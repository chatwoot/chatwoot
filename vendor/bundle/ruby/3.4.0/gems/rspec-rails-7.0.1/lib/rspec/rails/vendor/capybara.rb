begin
  require 'capybara/rspec'
rescue LoadError
end

begin
  require 'capybara/rails'
rescue LoadError
end

if defined?(Capybara)
  RSpec.configure do |c|
    if defined?(Capybara::DSL)
      c.include Capybara::DSL, type: :feature
      c.include Capybara::DSL, type: :system
    end

    if defined?(Capybara::RSpecMatchers)
      c.include Capybara::RSpecMatchers, type: :view
      c.include Capybara::RSpecMatchers, type: :helper
      c.include Capybara::RSpecMatchers, type: :mailer
      c.include Capybara::RSpecMatchers, type: :controller
      c.include Capybara::RSpecMatchers, type: :feature
      c.include Capybara::RSpecMatchers, type: :system
    end

    unless defined?(Capybara::RSpecMatchers) || defined?(Capybara::DSL)
      c.include Capybara, type: :request
      c.include Capybara, type: :controller
    end
  end
end
