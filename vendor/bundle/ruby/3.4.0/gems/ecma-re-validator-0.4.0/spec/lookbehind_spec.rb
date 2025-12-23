# frozen_string_literal: true

require 'spec_helper'

describe 'EcmaReValidator::Lookbehind' do
  it 'should fail if regexp has a positive lookbehind' do
    re = '(?<=a)b'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should pass if regexp has an escaped positive lookbehind' do
    re = '\\(?<=a\\)b'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should fail if regexp has a negative lookbehind' do
    re = '(?<!a)b'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should pass if regexp has an escaped negative lookbehind' do
    re = '\\(?<!a\\)b'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end
end
