require 'rails_helper'

describe EmailHelper do
  describe '#normalize_email_with_plus_addressing' do
    context 'when email is passed' do
      it 'normalise if plus addressing is present' do
        expect(helper.normalize_email_with_plus_addressing('john+test@acme.inc')).to eq 'admin@example.com'
      end

      it 'returns original if plus addressing is not present' do
        expect(helper.normalize_email_with_plus_addressing('admin@example.com')).to eq 'admin@example.com'
      end

      it 'returns downcased version of email' do
        expect(helper.normalize_email_with_plus_addressing('JoHn+AAsdfss@acme.inc')).to eq 'admin@example.com'
      end
    end
  end
end
