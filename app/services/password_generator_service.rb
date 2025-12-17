class PasswordGeneratorService
  ADJECTIVES = %w[
    Swift Bright Quick Smart Sharp Clever Bold Brave Strong Fast
    Happy Lucky Noble Rapid Agile Keen Vivid Clear Calm Cool
  ].freeze

  NOUNS = %w[
    Tiger Eagle Falcon Hawk Phoenix Dragon Lion Wolf Bear Panther
    Rocket Star Moon Cloud River Storm Thunder Ocean Wave Summit
  ].freeze

  SPECIAL_CHARS = %w[! @ # $ &].freeze

  def self.generate
    new.generate
  end

  def generate
    adjective = ADJECTIVES.sample
    noun = NOUNS.sample
    number = rand(100..999)
    special = SPECIAL_CHARS.sample

    "#{adjective}#{noun}#{number}#{special}"
  end
end
