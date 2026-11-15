require 'rails_helper'

describe Whatsapp::PhoneNormalizers::BrazilPhoneNormalizer do
  describe '#contact_candidates' do
    it 'preserves a partial Brazil number without raising' do
      expect(described_class.new.contact_candidates('55')).to eq(['55'])
    end
  end
end
