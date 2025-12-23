# frozen_string_literal: true

require 'spec_helper'

describe 'EcmaReValidator::AtomicGrouping' do
  it 'should fail if regexp has atomic grouping' do
    re = /\b(?>integer|insert|in)\b./

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end
end
