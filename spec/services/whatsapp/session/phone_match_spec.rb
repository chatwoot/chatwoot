require 'rails_helper'

RSpec.describe Whatsapp::Session::PhoneMatch do
  it 'matches a Brazilian line with and without its ninth digit' do
    expect(described_class.same_number?('+55 41 98888-7777', '554188887777')).to be(true)
  end

  it 'matches an Argentinian line with and without its 9' do
    expect(described_class.same_number?('+5491123456789', '541123456789')).to be(true)
  end

  it 'does not match two different lines' do
    expect(described_class.same_number?('5541988887777', '5541900001111')).to be(false)
  end

  # No normalizer knows this country, so the only safe answer for two different strings
  # is "not the same line": guessing would merge two unrelated numbers.
  it 'falls back to an exact comparison where no normalizer applies' do
    expect(described_class.same_number?('12025550100', '12025550100')).to be(true)
    expect(described_class.same_number?('12025550100', '12025550101')).to be(false)
  end

  it 'lists both ninth-digit forms of a Brazilian line' do
    expect(described_class.variants('5541988887777')).to contain_exactly('5541988887777', '554188887777')
  end

  it 'lists a number no normalizer knows as itself' do
    expect(described_class.variants('12025550100')).to eq(['12025550100'])
    expect(described_class.variants(nil)).to eq([])
  end

  it 'refuses to match anything against a blank' do
    expect(described_class.same_number?(nil, '5541988887777')).to be(false)
    expect(described_class.same_number?('', '')).to be(false)
  end
end
