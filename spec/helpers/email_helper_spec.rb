require 'rails_helper'

describe EmailHelper do
  describe '#normalize_email_with_plus_addressing' do
    context 'when email is passed' do
      it 'normalise if plus addressing is present' do
        expect(helper.normalize_email_with_plus_addressing('john+test@acme.inc')).to eq 'john@acme.inc'
      end

      it 'returns original if plus addressing is not present' do
        expect(helper.normalize_email_with_plus_addressing('john@acme.inc')).to eq 'john@acme.inc'
      end

      it 'returns downcased version of email' do
        expect(helper.normalize_email_with_plus_addressing('JoHn+AAsdfss@acme.inc')).to eq 'john@acme.inc'
      end
    end
  end

  describe '#process_email_string' do
    it 'splits emails delimited by commas or semicolons' do
      expect(helper.process_email_string('a@example.com, b@example.com; c@example.com')).to eq ['a@example.com', 'b@example.com', 'c@example.com']
    end

    it 'handles array inputs and removes whitespace within individual emails' do
      expect(helper.process_email_string(['a @example.com', 'b@example.com c@example.com'])).to eq ['a@example.com', 'b@example.com', 'c@example.com']
    end
  end
end
