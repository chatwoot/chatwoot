# frozen_string_literal: true

RSpec.describe Faraday::Request::Authorization do
  let(:conn) do
    Faraday.new do |b|
      b.request :authorization, auth_type, *auth_config
      b.adapter :test do |stub|
        stub.get('/auth-echo') do |env|
          [200, {}, env[:request_headers]['Authorization']]
        end
      end
    end
  end

  shared_examples 'does not interfere with existing authentication' do
    context 'and request already has an authentication header' do
      let(:response) { conn.get('/auth-echo', nil, authorization: 'OAuth oauth_token') }

      it 'does not interfere with existing authorization' do
        expect(response.body).to eq('OAuth oauth_token')
      end
    end
  end

  let(:response) { conn.get('/auth-echo') }

  describe 'basic_auth' do
    let(:auth_type) { :basic }

    context 'when passed correct params' do
      let(:auth_config) { %w[aladdin opensesame] }

      it { expect(response.body).to eq('Basic YWxhZGRpbjpvcGVuc2VzYW1l') }

      include_examples 'does not interfere with existing authentication'
    end

    context 'when passed very long values' do
      let(:auth_config) { ['A' * 255, ''] }

      it { expect(response.body).to eq("Basic #{'QUFB' * 85}Og==") }

      include_examples 'does not interfere with existing authentication'
    end
  end

  describe 'authorization' do
    let(:auth_type) { :Bearer }

    context 'when passed a string' do
      let(:auth_config) { ['custom'] }

      it { expect(response.body).to eq('Bearer custom') }

      include_examples 'does not interfere with existing authentication'
    end

    context 'when passed a proc' do
      let(:auth_config) { [-> { 'custom_from_proc' }] }

      it { expect(response.body).to eq('Bearer custom_from_proc') }

      include_examples 'does not interfere with existing authentication'
    end

    context 'when passed a callable' do
      let(:callable) { double('Callable Authorizer', call: 'custom_from_callable') }
      let(:auth_config) { [callable] }

      it { expect(response.body).to eq('Bearer custom_from_callable') }

      include_examples 'does not interfere with existing authentication'
    end

    context 'with an argument' do
      let(:response) { conn.get('/auth-echo', nil, 'middle' => 'crunchy surprise') }

      context 'when passed a proc' do
        let(:auth_config) { [proc { |env| "proc #{env.request_headers['middle']}" }] }

        it { expect(response.body).to eq('Bearer proc crunchy surprise') }

        include_examples 'does not interfere with existing authentication'
      end

      context 'when passed a lambda' do
        let(:auth_config) { [->(env) { "lambda #{env.request_headers['middle']}" }] }

        it { expect(response.body).to eq('Bearer lambda crunchy surprise') }

        include_examples 'does not interfere with existing authentication'
      end

      context 'when passed a callable with an argument' do
        let(:callable) do
          Class.new do
            def call(env)
              "callable #{env.request_headers['middle']}"
            end
          end.new
        end
        let(:auth_config) { [callable] }

        it { expect(response.body).to eq('Bearer callable crunchy surprise') }

        include_examples 'does not interfere with existing authentication'
      end
    end

    context 'when passed too many arguments' do
      let(:auth_config) { %w[baz foo] }

      it { expect { response }.to raise_error(ArgumentError) }

      include_examples 'does not interfere with existing authentication'
    end
  end
end
