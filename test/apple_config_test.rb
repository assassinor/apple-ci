# frozen_string_literal: true

require "minitest/autorun"
require "stringio"
require_relative "../scripts/apple_config"

class AppleConnectClientTest < Minitest::Test
  def test_jwt_uses_es256_raw_signature
    private_key = OpenSSL::PKey::EC.generate("prime256v1")
    client = AppleConnectClient.new(
      issuer_id: "issuer-id",
      key_id: "KEY1234567",
      private_key: private_key.to_pem,
      transport: ->(*) { raise "transport should not be called" }
    )

    header, payload, signature = client.send(:jwt).split(".")
    decoded_header = JSON.parse(Base64.urlsafe_decode64(header))
    decoded_payload = JSON.parse(Base64.urlsafe_decode64(payload))

    assert_equal("ES256", decoded_header.fetch("alg"))
    assert_equal("KEY1234567", decoded_header.fetch("kid"))
    assert_equal("issuer-id", decoded_payload.fetch("iss"))
    assert_equal(64, Base64.urlsafe_decode64(signature).bytesize)
  end
end

class FakeAppleClient
  attr_reader :created, :enabled

  def initialize(bundle: nil, capabilities: [])
    @bundle = bundle
    @capabilities = capabilities
    @created = []
    @enabled = []
  end

  def find_bundle_id(_identifier)
    @bundle
  end

  def create_bundle_id(identifier:, name:, platform:)
    @created << [identifier, name, platform]
    @bundle = { "id" => "new-id", "attributes" => { "identifier" => identifier } }
  end

  def capabilities(_bundle_id)
    @capabilities
  end

  def enable_capability(bundle_id:, capability_type:)
    @enabled << [bundle_id, capability_type]
  end
end

class AppleConfigReconcilerTest < Minitest::Test
  CONFIG = {
    "apps" => [{
      "name" => "Example",
      "identifier" => "com.example.app",
      "platform" => "IOS",
      "capabilities" => %w[PUSH_NOTIFICATIONS ASSOCIATED_DOMAINS]
    }]
  }.freeze

  def test_plan_does_not_mutate
    client = FakeAppleClient.new
    output = StringIO.new

    AppleConfigReconciler.new(client: client, apply: false, output: output).reconcile(CONFIG)

    assert_empty(client.created)
    assert_empty(client.enabled)
    assert_includes(output.string, "PLAN: CREATE bundle ID com.example.app")
    assert_includes(output.string, "PLAN: ENABLE PUSH_NOTIFICATIONS for com.example.app")
  end

  def test_apply_creates_bundle_and_missing_capabilities
    client = FakeAppleClient.new

    AppleConfigReconciler.new(client: client, apply: true, output: StringIO.new).reconcile(CONFIG)

    assert_equal([["com.example.app", "Example", "IOS"]], client.created)
    assert_equal(
      [["new-id", "ASSOCIATED_DOMAINS"], ["new-id", "PUSH_NOTIFICATIONS"]],
      client.enabled
    )
  end

  def test_apply_is_idempotent_when_capabilities_exist
    client = FakeAppleClient.new(
      bundle: { "id" => "existing-id" },
      capabilities: %w[PUSH_NOTIFICATIONS ASSOCIATED_DOMAINS]
    )
    output = StringIO.new

    AppleConfigReconciler.new(client: client, apply: true, output: output).reconcile(CONFIG)

    assert_empty(client.created)
    assert_empty(client.enabled)
    assert_includes(output.string, "APPLY: OK com.example.app; no changes")
  end
end
