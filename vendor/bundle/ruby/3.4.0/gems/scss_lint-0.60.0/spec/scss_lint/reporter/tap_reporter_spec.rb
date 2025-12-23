require 'spec_helper'

describe SCSSLint::Reporter::TAPReporter do
  let(:logger) { SCSSLint::Logger.new($stdout) }
  let(:files) { filenames.map { |filename| { path: filename } } }
  subject { described_class.new(lints, files, logger) }

  describe '#report_lints' do
    context 'when there are no files' do
      let(:filenames) { [] }
      let(:lints) { [] }

      it 'returns the TAP version, plan, and explanation' do
        subject.report_lints.should == "TAP version 13\n1..0 # No files to lint\n"
      end
    end

    context 'when there are files but no lints' do
      let(:filenames) { ['file.scss', 'another-file.scss'] }
      let(:lints) { [] }

      it 'returns the TAP version, plan, and ok test lines' do
        subject.report_lints.should eq(<<-LINES)
TAP version 13
1..2
ok 1 - file.scss
ok 2 - another-file.scss
        LINES
      end
    end

    context 'when there are some lints' do
      let(:filenames) { %w[ok1.scss not-ok1.scss not-ok2.scss ok2.scss] }

      let(:lints) do
        [
          SCSSLint::Lint.new(
            SCSSLint::Linter::PrivateNamingConvention,
            filenames[1],
            SCSSLint::Location.new(123, 10, 8),
            'Description of lint 1',
            :warning
          ),
          SCSSLint::Lint.new(
            SCSSLint::Linter::PrivateNamingConvention,
            filenames[2],
            SCSSLint::Location.new(20, 2, 6),
            'Description of lint 2',
            :error
          ),
          SCSSLint::Lint.new(
            SCSSLint::Linter::PrivateNamingConvention,
            filenames[2],
            SCSSLint::Location.new(21, 3, 4),
            'Description of lint 3',
            :warning
          ),
        ]
      end

      it 'returns the TAP version, plan, and correct test lines' do
        subject.report_lints.should eq(<<-LINES)
TAP version 13
1..5
ok 1 - ok1.scss
not ok 2 - not-ok1.scss:123:10 SCSSLint::Linter::PrivateNamingConvention
  ---
  message: Description of lint 1
  severity: warning
  file: not-ok1.scss
  line: 123
  column: 10
  name: SCSSLint::Linter::PrivateNamingConvention
  ...
not ok 3 - not-ok2.scss:20:2 SCSSLint::Linter::PrivateNamingConvention
  ---
  message: Description of lint 2
  severity: error
  file: not-ok2.scss
  line: 20
  column: 2
  name: SCSSLint::Linter::PrivateNamingConvention
  ...
not ok 4 - not-ok2.scss:21:3 SCSSLint::Linter::PrivateNamingConvention
  ---
  message: Description of lint 3
  severity: warning
  file: not-ok2.scss
  line: 21
  column: 3
  name: SCSSLint::Linter::PrivateNamingConvention
  ...
ok 5 - ok2.scss
        LINES
      end
    end
  end
end
