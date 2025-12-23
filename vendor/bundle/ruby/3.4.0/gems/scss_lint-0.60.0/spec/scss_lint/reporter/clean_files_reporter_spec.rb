require 'spec_helper'

describe SCSSLint::Reporter::CleanFilesReporter do
  subject { described_class.new(lints, files, nil) }

  describe '#report_lints' do
    context 'when there are no lints and no files' do
      let(:files) { [] }
      let(:lints) { [] }

      it 'returns nil' do
        subject.report_lints.should be_nil
      end
    end

    context 'when there are no lints but some files were linted' do
      let(:files) { [{ 'path' => 'c.scss' }, { 'path' => 'b.scss' }, { 'path' => 'a.scss' }] }
      let(:lints) { [] }

      it 'prints each file on its own line' do
        subject.report_lints.count("\n").should == 3
      end

      it 'prints the files in order' do
        subject.report_lints.split("\n")[0].should eq 'a.scss'
        subject.report_lints.split("\n")[1].should eq 'b.scss'
        subject.report_lints.split("\n")[2].should eq 'c.scss'
      end

      it 'prints a trailing newline' do
        subject.report_lints[-1].should == "\n"
      end
    end

    context 'when there are lints in some files' do
      let(:dirty_files) { [{ 'path' => 'a.scss' }, { 'path' => 'b.scss' }] }
      let(:clean_files) { [{ 'path' => 'c.scss' }, { 'path' => 'd.scss' }] }
      let(:files) { dirty_files + clean_files }

      let(:lints) do
        dirty_files.map do |file|
          SCSSLint::Lint.new(SCSSLint::Linter::Comment.new, file['path'], SCSSLint::Location.new, '')
        end
      end

      it 'prints the file for each lint' do
        clean_files.each do |file|
          subject.report_lints.scan(file['path']).count.should == 1
        end
      end

      it 'does not print clean files' do
        dirty_files.each do |file|
          subject.report_lints.scan(file['path']).count.should == 0
        end
      end
    end

    context 'when there are lints in every file' do
      let(:files) { %w[a.scss b.scss c.scss d.scss] }

      let(:lints) do
        files.map do |file|
          SCSSLint::Lint.new(SCSSLint::Linter::Comment.new, file, SCSSLint::Location.new, '')
        end
      end

      it 'does not print clean files' do
        subject.report_lints.should be_nil
      end
    end
  end
end
