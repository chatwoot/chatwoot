module FactoryBot
  class << self
    attr_accessor :aliases
  end

  self.aliases = [
    [/(.+)_id/, '\1'],
    [/(.*)/, '\1_id']
  ]

  def self.aliases_for(attribute)
    aliases.map { |(pattern, replace)|
      if pattern.match?(attribute)
        attribute.to_s.sub(pattern, replace).to_sym
      end
    }.compact << attribute
  end
end
