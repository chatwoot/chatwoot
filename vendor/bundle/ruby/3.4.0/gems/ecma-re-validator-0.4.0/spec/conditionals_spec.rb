# frozen_string_literal: true

require 'spec_helper'

describe 'EcmaReValidator::Conditionals' do
  it 'should pass if regexp is using just (?...)' do
    re = '(?:Aa)'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should fail if regexp is using complicated if-then-else' do
    re = '(?(?=condition)(then1|then2|then3)|(else1|else2|else3))'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp is using basic if-then-else' do
    re = 'b(?(1)c|d)'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end
end
