require 'spec_helper'

describe SCSSLint::Reporter::ConfigReporter do
  subject { YAML.load(result) }
  let(:result) { described_class.new(lints, [], nil).report_lints }

  describe '#report_lints' do
    context 'when there are no lints' do
      let(:lints) { [] }

      it 'returns nil' do
        result.should be_nil
      end
    end

    context 'when there are lints' do
      let(:linters) do
        [SCSSLint::Linter::FinalNewline, SCSSLint::Linter::BorderZero,
         SCSSLint::Linter::BorderZero]
      end
      let(:lints) do
        linters.each.map do |linter|
          SCSSLint::Lint.new(linter.new, '',
                             SCSSLint::Location.new, '')
        end
      end

      it 'adds one entry per linter' do
        subject['linters'].size.should eq 2
      end

      it 'sorts linters by name' do
        subject['linters'].map(&:first).should eq %w[BorderZero FinalNewline]
      end

      it 'disables all found linters' do
        subject['linters']['BorderZero']['enabled'].should eq false
        subject['linters']['FinalNewline']['enabled'].should eq false
      end
    end
  end
end
