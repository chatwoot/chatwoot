require 'rails_helper'

describe Digitaltolk::Openai::Base do
  subject { described_class.new }

  describe '#initialize' do
    it 'initializes the client' do
      subject
      expect(subject.instance_variable_get(:@client)).to be_a(OpenAI::Client)
    end
  end

  describe 'parse_response' do
    let(:response) do
      { 'response' => 'response' }
    end

    context 'when response is a hash' do
      it 'returns a hash' do
        expect(subject.send(:parse_response, response)).to eq({ 'response' => 'response' })
      end
    end

    context 'when response is a string' do
      it 'returns a hash' do
        expect(subject.send(:parse_response, response.to_json)).to eq({ 'response' => 'response' })
      end
    end

    context 'when response is null' do
      it 'returns a empty hash' do
        expect(subject.send(:parse_response, nil)).to eq({})
      end
    end
  end
end
