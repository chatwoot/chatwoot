# frozen_string_literal: true

require 'spec_helper'

describe 'EcmaReValidator::PossesiveQuantifiers' do
  it 'should fail if regexp has *+ possesive quantifier' do
    re = /"[^"]*+"/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp has ++ possesive quantifier' do
    re = /"[^"]++"/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp has ?+ possesive quantifier' do
    re = /"[^"]?+"/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end
end
