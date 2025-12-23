# frozen_string_literal: true

require 'spec_helper'

describe 'EcmaReValidator::Comments' do
  it 'should fail if regexp has inline comments' do
    re = /(?#comment)hello/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp has inline comments across lines' do
    re = /
          start         # some text
          \s            # white space char
          (group)       # first group
          (?:alt1|alt2) # some alternation
          end
        /x

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end
end
