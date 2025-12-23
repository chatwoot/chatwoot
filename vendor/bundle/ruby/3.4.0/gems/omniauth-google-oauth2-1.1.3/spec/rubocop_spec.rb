# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Rubocop' do
  it 'should pass with no offenses detected' do
    expect(`rubocop`).to include('no offenses detected')
  end
end
