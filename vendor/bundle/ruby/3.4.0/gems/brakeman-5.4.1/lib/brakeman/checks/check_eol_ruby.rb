require_relative 'eol_check'

class Brakeman::CheckEOLRuby < Brakeman::EOLCheck
  Brakeman::Checks.add self

  @description = "Checks for unsupported versions of Ruby"

  def run_check
    return unless tracker.config.ruby_version

    check_eol_version :ruby, RUBY_EOL_DATES
  end

  RUBY_EOL_DATES = {
    ['0.0.0', '1.9.3'] => Date.new(2015, 2, 23),
    ['2.0.0', '2.0.99'] => Date.new(2016, 2, 24),
    ['2.1.0', '2.1.99'] => Date.new(2017, 3, 31),
    ['2.2.0', '2.2.99'] => Date.new(2018, 3, 31),
    ['2.3.0', '2.3.99'] => Date.new(2019, 3, 31),
    ['2.4.0', '2.4.99'] => Date.new(2020, 3, 31),
    ['2.5.0', '2.5.99'] => Date.new(2021, 3, 31),
    ['2.6.0', '2.6.99'] => Date.new(2022, 3, 31),
    ['2.7.0', '2.7.99'] => Date.new(2023, 3, 31),
    ['3.0.0', '2.8.99'] => Date.new(2024, 3, 31),
  }
end
