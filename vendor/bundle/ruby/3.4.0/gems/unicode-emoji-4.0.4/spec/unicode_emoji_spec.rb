require_relative "../lib/unicode/emoji"
require "minitest/autorun"

describe Unicode::Emoji do
  describe ".properties" do
    it "returns an Array of Emoji properties for given codepoint" do
      assert_equal ["Emoji", "Emoji_Presentation", "Extended_Pictographic"], Unicode::Emoji.properties("😴")
      assert_equal ["Emoji", "Extended_Pictographic"], Unicode::Emoji.properties("♠")
    end

    it "returns nil if codepoint has no Emoji prop" do
      assert_nil Unicode::Emoji.properties("A")
    end
  end

  describe "REGEX" do
    it "matches most singleton emoji codepoints" do
      "😴 sleeping face" =~ Unicode::Emoji::REGEX
      assert_equal "😴", $&
    end

    it "matches singleton emoji in combination with emoji variation selector" do
      "😴\u{FE0F} sleeping face" =~ Unicode::Emoji::REGEX
      assert_equal "😴\u{FE0F}", $&
    end

    it "does not match singleton emoji in combination with text variation selector" do
      "😴\u{FE0E} sleeping face" =~ Unicode::Emoji::REGEX
      assert_nil $&
    end

    it "does not match textual singleton emoji" do
      "▶ play button" =~ Unicode::Emoji::REGEX
      assert_nil $&
    end

    it "matches textual singleton emoji in combination with emoji variation selector" do
      "▶\u{FE0F} play button" =~ Unicode::Emoji::REGEX
      assert_equal "▶\u{FE0F}", $&
    end

    it "matches singleton skin tone modifiers and hair components" do
      "🏻 light skin tone" =~ Unicode::Emoji::REGEX
      assert_equal "🏻", $&

      "🦰 emoji component red hair" =~ Unicode::Emoji::REGEX
      assert_equal "🦰", $&
    end

    it "does not match singleton components that are not skin tone modifiers or hair components" do
      "1 digit one" =~ Unicode::Emoji::REGEX
      assert_nil $&

      "🇦 regional indicator symbol letter a" =~ Unicode::Emoji::REGEX
      assert_nil $&
    end

    it "matches modified emoji if modifier base emoji is used" do
      "🛌🏽 person in bed: medium skin tone" =~ Unicode::Emoji::REGEX
      assert_equal "🛌🏽", $&
    end

    it "does not match modified emoji if no modifier base emoji is used" do
      "🌵🏽 cactus" =~ Unicode::Emoji::REGEX
      assert_equal "🌵", $&
    end

    it "matches valid region flags" do
      "🇵🇹 Portugal" =~ Unicode::Emoji::REGEX
      assert_equal "🇵🇹", $&
    end

    it "does not match invalid region flags" do
      "🇵🇵 PP Land" =~ Unicode::Emoji::REGEX
      assert_nil $&
    end

    it "matches emoji keycap sequences" do
      "2️⃣ keycap: 2" =~ Unicode::Emoji::REGEX
      assert_equal "2️⃣", $&
    end

    it "does not match non-emoji keycap sequences" do
      "8⃣ text keycap: 8" =~ Unicode::Emoji::REGEX
      assert_nil $&

      "#⃣ text keycap: #" =~ Unicode::Emoji::REGEX
      assert_nil $&
    end
  
    it "matches recommended tag sequences" do
      "🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland" =~ Unicode::Emoji::REGEX
      assert_equal "🏴󠁧󠁢󠁳󠁣󠁴󠁿", $&
    end

    it "does not match valid tag sequences that are not recommended" do
      "🏴󠁧󠁢󠁡󠁧󠁢󠁿 GB AGB" =~ Unicode::Emoji::REGEX
      assert_equal "🏴", $& # only base flag is matched
    end

    it "matches recommended zwj sequences" do
      "🤾🏽‍♀️ woman playing handball: medium skin tone" =~ Unicode::Emoji::REGEX
      assert_equal "🤾🏽‍♀️", $&
    end

    it "does not match MQE zwj sequences" do
      "🤾🏽‍♀ woman playing handball: medium skin tone, missing VS16" =~ Unicode::Emoji::REGEX
      refute_equal "🤾🏽‍♀", $&
    end

    it "does not match UQE emoji" do
      "🏌‍♂️ man golfing, missing VS16" =~ Unicode::Emoji::REGEX
      refute_equal "🏌‍♂️", $&
    end

    it "does not match valid zwj sequences that are not recommended" do
      "🤠‍🤢 vomiting cowboy" =~ Unicode::Emoji::REGEX
      assert_equal "🤠", $&
    end

    it "matches 12.1 emoji" do
      "🧑‍🦱 person: curly hair" =~ Unicode::Emoji::REGEX
      assert_equal "🧑‍🦱", $&
    end

    it "matches 13.0 emoji" do
      "👨‍🍼 man feeding baby" =~ Unicode::Emoji::REGEX
      assert_equal "👨‍🍼", $&
    end

    it "matches 13.1 emoji" do
      "❤️‍🔥 heart on fire" =~ Unicode::Emoji::REGEX
      assert_equal "❤️‍🔥", $&
    end

    it "matches 14.0 emoji" do
      "🪺 nest with eggs" =~ Unicode::Emoji::REGEX
      assert_equal "🪺", $&
    end

    it "matches 15.0 emoji" do
      "🐦‍⬛ black bird" =~ Unicode::Emoji::REGEX
      assert_equal "🐦‍⬛", $&
    end

    it "matches 15.1 emoji" do
      "🙂‍↔️ head shaking horizontally" =~ Unicode::Emoji::REGEX
      assert_equal "🙂‍↔️", $&
    end

    it "matches 16.0 emoji" do
      "🪾 leafless tree" =~ Unicode::Emoji::REGEX
      assert_equal "🪾", $&
    end

    # See gh#12 and https://github.com/matt17r/nw5k/commit/05a34d3c9211a23e5ae6853bb19fd2f224779ef4#diff-afb6f8bc3bae71b75743e00882a060863e2430cbe858ec9014e5956504dfc61cR2
    it "matches family emoji correctly" do
      ["👨‍👩‍👧‍👦", "👨‍👩‍👦‍👦", "👨‍👩‍👧‍👧", "👨‍👨‍👧‍👦", "👨‍👨‍👦‍👦", "👨‍👨‍👧‍👧", "👩‍👩‍👧‍👦", "👩‍👩‍👦‍👦", "👩‍👩‍👧‍👧", "👨‍👦‍👦", "👨‍👧‍👦", "👨‍👧‍👧", "👩‍👦‍👦", "👩‍👧‍👦", "👩‍👧‍👧"].each { |family|
        assert_equal family, family[Unicode::Emoji::REGEX]
      }
    end
  end

  describe "REGEX_INCLUDE_MQE" do
    it "matches MQE emoji" do
      "🤾🏽‍♀ woman playing handball: medium skin tone, missing VS16" =~ Unicode::Emoji::REGEX_INCLUDE_MQE
      assert_equal "🤾🏽‍♀", $&
    end

    it "does not match UQE emoji" do
      "🏌‍♂️ man golfing, missing VS16" =~ Unicode::Emoji::REGEX_INCLUDE_MQE
      refute_equal "🏌‍♂️", $&
    end
  end

  describe "REGEX_INCLUDE_MQE_UQE" do
    it "matches MQE emoji" do
      "🤾🏽‍♀ woman playing handball: medium skin tone, missing VS16" =~ Unicode::Emoji::REGEX_INCLUDE_MQE_UQE
      assert_equal "🤾🏽‍♀", $&
    end

    it "matches UQE emoji" do
      "🏌‍♂️ man golfing, missing VS16" =~ Unicode::Emoji::REGEX_INCLUDE_MQE_UQE
      assert_equal "🏌‍♂️", $&
    end
  end

  describe "REGEX_VALID" do
    it "matches most singleton emoji codepoints" do
      "😴 sleeping face" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "😴", $&
    end

    it "matches singleton emoji in combination with emoji variation selector" do
      "😴\u{FE0F} sleeping face" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "😴\u{FE0F}", $&
    end

    it "does not match singleton emoji when in combination with text variation selector" do
      "😴\u{FE0E} sleeping face" =~ Unicode::Emoji::REGEX_VALID
      assert_nil $&
    end

    it "does not match textual singleton emoji" do
      "▶ play button" =~ Unicode::Emoji::REGEX_VALID
      assert_nil $&
    end

    it "matches textual singleton emoji in combination with emoji variation selector" do
      "▶\u{FE0F} play button" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "▶\u{FE0F}", $&
    end

    it "matches singleton skin tone modifiers and hair components" do
      "🏻 light skin tone" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🏻", $&

      "🦰 emoji component red hair" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🦰", $&
    end

    it "does not match singleton components that are not skin tone modifiers or hair components" do
      "1 digit one" =~ Unicode::Emoji::REGEX_VALID
      assert_nil $&

      "🇦 regional indicator symbol letter a" =~ Unicode::Emoji::REGEX_VALID
      assert_nil $&
    end

    it "matches modified emoji if modifier base emoji is used" do
      "🛌🏽 person in bed: medium skin tone" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🛌🏽", $&
    end

    it "does not match modified emoji if no modifier base emoji is used" do
      "🌵🏽 cactus" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🌵", $&
    end

    it "matches valid region flags" do
      "🇵🇹 Portugal" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🇵🇹", $&
    end

    it "does not match invalid region flags" do
      "🇵🇵 PP Land" =~ Unicode::Emoji::REGEX_VALID
      assert_nil $&
    end

    it "matches emoji keycap sequences" do
      "2️⃣ keycap: 2" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "2️⃣", $&
    end

    it "does not match non-emoji keycap sequences" do
      "8⃣ text keycap: 8" =~ Unicode::Emoji::REGEX_VALID
      assert_nil $&

      "#⃣ text keycap: #" =~ Unicode::Emoji::REGEX_VALID
      assert_nil $&
    end

    it "matches recommended tag sequences" do
      "🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🏴󠁧󠁢󠁳󠁣󠁴󠁿", $&
    end

    it "matches valid tag sequences, even though they are not recommended" do
      "🏴󠁧󠁢󠁡󠁧󠁢󠁿 GB AGB" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🏴󠁧󠁢󠁡󠁧󠁢󠁿", $&
    end

    it "matches valid tag sequences (compressed one)" do
      "🏴󠁬󠁶󠀰󠀴󠀲󠁿 lv042" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🏴󠁬󠁶󠀰󠀴󠀲󠁿", $&
    end

    it "does not match invalid tag sequences" do
      "🏴󠁧󠁢󠁡󠁡󠁡󠁿 GB AAA" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🏴", $& # only base flag is matched
    end

    it "matches recommended zwj sequences" do
      "🤾🏽‍♀️ woman playing handball: medium skin tone" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🤾🏽‍♀️", $&
    end

    it "matches valid zwj sequences, even though they are not recommended" do
      "🤠‍🤢 vomiting cowboy" =~ Unicode::Emoji::REGEX_VALID
      assert_equal "🤠‍🤢", $&
    end
  end

  describe "REGEX_WELL_FORMED" do
    it "matches most singleton emoji codepoints" do
      "😴 sleeping face" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "😴", $&
    end

    it "matches singleton emoji in combination with emoji variation selector" do
      "😴\u{FE0F} sleeping face" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "😴\u{FE0F}", $&
    end

    it "does not match singleton emoji when in combination with text variation selector" do
      "😴\u{FE0E} sleeping face" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_nil $&
    end

    it "does not match textual singleton emoji" do
      "▶ play button" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_nil $&
    end

    it "matches textual singleton emoji in combination with emoji variation selector" do
      "▶\u{FE0F} play button" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "▶\u{FE0F}", $&
    end

    it "matches singleton skin tone modifiers and hair components" do
      "🏻 light skin tone" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🏻", $&

      "🦰 emoji component red hair" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🦰", $&
    end

    it "does not match singleton components that are not skin tone modifiers or hair components" do
      "1 digit one" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_nil $&

      "🇦 regional indicator symbol letter a" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_nil $&
    end

    it "matches modified emoji if modifier base emoji is used" do
      "🛌🏽 person in bed: medium skin tone" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🛌🏽", $&
    end

    it "does not match modified emoji if no modifier base emoji is used" do
      "🌵🏽 cactus" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🌵", $&
    end

    it "matches valid region flags" do
      "🇵🇹 Portugal" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🇵🇹", $&
    end

    it "does match invalid region flags" do
      "🇵🇵 PP Land" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🇵🇵", $&
    end

    it "matches emoji keycap sequences" do
      "2️⃣ keycap: 2" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "2️⃣", $&
    end

    it "does not match non-emoji keycap sequences" do
      "8⃣ text keycap: 8" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_nil $&

      "#⃣ text keycap: #" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_nil $&
    end

    it "matches recommended tag sequences" do
      "🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🏴󠁧󠁢󠁳󠁣󠁴󠁿", $&
    end

    it "matches valid tag sequences, even though they are not recommended" do
      "🏴󠁧󠁢󠁡󠁧󠁢󠁿 GB AGB" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🏴󠁧󠁢󠁡󠁧󠁢󠁿", $&
    end

    it "matches invalid base tag sequences" do
      "😴󠁧󠁢󠁡󠁡󠁡󠁿 GB AAA" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "😴󠁧󠁢󠁡󠁡󠁡󠁿", $&
    end

    it "does not match too long tag sequences (only black flag is matched)" do
      "🏴󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁿 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🏴", $&
    end

    it "does not match invalid tag sequences (only black flag is matched)" do
      "🏴󠀤󠁿 $" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🏴", $&
    end

    it "matches recommended zwj sequences" do
      "🤾🏽‍♀️ woman playing handball: medium skin tone" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🤾🏽‍♀️", $&
    end

    it "matches valid zwj sequences, even though they are not recommended" do
      "🤠‍🤢 vomiting cowboy" =~ Unicode::Emoji::REGEX_WELL_FORMED
      assert_equal "🤠‍🤢", $&
    end
  end

  describe "REGEX_POSSIBLE" do
    it "matches most singleton emoji codepoints" do
      "😴 sleeping face" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "😴", $&
    end

    it "matches singleton emoji in combination with emoji variation selector" do
      "😴\u{FE0F} sleeping face" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "😴\u{FE0F}", $&
    end

    it "matches singleton emoji (without VS) when in combination with text variation selector" do
      "😴\u{FE0E} sleeping face" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "😴", $&
    end

    it "matches textual singleton emoji" do
      "▶ play button" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "▶", $&
    end

    it "matches textual singleton emoji in combination with emoji variation selector" do
      "▶\u{FE0F} play button" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "▶\u{FE0F}", $&
    end

    it "matches singleton skin tone modifiers and hair components" do
      "🏻 light skin tone" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🏻", $&

      "🦰 emoji component red hair" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🦰", $&
    end

    it "matches singleton components that are not skin tone modifiers or hair components" do
      "1 digit one" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "1", $&

      "🇦 regional indicator symbol letter a" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🇦", $&
    end

    it "matches modified emoji if modifier base emoji is used" do
      "🛌🏽 person in bed: medium skin tone" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🛌🏽", $&
    end

    it "matches modified emoji even if no modifier base emoji is used" do
      "🌵🏽 cactus" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🌵🏽", $&
    end

    it "matches valid region flags" do
      "🇵🇹 Portugal" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🇵🇹", $&
    end

    it "does match invalid region flags" do
      "🇵🇵 PP Land" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🇵🇵", $&
    end

    it "matches emoji keycap sequences" do
      "2️⃣ keycap: 2" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "2️⃣", $&
    end

    it "matches only digit of non-emoji keycap sequences" do
      "8⃣ text keycap: 8" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "8", $&

      "#⃣ text keycap: #" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "#", $&
    end

    it "matches recommended tag sequences" do
      "🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🏴󠁧󠁢󠁳󠁣󠁴󠁿", $&
    end

    it "matches valid tag sequences, even though they are not recommended" do
      "🏴󠁧󠁢󠁡󠁧󠁢󠁿 GB AGB" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🏴󠁧󠁢󠁡󠁧󠁢󠁿", $&
    end

    it "matches invalid base tag sequences" do
      "😴󠁧󠁢󠁡󠁡󠁡󠁿 GB AAA" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "😴󠁧󠁢󠁡󠁡󠁡󠁿", $&
    end

    it "matches too long tag sequences" do
      "🏴󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁿 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🏴󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁁󠁿", $&
    end

    it "machtes invalid tag sequences (only black flag is matched)" do
      "🏴󠀤󠁿 $" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🏴󠀤󠁿", $&
    end

    it "matches recommended zwj sequences" do
      "🤾🏽‍♀️ woman playing handball: medium skin tone" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🤾🏽‍♀️", $&
    end

    it "matches valid zwj sequences, even though they are not recommended" do
      "🤠‍🤢 vomiting cowboy" =~ Unicode::Emoji::REGEX_POSSIBLE
      assert_equal "🤠‍🤢", $&
    end
  end

  describe "REGEX_BASIC" do
    it "matches most singleton emoji codepoints" do
      "😴 sleeping face" =~ Unicode::Emoji::REGEX_BASIC
      assert_equal "😴", $&
    end

    it "matches singleton emoji in combination with emoji variation selector" do
      "😴\u{FE0F} sleeping face" =~ Unicode::Emoji::REGEX_BASIC
      assert_equal "😴\u{FE0F}", $&
    end

    it "does not match singleton emoji when in combination with text variation selector" do
      "😴\u{FE0E} sleeping face" =~ Unicode::Emoji::REGEX_BASIC
      assert_nil $&
    end

    it "does not match textual singleton emoji" do
      "▶ play button" =~ Unicode::Emoji::REGEX_BASIC
      assert_nil $&
    end

    it "matches textual singleton emoji in combination with emoji variation selector" do
      "▶\u{FE0F} play button" =~ Unicode::Emoji::REGEX_BASIC
      assert_equal "▶\u{FE0F}", $&
    end

    it "matches singleton skin tone modifiers and hair components" do
      "🏻 light skin tone" =~ Unicode::Emoji::REGEX_BASIC
      assert_equal "🏻", $&

      "🦰 emoji component red hair" =~ Unicode::Emoji::REGEX_BASIC
      assert_equal "🦰", $&
    end

    it "does not match singleton components that are not skin tone modifiers or hair components" do
      "1 digit one" =~ Unicode::Emoji::REGEX_BASIC
      assert_nil $&

      "🇦 regional indicator symbol letter a" =~ Unicode::Emoji::REGEX_BASIC
      assert_nil $&
    end

    it "does not match modified emoji" do
      "🛌🏽 person in bed: medium skin tone" =~ Unicode::Emoji::REGEX_BASIC
      assert_equal "🛌", $&
    end

    it "does not match region flags" do
      "🇵🇹 Portugal" =~ Unicode::Emoji::REGEX_BASIC
      assert_nil $&
    end

    it "does not match emoji keycap sequences" do
      "2️⃣ keycap: 2" =~ Unicode::Emoji::REGEX_BASIC
      assert_nil $&
    end

    it "does not match tag sequences" do
      "🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland" =~ Unicode::Emoji::REGEX_BASIC
      assert_equal "🏴", $& # only base flag is matched
    end

    it "does not match zwj sequences" do
      "🤾🏽‍♀️ woman playing handball: medium skin tone" =~ Unicode::Emoji::REGEX_BASIC
      assert_equal "🤾", $&
    end
  end

  describe "REGEX_TEXT" do
    it "deos not match singleton emoji codepoints with emoji presentation and no variation selector" do
      "😴 sleeping face" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end

    it "does not match singleton emoji in combination with emoji variation selector" do
      "😴\u{FE0F} sleeping face" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end

    it "matches singleton emoji in combination with text variation selector" do
      "😴\u{FE0E} sleeping face" =~ Unicode::Emoji::REGEX_TEXT
      assert_equal "😴\u{FE0E}", $&
    end

    it "matches textual singleton emoji" do
      "▶ play button" =~ Unicode::Emoji::REGEX_TEXT
      assert_equal "▶", $&
    end

    it "does not match textual singleton emoji in combination with emoji variation selector" do
      "▶\u{FE0F} play button" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end

    it "does not match textual singleton emoji in combination with emoji modifiers" do
      "✌🏻 victory hand" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end

    it "does not match singleton skin tone modifiers and hair components" do
      "🏻 light skin tone" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&

      "🦰 emoji component red hair" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end

    it "does not match singleton components that are not skin tone modifiers or hair components" do
      "1 digit one" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&

      "🇦 regional indicator symbol letter a" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end

    it "does not match modified emoji" do
      "🛌🏽 person in bed: medium skin tone" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end

    it "does not match region flags" do
      "🇵🇹 Portugal" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end

    it "does not match emoji keycap sequences" do
      "2️⃣ keycap: 2" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end

    it "matches non-emoji keycap sequences" do
      "8⃣ text keycap: 8" =~ Unicode::Emoji::REGEX_TEXT
      assert_equal "8⃣", $&
      
      "#⃣ text keycap: #" =~ Unicode::Emoji::REGEX_TEXT
      assert_equal "#⃣", $&
    end

    it "does not match tag sequences" do
      "🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end

    it "does not match zwj sequences" do
      "🤾🏽‍♀️ woman playing handball: medium skin tone" =~ Unicode::Emoji::REGEX_TEXT
      assert_nil $&
    end
  end

  describe "REGEX_PROP_EMOJI" do
    it "returns any emoji-related codepoint (but no variation selectors or tags)" do
      matches = "1 string 😴\u{FE0F} sleeping face with 🇵 and modifier 🏾, also 🏴󠁧󠁢󠁳󠁣󠁴󠁿 Scotland".scan(Unicode::Emoji::REGEX_PROP_EMOJI)
      assert_equal ["1", "😴", "🇵", "🏾", "🏴"], matches
    end
  end

  describe "REGEX_EMOJI_KEYCAP" do
    it "matches emoji keycap sequences" do
      "2️⃣ keycap: 2" =~ Unicode::Emoji::REGEX_EMOJI_KEYCAP
      assert_equal "2️⃣", $&
    end

    it "does not match non-emoji keycap sequences" do
      "8⃣ text keycap: 8" =~ Unicode::Emoji::REGEX_EMOJI_KEYCAP
      assert_nil $&

      "#⃣ text keycap: #" =~ Unicode::Emoji::REGEX_EMOJI_KEYCAP
      assert_nil $&
    end
  end

  describe "REGEX_PICTO" do
    it "matches codepoints with Extended_Pictograph property (almost all emoji are, but also others)" do
      matches = "U+1F32D 🌭 HOT DOG, U+203C ‼ DOUBLE EXCLAMATION MARK, U+26E8 ⛨ BLACK CROSS ON SHIELD".scan(Unicode::Emoji::REGEX_PICTO)
      assert_equal ["🌭", "‼", "⛨"], matches
    end
  end

  describe "REGEX_PICTO_NO_EMOJI" do
    it "matches codepoints with Extended_Pictograph property, but no Emoji property" do
      matches = "U+1F32D 🌭 HOT DOG, U+203C ‼ DOUBLE EXCLAMATION MARK, U+26E8 ⛨ BLACK CROSS ON SHIELD".scan(Unicode::Emoji::REGEX_PICTO_NO_EMOJI)
      assert_equal ["⛨"], matches
    end
  end

  describe ".list" do
    it "returns a grouped list of emoji" do
      assert_includes Unicode::Emoji.list.keys, "Smileys & Emotion"
    end

    it "sub-groups the list of emoji" do
      assert_includes Unicode::Emoji.list("Smileys & Emotion").keys, "face-glasses"
    end

    it "has emoji in sub-groups" do
      assert_includes Unicode::Emoji.list("Smileys & Emotion", "face-glasses"), "😎"
    end

    it "issues a warning if attempting to retrieve old category" do
      assert_output nil, "Warning(unicode-emoji): The category of Smileys & People does not exist anymore\n" do
        assert_nil Unicode::Emoji.list("Smileys & People", "face-positive")
      end
    end
  end
end
