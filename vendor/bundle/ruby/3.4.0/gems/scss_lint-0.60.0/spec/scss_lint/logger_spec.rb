require 'spec_helper'

describe SCSSLint::Logger do
  let(:io)     { StringIO.new }
  let(:logger) { described_class.new(io) }

  describe '#color_enabled' do
    subject { io.string }

    before do
      logger.color_enabled = enabled
      logger.success('Success!')
    end

    context 'when color is enabled' do
      let(:enabled) { true }

      it { should include '32' }
    end

    context 'when color is disabled' do
      let(:enabled) { false }

      it { should_not include '32' }
    end
  end
end
