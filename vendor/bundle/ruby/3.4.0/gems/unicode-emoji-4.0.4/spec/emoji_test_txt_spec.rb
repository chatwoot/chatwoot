require_relative "../lib/unicode/emoji"
require "minitest/autorun"
require "open-uri"

def iterate_emoji
  EMOJI_TEST_FILE.scan(/^(?:# (?<sub>sub)?group: (?<group_name>.*)$)|(?:(?<codepoints>.+?)\s*; (?<qual_status>.+?)-?qualified )/) do
    if $~[:codepoints]
      yield $~[:codepoints].split.map{|e| e.to_i(16)}.pack("U*"), $~[:qual_status]
    end
  end
end

describe "emoji-test.txt" do
  EMOJI_TEST_FILE = begin
    emoji_test_path = File.join(__dir__, "data/emoji-test.txt")
    if File.exist? emoji_test_path
      file = File.read(emoji_test_path)
    else
      puts "Downloading emoji-test.txt from the consortium"
      URI.open "https://www.unicode.org/Public/emoji/#{Unicode::Emoji::EMOJI_VERSION}/emoji-test.txt" do |f|
        file = f.read
        File.write(File.join(__dir__, "data/emoji-test.txt"), @file)
      end
    end

    file
  end

  # qual_status:
  # - fully - fully-qualified emoji sequences
  # - minimally - minimallyq-ualified emoji sequences (some VS16 missing, but not first one)
  # - un - unqualified emoji sequences (some VS16 missing)

  describe "REGEX" do
    describe "detects fully-qualified emoji" do
      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          if qual_status == "fully"
            assert_equal emoji, emoji[Unicode::Emoji::REGEX]
          else
            refute_equal emoji, emoji[Unicode::Emoji::REGEX]
          end
        end
      end
    end
  end

  describe "REGEX_INCLUDE_TEXT" do
    describe "detects fully-qualified emoji and (unqualified) singleton text emoji" do
      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          if qual_status == "fully" || qual_status == "un" && emoji.size <= 2
            assert_equal emoji, emoji[Unicode::Emoji::REGEX_INCLUDE_TEXT]
          else
            refute_equal emoji, emoji[Unicode::Emoji::REGEX_INCLUDE_TEXT]
          end
        end
      end
    end
  end

  describe "REGEX_INCLUDE_MQE" do
    describe "detects fully-qualified emoji and minimally-qualified emoji" do
      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          if qual_status == "fully" || qual_status == "minimally"
            assert_equal emoji, emoji[Unicode::Emoji::REGEX_INCLUDE_MQE]
          else
            refute_equal emoji, emoji[Unicode::Emoji::REGEX_INCLUDE_MQE]
          end
        end
      end
    end
  end

  describe "REGEX_INCLUDE_MQE_UQE" do
    describe "detects all emoji" do
      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          assert_equal emoji, emoji[Unicode::Emoji::REGEX_INCLUDE_MQE_UQE]
        end
      end
    end
  end

  describe "REGEX_VALID" do
    describe "detects fully-qualified, minimally-qualified emoji, and unqualified emoji with ZWJ" do
      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          if qual_status == "fully" || qual_status == "minimally" || qual_status == "un" && emoji.size >= 3
            assert_equal emoji, emoji[Unicode::Emoji::REGEX_VALID]
          else
            refute_equal emoji, emoji[Unicode::Emoji::REGEX_VALID]
          end
        end
      end
    end
  end

  describe "REGEX_VALID_INCLUDE_TEXT" do
    describe "detects all emoji" do
      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          assert_equal emoji, emoji[Unicode::Emoji::REGEX_VALID_INCLUDE_TEXT]
        end
      end
    end
  end

  describe "REGEX_WELL_FORMED" do
    describe "detects fully-qualified, minimally-qualified emoji, and unqualified emoji with ZWJ" do
      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          if qual_status == "fully" || qual_status == "minimally" || qual_status == "un" && emoji.size >= 3
            assert_equal emoji, emoji[Unicode::Emoji::REGEX_WELL_FORMED]
          else
            refute_equal emoji, emoji[Unicode::Emoji::REGEX_WELL_FORMED]
          end
        end
      end
    end
  end

  describe "REGEX_WELL_FORMED_INCLUDE_TEXT" do
    describe "detects all emoji" do
      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          assert_equal emoji, emoji[Unicode::Emoji::REGEX_WELL_FORMED_INCLUDE_TEXT]
        end
      end
    end
  end

  describe "REGEX_POSSIBLE" do
    describe "detects all emoji, except unqualified keycap sequences" do
      # fixing test not regex, since implementation of this regex should match the one in the standard
      unqualified_keycaps = Unicode::Emoji::EMOJI_KEYCAPS.map{|keycap|
        [keycap, Unicode::Emoji::EMOJI_KEYCAP_SUFFIX].pack("U*")
      }

      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          if !unqualified_keycaps.include?(emoji)
            assert_equal emoji, emoji[Unicode::Emoji::REGEX_POSSIBLE]
          else
            refute_equal emoji, emoji[Unicode::Emoji::REGEX_POSSIBLE]
          end
        end
      end
    end
  end

  describe "REGEX_TEXT" do
    describe "detects (unqualified) singleton text emoji" do
      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          # if qual_status == "un" && emoji =~ /^.[\u{FE0E 20E3}]?$/
          if qual_status == "un" && emoji.size <= 2
            assert_equal emoji, emoji[Unicode::Emoji::REGEX_TEXT]
          else
            refute_equal emoji, emoji[Unicode::Emoji::REGEX_TEXT]
          end
        end
      end
    end
  end

  describe "REGEX_BASIC" do
    describe "detects (fully-qualified) singleton emoji" do
      iterate_emoji do |emoji, qual_status|
        it(emoji) do
          if qual_status == "fully" && emoji =~ /^.\u{FE0F}?$/
            assert_equal emoji, emoji[Unicode::Emoji::REGEX_BASIC]
          else
            refute_equal emoji, emoji[Unicode::Emoji::REGEX_BASIC]
          end
        end
      end
    end
  end
end
