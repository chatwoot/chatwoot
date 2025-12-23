# frozen_string_literal: true

module TestProf # :nodoc: all
  FACTORY_GIRL_NAMES = {"factory_bot" => "::FactoryBot", "factory_girl" => "::FactoryGirl"}.freeze

  FACTORY_GIRL_NAMES.find do |name, cname|
    TestProf.require(name) do
      TestProf::FactoryBot = Object.const_get(cname)
    end
  end
end
