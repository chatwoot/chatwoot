require 'rails_helper'

RSpec.describe PaymentCustomerSanitizable do
  let(:test_class) do
    Class.new do
      include PaymentCustomerSanitizable

      # Expose private method for testing
      public :sanitize_customer_name
    end
  end

  let(:sanitizer) { test_class.new }

  describe '#sanitize_customer_name' do
    context 'with normal names' do
      it 'returns the name unchanged' do
        expect(sanitizer.sanitize_customer_name('John Smith')).to eq('John Smith')
      end

      it 'preserves hyphens in names' do
        expect(sanitizer.sanitize_customer_name('Jean-Pierre')).to eq('Jean-Pierre')
      end

      it 'preserves apostrophes in names' do
        expect(sanitizer.sanitize_customer_name("O'Brien")).to eq("O'Brien")
      end

      it 'preserves dots in names' do
        expect(sanitizer.sanitize_customer_name('J. Smith')).to eq('J. Smith')
      end

      it 'handles compound names with hyphens and apostrophes' do
        expect(sanitizer.sanitize_customer_name("Jean-Pierre O'Brien")).to eq("Jean-Pierre O'Brien")
      end
    end

    context 'with Unicode names' do
      it 'preserves Arabic names' do
        expect(sanitizer.sanitize_customer_name('محمد علي')).to eq('محمد علي')
      end

      it 'preserves Chinese names' do
        expect(sanitizer.sanitize_customer_name('张三')).to eq('张三')
      end

      it 'preserves Cyrillic names' do
        expect(sanitizer.sanitize_customer_name('Иван Петров')).to eq('Иван Петров')
      end

      it 'preserves accented Latin names' do
        expect(sanitizer.sanitize_customer_name('José García')).to eq('José García')
      end
    end

    context 'with invalid names that fall back to default' do
      it 'returns Customer for nil' do
        expect(sanitizer.sanitize_customer_name(nil)).to eq('Customer')
      end

      it 'returns Customer for empty string' do
        expect(sanitizer.sanitize_customer_name('')).to eq('Customer')
      end

      it 'returns Customer for emoji-only names' do
        expect(sanitizer.sanitize_customer_name('😊')).to eq('Customer')
      end

      it 'returns Customer for multiple emojis' do
        expect(sanitizer.sanitize_customer_name('😊🎉🔥')).to eq('Customer')
      end

      it 'returns Customer for symbol-only names' do
        expect(sanitizer.sanitize_customer_name('!!@@##')).to eq('Customer')
      end

      it 'returns Customer for dots-only names' do
        expect(sanitizer.sanitize_customer_name('..')).to eq('Customer')
      end

      it 'returns Customer for a single dot' do
        expect(sanitizer.sanitize_customer_name('.')).to eq('Customer')
      end

      it 'returns Customer for multiple dots' do
        expect(sanitizer.sanitize_customer_name('...')).to eq('Customer')
      end

      it 'returns Customer for hyphens-only' do
        expect(sanitizer.sanitize_customer_name('---')).to eq('Customer')
      end

      it 'returns Customer for apostrophes-only' do
        expect(sanitizer.sanitize_customer_name("'''")).to eq('Customer')
      end

      it 'returns Customer for mixed punctuation without letters' do
        expect(sanitizer.sanitize_customer_name(".-'-..")).to eq('Customer')
      end

      it 'returns Customer for phone numbers' do
        expect(sanitizer.sanitize_customer_name('+96512345678')).to eq('Customer')
      end

      it 'returns Customer for a single letter' do
        expect(sanitizer.sanitize_customer_name('A')).to eq('Customer')
      end

      it 'returns Customer for a single Unicode letter' do
        expect(sanitizer.sanitize_customer_name('م')).to eq('Customer')
      end
    end

    context 'with mixed valid and invalid characters' do
      it 'strips digits from names' do
        expect(sanitizer.sanitize_customer_name('John123')).to eq('John')
      end

      it 'strips emojis but keeps the text' do
        expect(sanitizer.sanitize_customer_name('John 😊 Smith')).to eq('John Smith')
      end

      it 'strips special symbols but keeps name characters' do
        expect(sanitizer.sanitize_customer_name('John!@#Smith')).to eq('JohnSmith')
      end
    end

    context 'with whitespace normalization' do
      it 'collapses multiple spaces' do
        expect(sanitizer.sanitize_customer_name('John    Smith')).to eq('John Smith')
      end

      it 'trims leading and trailing spaces' do
        expect(sanitizer.sanitize_customer_name('  John Smith  ')).to eq('John Smith')
      end

      it 'handles tabs and newlines' do
        expect(sanitizer.sanitize_customer_name("John\t\nSmith")).to eq('John Smith')
      end
    end
  end
end
