# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rack::Attack::Request do
  describe '#ip' do
    let(:remote_ip_value) { instance_double(Object, to_s: '198.51.100.2') }

    context 'when action_dispatch.remote_ip is set' do
      let(:env) do
        {
          'REMOTE_ADDR' => '10.0.0.1',
          'action_dispatch.remote_ip' => remote_ip_value
        }
      end

      it 'returns the Rails-resolved client IP string' do
        request = described_class.new(env)
        expect(request.ip).to eq('198.51.100.2')
      end

      it 'matches #remote_ip' do
        request = described_class.new(env)
        expect(request.remote_ip).to eq(request.ip)
      end
    end

    context 'when action_dispatch.remote_ip is absent' do
      let(:env) { { 'REMOTE_ADDR' => '192.0.2.1' } }

      it 'falls back to Rack::Request#ip' do
        request = described_class.new(env)
        expect(request.ip).to eq('192.0.2.1')
      end
    end
  end
end
