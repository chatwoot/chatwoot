require 'spec_helper'

describe SCSSLint::Reporter::StatsReporter do
  class SCSSLint::Linter::FakeLinter1 < SCSSLint::Linter; end
  class SCSSLint::Linter::FakeLinter2 < SCSSLint::Linter; end

  let(:logger) { SCSSLint::Logger.new($stdout) }
  let(:linter_1) { SCSSLint::Linter::FakeLinter1.new }
  let(:linter_2) { SCSSLint::Linter::FakeLinter2.new }
  subject { SCSSLint::Reporter::StatsReporter.new(lints, [], logger) }

  def new_lint(linter, filename, line)
    SCSSLint::Lint.new(linter, filename, SCSSLint::Location.new(line), 'Description', :warning)
  end

  describe '#report_lints' do
    context 'when there are no lints' do
      let(:lints) { [] }

      it 'returns nil' do
        subject.report_lints.should be_nil
      end
    end

    context 'when there are lints from one linter in one file' do
      let(:lints) do
        [new_lint(linter_1, 'a.scss', 10), new_lint(linter_1, 'a.scss', 20)]
      end

      it 'prints one line per linter with lints, plus 2 summary lines' do
        subject.report_lints.count("\n").should eq 3
      end

      it 'prints the name of each linter with lints' do
        subject.report_lints.should include linter_1.name
      end

      it 'prints the number of lints per linter' do
        subject.report_lints.should include '2  FakeLinter1'
      end

      it 'prints the number of files where each linter found lints' do
        subject.report_lints.should include '1 files'
      end

      it 'prints the total lints and total lines' do
        subject.report_lints.should match(/2  total +\(across 1/)
      end
    end

    context 'when there are lints from multiple linters in one file' do
      let(:lints) do
        [new_lint(linter_1, 'a.scss', 10),
         new_lint(linter_1, 'a.scss', 20),
         new_lint(linter_2, 'a.scss', 30)]
      end

      it 'prints one line per linter with lints, plus 2 summary lines' do
        subject.report_lints.count("\n").should eq 4
      end

      it 'prints the name of each linter with lints' do
        subject.report_lints.scan(linter_1.name).count.should eq 1
        subject.report_lints.scan(linter_2.name).count.should eq 1
      end

      it 'prints the number of lints per linter' do
        subject.report_lints.should include '2  FakeLinter1'
        subject.report_lints.should include '1  FakeLinter2'
      end

      it 'prints the number of files where each linter found lints' do
        subject.report_lints.scan(/FakeLinter\d +\(across 1 files/).count.should eq 2
      end

      it 'prints the total lints and total lines' do
        subject.report_lints.should match(/3  total +\(across 1/)
      end
    end

    context 'when there are lints from multiple linters in multiple files' do
      let(:lints) do
        [new_lint(linter_1, 'a.scss', 10),
         new_lint(linter_1, 'a.scss', 20),
         new_lint(linter_2, 'a.scss', 30),
         new_lint(linter_1, 'b.scss', 15),
         new_lint(linter_2, 'b.scss', 25),
         new_lint(linter_1, 'c.scss', 100)]
      end

      it 'prints one line per linter with lints, plus 2 summary lines' do
        subject.report_lints.count("\n").should eq 4
      end

      it 'prints the name of each linter with lints' do
        subject.report_lints.scan(linter_1.name).count.should eq 1
        subject.report_lints.scan(linter_2.name).count.should eq 1
      end

      it 'prints the number of lints per linter' do
        subject.report_lints.should include '4  FakeLinter1'
        subject.report_lints.should include '2  FakeLinter2'
      end

      it 'prints the number of files where each linter found lints' do
        subject.report_lints.scan(/FakeLinter2 +\(across 2 files/).count.should eq 1
        subject.report_lints.scan(/FakeLinter1 +\(across 3 files/).count.should eq 1
      end

      it 'prints the total lints and total lines' do
        subject.report_lints.should match(/6  total +\(across 3/)
      end
    end
  end
end
