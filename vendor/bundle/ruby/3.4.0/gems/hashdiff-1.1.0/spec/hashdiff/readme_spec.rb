# frozen_string_literal: true

require 'spec_helper'

describe 'README.md' do
  it 'has correct examples' do
    File.read('README.md').scan(/```ruby(.*?)```/m).flatten(1).each do |block|
      begin
        eval block # rubocop:disable Security/Eval
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise "README.md code block:\n#{block}\n\nhas error:\n#{e}"
      end
    end
  end
end
