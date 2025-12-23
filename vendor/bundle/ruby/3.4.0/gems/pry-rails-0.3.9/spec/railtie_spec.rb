# encoding: UTF-8

require 'spec_helper'

if (Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR >= 1) ||
    Rails::VERSION::MAJOR >= 6
  require 'rails/command'
  require 'rails/commands/console/console_command'
else
  require 'rails/commands/console'
end

describe PryRails::Railtie do
  it 'should start Pry instead of IRB and make the helpers available' do
    # Yes, I know this is horrible.
    begin
      $called_start = false
      real_pry = Pry

      silence_warnings do
        ::Pry = Class.new do
          def self.start(*)
            $called_start = true
          end
        end
      end

      Rails::Console.start(Rails.application)

      assert $called_start
    ensure
      silence_warnings do
        ::Pry = real_pry
      end
    end

    %w(app helper reload!).each do |helper|
      TOPLEVEL_BINDING.eval("respond_to?(:#{helper}, true)").must_equal true
    end
  end
end
