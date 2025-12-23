# frozen_string_literal: true

require 'spec_helper'

describe 'EcmaReValidator::Unicode' do
  it 'should fail if regexp uses \p{L} or \p{Letter}' do
    re = /\p{L}/

    expect(EcmaReValidator.valid?(re)).to eql(false)

    re = /\p{Letter}/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp uses \p{M} or \p{Mark}' do
    re = /\p{M}/

    expect(EcmaReValidator.valid?(re)).to eql(false)

    re = /\p{Mark}/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp uses \p{Z} or \p{Separator}' do
    re = /\p{Z}/

    expect(EcmaReValidator.valid?(re)).to eql(false)

    re = /\p{Separator}/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp uses \p{S} or \p{Symbol}' do
    re = /\p{S}/

    expect(EcmaReValidator.valid?(re)).to eql(false)

    re = /\p{Symbol}/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp uses \p{N} or \p{Number}' do
    re = /\p{N}/

    expect(EcmaReValidator.valid?(re)).to eql(false)

    re = /\p{Number}/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp uses \p{P} or \p{Punctuation}' do
    re = /\p{P}/

    expect(EcmaReValidator.valid?(re)).to eql(false)

    re = /\p{Punctuation}/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp uses \p{C} or \p{Other}' do
    re = /\p{C}/

    expect(EcmaReValidator.valid?(re)).to eql(false)

    re = /\p{Other}/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  it 'should fail if regexp uses a script' do
    re = /\p{Armenian}/

    expect(EcmaReValidator.valid?(re)).to eql(false)
  end

  # not yet supported
  # it 'should fail if regexp uses a block' do
  #   re = /\p{InArmenian}/
  #
  #   expect(EcmaReValidator.valid?(re)).to eql(false)
  # end

  it 'should pass if regexp uses a \u' do
    re = /\uf8f8/

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should pass if regexp uses a \x' do
    re = /\x22/

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should pass if regexp uses a \w' do
    re = /^\w+/

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should pass if regexp uses a \s' do
    re = /\s*wow/

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end

  it 'should pass if regexp uses a \d' do
    re = /\d$/

    expect(EcmaReValidator.valid?(re)).to eql(true)
  end
end
