# frozen_string_literal: true

require 'spec_helper'

describe 'EcmaRe' do
  it 'should fail if input is not a string or regexp' do
    re = 92

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if string is not resolvable' do
    re = '(\w'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'passes for a valid regexp string' do
    re = '[Ss]mith\\\\b'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'passes for a valid regexp' do
    re = /[Ss]mith\\\\b/

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end
end
