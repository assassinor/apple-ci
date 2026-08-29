require "minitest/autorun"

def opt_out_usage; end
def desc(*); end
def lane(*); end

load File.expand_path("../fastlane/Fastfile", __dir__)

class AppleCiVersionTest < Minitest::Test
  def validate(marketing_version: "2026.08.29", tag: "v2026.08.29.1", tagger_date: "2026.08.29")
    AppleCiVersion.validate_calendar_release(
      marketing_version: marketing_version,
      tag: tag,
      tagger_date: tagger_date
    )
  end

  def test_accepts_matching_calendar_release
    assert_equal "2026.08.29.1", validate
  end

  def test_rejects_missing_revision
    assert_raises(ArgumentError) { validate(tag: "v2026.08.29") }
  end

  def test_rejects_zero_padded_revision
    assert_raises(ArgumentError) { validate(tag: "v2026.08.29.01") }
  end

  def test_rejects_invalid_date
    assert_raises(ArgumentError) do
      validate(marketing_version: "2026.02.30", tag: "v2026.02.30.1", tagger_date: "2026.02.30")
    end
  end

  def test_rejects_stale_marketing_version
    error = assert_raises(ArgumentError) do
      validate(marketing_version: "2026.08.16")
    end
    assert_match "does not match marketing version", error.message
  end

  def test_rejects_tag_created_on_another_date
    error = assert_raises(ArgumentError) do
      validate(tagger_date: "2026.08.30")
    end
    assert_match "does not match tagger date", error.message
  end

  def test_requires_annotated_tag
    assert_raises(ArgumentError) { validate(tagger_date: "") }
  end
end

class AppleCiTagVerificationTest < Minitest::Test
  def valid_payload
    {
      "tag" => "v2026.08.30.1",
      "object" => { "type" => "commit" },
      "verification" => { "verified" => true, "reason" => "valid" }
    }
  end

  def test_accepts_valid_github_tag_signature
    assert AppleCiTagVerification.validate!(valid_payload, expected_tag: "v2026.08.30.1")
  end

  def test_rejects_unsigned_tag
    payload = valid_payload.merge("verification" => { "verified" => false, "reason" => "unsigned" })
    error = assert_raises(ArgumentError) do
      AppleCiTagVerification.validate!(payload, expected_tag: "v2026.08.30.1")
    end
    assert_match "unsigned", error.message
  end

  def test_rejects_mismatched_tag
    assert_raises(ArgumentError) do
      AppleCiTagVerification.validate!(valid_payload, expected_tag: "v2026.08.30.2")
    end
  end

  def test_rejects_non_commit_target
    payload = valid_payload.merge("object" => { "type" => "tag" })
    assert_raises(ArgumentError) do
      AppleCiTagVerification.validate!(payload, expected_tag: "v2026.08.30.1")
    end
  end
end
