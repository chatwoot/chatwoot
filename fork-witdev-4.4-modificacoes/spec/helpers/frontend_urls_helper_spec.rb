require 'rails_helper'

describe FrontendUrlsHelper do
  describe '#frontend_url' do
    context 'without query params' do
      it 'creates path correctly' do
        expect(helper.frontend_url('dashboard')).to eq 'http://test.host/app/dashboard'
      end
    end

    context 'with query params' do
      it 'creates path correctly' do
        expect(helper.frontend_url('dashboard', p1: 'p1', p2: 'p2')).to eq 'http://test.host/app/dashboard?p1=p1&p2=p2'
      end
    end
  end
end
