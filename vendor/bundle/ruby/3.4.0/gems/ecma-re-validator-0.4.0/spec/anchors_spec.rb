# frozen_string_literal: true

require 'spec_helper'

describe 'EcmaReValidator::Anchors' do
  it 'should pass if regexp has ^' do
    re = '^anchor'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should pass if regexp has $' do
    re = 'anchor$'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should pass if regexp has no \A' do
    re = 'anchor'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should pass if regexp is escaped \A' do
    re = 'anchor\\\\A'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should fail if regexp is not escaped \A' do
    re = 'anchor\\A'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp is not escaped \A, despite backslashes' do
    re = 'anchor\\\\\\A'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should pass if regexp is escaped \A, with many backslashes' do
    re = 'anchor\\\\\\\\A'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should pass if regexp is escaped \Z' do
    re = 'anchor\\\\Z'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should fail if regexp is not escaped \Z' do
    re = 'anchor\\Z'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp is not escaped \Z, despite backslashes' do
    re = 'anchor\\\\\\Z'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should pass if regexp is escaped \Z, with many backslashes' do
    re = 'anchor\\\\\\\\Z'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should pass if regexp is escaped \z' do
    re = 'anchor\\\\z'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should fail if regexp is not escaped \z' do
    re = 'anchor\\z'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp is not escaped \z, despite backslashes' do
    re = 'anchor\\\\\\z'

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should pass if regexp is escaped \z, with many backslashes' do
    re = 'anchor\\\\\\\\z'

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end
end
