if ENV['TRAVIS']
  # When running in Travis, report coverage stats to Coveralls.
  require 'coveralls'
  Coveralls.wear!
else
  # Otherwise render coverage information in coverage/index.html and display
  # coverage percentage in the console.
  require 'simplecov'
end

require 'scss_lint'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = %i[expect should]
  end

  config.mock_with :rspec do |c|
    c.syntax = :should
  end

  config.before(:each) do
    # If running a linter spec, run the described linter against the CSS code
    # for each example. This significantly DRYs up our linter specs to contain
    # only tests, since all the setup code is now centralized here.
    if described_class && described_class <= SCSSLint::Linter
      initial_indent = scss[/\A(\s*)/, 1]
      normalized_css = scss.gsub(/^#{initial_indent}/, '')

      # Use the configuration settings defined by default unless a specific
      # configuration has been provided for the test.
      local_config = if respond_to?(:linter_config)
                       linter_config
                     else
                       SCSSLint::Config.default.linter_options(subject)
                     end

      subject.run(SCSSLint::Engine.new(code: normalized_css), local_config)
    end
  end
end
