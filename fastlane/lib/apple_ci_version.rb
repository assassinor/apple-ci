require "date"

module AppleCiVersion
  CALENDAR_VERSION = /\A(?<date>\d{4}\.\d{2}\.\d{2})\.(?<revision>[1-9]\d*)\z/
  MARKETING_VERSION = /\A\d{4}\.\d{2}\.\d{2}\z/

  module_function

  def validate_calendar_release(marketing_version:, tag:, tagger_date:)
    unless MARKETING_VERSION.match?(marketing_version)
      raise ArgumentError, "marketing version must use YYYY.MM.DD"
    end

    parse_date(marketing_version, "marketing version")
    match = CALENDAR_VERSION.match(tag.delete_prefix("v"))
    raise ArgumentError, "release tag must use vYYYY.MM.DD.N" unless tag.start_with?("v") && match

    tag_date = match["date"]
    parse_date(tag_date, "release tag")
    raise ArgumentError, "tag date #{tag_date} does not match marketing version #{marketing_version}" unless tag_date == marketing_version
    raise ArgumentError, "release tag must be annotated so its tagger date can be verified" if tagger_date.to_s.empty?
    raise ArgumentError, "tag date #{tag_date} does not match tagger date #{tagger_date}" unless tag_date == tagger_date

    match[0]
  end

  def parse_date(value, label)
    Date.strptime(value, "%Y.%m.%d")
  rescue Date::Error
    raise ArgumentError, "#{label} contains an invalid calendar date: #{value}"
  end
  private_class_method :parse_date
end
