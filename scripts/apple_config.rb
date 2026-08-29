#!/usr/bin/env ruby
# frozen_string_literal: true

require "base64"
require "json"
require "net/http"
require "openssl"
require "optparse"
require "uri"
require "yaml"

class AppleApiError < StandardError; end

class AppleConnectClient
  BASE_URL = "https://api.appstoreconnect.apple.com"

  def initialize(issuer_id:, key_id:, private_key:, transport: nil)
    @issuer_id = issuer_id
    @key_id = key_id
    @private_key = OpenSSL::PKey::EC.new(private_key)
    @transport = transport || method(:request_over_network)
  end

  def find_bundle_id(identifier)
    response = request(:get, "/v1/bundleIds", query: { "filter[identifier]" => identifier })
    response.fetch("data").find { |item| item.dig("attributes", "identifier") == identifier }
  end

  def create_bundle_id(identifier:, name:, platform:)
    request(
      :post,
      "/v1/bundleIds",
      body: {
        data: {
          type: "bundleIds",
          attributes: { identifier: identifier, name: name, platform: platform }
        }
      }
    ).fetch("data")
  end

  def capabilities(bundle_id)
    request(:get, "/v1/bundleIds/#{bundle_id}/bundleIdCapabilities", query: { "limit" => "200" })
      .fetch("data")
      .map { |item| item.dig("attributes", "capabilityType") }
      .compact
  end

  def enable_capability(bundle_id:, capability_type:)
    request(
      :post,
      "/v1/bundleIdCapabilities",
      body: {
        data: {
          type: "bundleIdCapabilities",
          attributes: { capabilityType: capability_type },
          relationships: {
            bundleId: { data: { type: "bundleIds", id: bundle_id } }
          }
        }
      }
    )
  end

  private

  def request(method, path, query: {}, body: nil)
    @transport.call(method, path, query, body, jwt)
  end

  def request_over_network(method, path, query, body, token)
    uri = URI.join(BASE_URL, path)
    uri.query = URI.encode_www_form(query) unless query.empty?
    request_class = method == :get ? Net::HTTP::Get : Net::HTTP::Post
    request = request_class.new(uri)
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(body) if body

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    parsed = response.body.to_s.empty? ? {} : JSON.parse(response.body)
    return parsed if response.is_a?(Net::HTTPSuccess)

    detail = Array(parsed["errors"]).map { |error| error["detail"] || error["title"] }.compact.join("; ")
    raise AppleApiError, "Apple API #{response.code} for #{path}: #{detail}"
  end

  def jwt
    now = Time.now.to_i
    header = base64url(JSON.generate(alg: "ES256", kid: @key_id, typ: "JWT"))
    payload = base64url(JSON.generate(iss: @issuer_id, iat: now, exp: now + 1_200, aud: "appstoreconnect-v1"))
    signing_input = "#{header}.#{payload}"
    der_signature = @private_key.dsa_sign_asn1(OpenSSL::Digest::SHA256.digest(signing_input))
    sequence = OpenSSL::ASN1.decode(der_signature)
    raw_signature = sequence.value.map { |integer| integer.value.to_s(2).rjust(32, "\0") }.join
    "#{signing_input}.#{base64url(raw_signature)}"
  end

  def base64url(value)
    Base64.urlsafe_encode64(value, padding: false)
  end
end

class AppleConfigReconciler
  def initialize(client:, apply:, output: $stdout)
    @client = client
    @apply = apply
    @output = output
  end

  def reconcile(config)
    Array(config.fetch("apps")).each { |app| reconcile_app(app) }
  end

  private

  def reconcile_app(app)
    identifier = app.fetch("identifier")
    bundle = @client.find_bundle_id(identifier)

    unless bundle
      report("CREATE bundle ID #{identifier} (#{app.fetch('platform')})")
      return unless @apply

      bundle = @client.create_bundle_id(
        identifier: identifier,
        name: app.fetch("name"),
        platform: app.fetch("platform")
      )
    end

    current = @client.capabilities(bundle.fetch("id"))
    requested = Array(app["capabilities"]).map(&:to_s).uniq
    (requested - current).sort.each do |capability|
      report("ENABLE #{capability} for #{identifier}")
      @client.enable_capability(bundle_id: bundle.fetch("id"), capability_type: capability) if @apply
    end
    report("OK #{identifier}; no changes") if requested.all? { |capability| current.include?(capability) }
  end

  def report(message)
    @output.puts("#{@apply ? 'APPLY' : 'PLAN'}: #{message}")
  end
end

if $PROGRAM_NAME == __FILE__
  options = { apply: false }
  OptionParser.new do |parser|
    parser.banner = "Usage: apple_config.rb --config fastlane/capabilities.yml [--apply]"
    parser.on("--config PATH", "Capability configuration YAML") { |value| options[:config] = value }
    parser.on("--apply", "Create missing Bundle IDs and capabilities") { options[:apply] = true }
  end.parse!

  abort("--config is required") unless options[:config]
  config = YAML.safe_load_file(options[:config], permitted_classes: [], aliases: false)
  key_content = ENV["APPLE_ASC_PRIVATE_KEY_BASE64"]
  abort("APPLE_ASC_PRIVATE_KEY_BASE64 is required") if key_content.to_s.empty?

  client = AppleConnectClient.new(
    issuer_id: ENV.fetch("APPLE_ASC_ISSUER_ID"),
    key_id: ENV.fetch("APPLE_ASC_KEY_ID"),
    private_key: Base64.decode64(key_content)
  )
  AppleConfigReconciler.new(client: client, apply: options[:apply]).reconcile(config)
end
