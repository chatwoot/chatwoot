require 'rails_helper'

describe Whatsapp::PhoneNormalizers::MexicoPhoneNormalizer do
  subject(:normalizer) { described_class.new }

  describe '#normalize' do
    it 'strips the mobile "1" from the 13-digit form (521 + 10 digits)' do
      expect(normalizer.normalize('5215512345678')).to eq('525512345678')
    end

    it 'leaves the already-normalized 12-digit form untouched' do
      expect(normalizer.normalize('525512345678')).to eq('525512345678')
    end

    it 'does not strip a legitimate leading "1" from a 12-digit national number' do
      expect(normalizer.normalize('521512345678')).to eq('521512345678')
    end

    it 'returns non-Mexico numbers unchanged' do
      expect(normalizer.normalize('5511999998888')).to eq('5511999998888')
    end
  end
end
