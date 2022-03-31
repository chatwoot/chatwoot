require 'rails_helper'

describe UrlHelper, type: :helper do
  describe '#url_valid' do
    context 'when url valid called' do
      it 'return if valid url passed' do
        expect(helper.url_valid?('https://app.chatwoot.com/')).to eq true
      end

      it 'return false if invalid url passed' do
        expect(helper.url_valid?('javascript:alert(document.cookie)')).to eq false
      end
    end
  end
end
