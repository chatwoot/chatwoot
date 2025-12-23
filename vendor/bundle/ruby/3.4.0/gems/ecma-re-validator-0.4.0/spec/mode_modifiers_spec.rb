# frozen_string_literal: true

require 'spec_helper'

describe 'EcmaReValidator::ModeModifiers' do
  it 'should fail if regexp has simple option' do
    re = '(?i)test'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp has multiple options' do
    re = '(?ism)test'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp has colon option' do
    re = '(?mix:abc)'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp has hyphen option' do
    re = 'te(?-i)st'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end
end
