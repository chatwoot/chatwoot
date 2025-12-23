# frozen_string_literal: true

require 'spec_helper'

describe 'EcmaReValidator::NamedCaptureGroups' do
  it 'should fail if regexp has named capture group using ?<>' do
    re = /(?<name>group)/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp has named capture group using ?\'\'' do
    re = /(?'name'group)/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end
end
