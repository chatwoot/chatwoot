require 'spec_helper'

describe SCSSLint::Reporter::JSONReporter do
  subject { SCSSLint::Reporter::JSONReporter.new(lints, [], nil) }

  describe '#report_lints' do
    let(:json) { JSON.parse(subject.report_lints) }

    shared_examples_for 'parsed JSON' do
      it 'is a Hash' do
        json.is_a?(Hash)
      end
    end

    context 'when there are no lints' do
      let(:lints) { [] }

      it_should_behave_like 'parsed JSON'
    end

    context 'when there are lints' do
      let(:filenames)    { ['f1.scss', 'f2.scss', 'f1.scss'] }
      # Include invalid XML characters in the third description to validate
      # that escaping happens for preventing broken XML output
      let(:descriptions) { ['lint 1', 'lint 2', 'lint 3 " \' < & >'] }
      let(:severities)   { [:warning] * 3 }

      let(:locations)    do
        [
          SCSSLint::Location.new(5,  2, 3),
          SCSSLint::Location.new(7,  6, 2),
          SCSSLint::Location.new(9, 10, 1)
        ]
      end

      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          SCSSLint::Lint.new(SCSSLint::LinterRegistry.linters.sample, filename, locations[index],
                             descriptions[index], severities[index])
        end
      end

      it_should_behave_like 'parsed JSON'

      it 'contains an <issue> node for each lint' do
        json.values.inject(0) { |sum, issues| sum + issues.size }.should == 3
      end

      it 'contains a group of issues for each file' do
        json.keys.should == filenames.uniq
      end

      it 'contains <issue> nodes grouped by <file>' do
        json.values.map(&:size).should == [2, 1]
      end

      it 'marks each issue with a line number' do
        json.values.flat_map { |issues| issues.map { |issue| issue['line'] } }
            .should =~ locations.map(&:line)
      end

      it 'marks each issue with a column number' do
        json.values.flat_map { |issues| issues.map { |issue| issue['column'] } }
            .should =~ locations.map(&:column)
      end

      it 'marks each issue with a length' do
        json.values.flat_map { |issues| issues.map { |issue| issue['length'] } }
            .should =~ locations.map(&:length)
      end

      it 'marks each issue with a reason containing the lint description' do
        json.values.flat_map { |issues| issues.map { |issue| issue['reason'] } }
            .should =~ descriptions
      end

      context 'when lints are warnings' do
        it 'marks each issue with a severity of "warning"' do
          json.values.inject(0) do |sum, issues|
            sum + issues.count { |i| i['severity'] == 'warning' }
          end.should == 3
        end
      end

      context 'when lints are errors' do
        let(:severities) { [:error] * 3 }

        it 'marks each issue with a severity of "error"' do
          json.values.inject(0) do |sum, issues|
            sum + issues.count { |i| i['severity'] == 'error' }
          end.should == 3
        end
      end
    end
  end
end
