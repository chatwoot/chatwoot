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
    it 'returns nothing for a blank list' do
      expect(helper.process_email_string(nil)).to eq []
      expect(helper.process_email_string('')).to eq []
    end

    it 'accepts comma, semicolon and space separated addresses' do
      expect(helper.process_email_string('a@test.com,b@test.com')).to eq ['a@test.com', 'b@test.com']
      expect(helper.process_email_string('a@test.com; b@test.com')).to eq ['a@test.com', 'b@test.com']
      expect(helper.process_email_string('a@test.com b@test.com')).to eq ['a@test.com', 'b@test.com']
    end

    it 'takes the address out of a display name form' do
      expect(helper.process_email_string('Jane Smith <jane@test.com>, John Doe <john@test.com>')).to eq ['jane@test.com', 'john@test.com']
    end

    it 'keeps a comma and an @ inside a quoted display name' do
      expect(helper.process_email_string('"Doe, John" <john@test.com>, jane@test.com')).to eq ['john@test.com', 'jane@test.com']
      expect(helper.process_email_string('"support@test.com" <agent@test.com>')).to eq ['agent@test.com']
      expect(helper.process_email_string('"support@test.com \\"team\\"" <agent@test.com>')).to eq ['agent@test.com']
    end

    it 'rejects a recipient swallowed into an unquoted display name instead of dropping it' do
      # Each of these would otherwise send to the last address only, losing the first silently.
      ['a@test.com Jane Doe <b@test.com>', 'a@test.com b@test.com <c@test.com>',
       '"Team" jane@test.com John Doe <john@test.com>'].each do |list|
        expect { helper.process_email_string(list) }.to raise_error(StandardError, 'Invalid email address'), list
      end
    end

    it 'allows angle brackets inside a quoted display name' do
      expect(helper.process_email_string('"Ops <West>" <ops@test.com>')).to eq ['ops@test.com']
      expect(helper.process_email_string('"Ops <West>" <ops@test.com>, jane@test.com')).to eq ['ops@test.com', 'jane@test.com']
    end

    it 'still finds a recipient swallowed in after a quoted name holding angle brackets' do
      expect do
        helper.process_email_string('"Team <West>" jane@test.com John Doe <john@test.com>')
      end.to raise_error StandardError, 'Invalid email address'
    end

    it 'rejects a list it cannot parse' do
      expect { helper.process_email_string('Jane <') }.to raise_error StandardError, 'Invalid email address'
      expect { helper.process_email_string('"Jane <jane@test.com>') }.to raise_error StandardError, 'Invalid email address'
    end
  end
end
