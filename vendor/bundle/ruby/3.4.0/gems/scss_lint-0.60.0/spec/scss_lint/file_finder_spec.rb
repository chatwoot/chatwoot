require 'spec_helper'
require 'fileutils'

describe SCSSLint::FileFinder do
  let(:config) { SCSSLint::Config.default }

  subject { described_class.new(config) }

  describe '#find' do
    include_context 'isolated environment'

    subject { super().find(patterns) }

    context 'when no patterns are given' do
      let(:patterns) { [] }

      it 'raises an error' do
        expect { subject }.to raise_error SCSSLint::Exceptions::NoFilesError
      end
    end

    context 'when files without valid extension are given' do
      let(:patterns) { ['test.txt'] }

      context 'and those files exist' do
        before do
          FileUtils.touch('test.txt')
        end

        it { should == ['test.txt'] }
      end

      context 'and those files do not exist' do
        it { should == ['test.txt'] }
      end
    end

    context 'when directories are given' do
      let(:patterns) { ['some-dir'] }

      context 'and those directories exist' do
        before do
          `mkdir -p some-dir`
        end

        context 'and they contain SCSS files' do
          before do
            FileUtils.touch(File.join('some-dir', 'test.scss'))
          end

          it { should == [File.join('some-dir', 'test.scss')] }

          context 'and those SCSS files are excluded by the config' do
            before do
              config.exclude_file('some-dir/test.scss')
            end

            it { should == [] }
          end
        end

        context 'and they contain CSS files' do
          before do
            FileUtils.touch(File.join('some-dir', 'test.css'))
          end

          it { should == [File.join('some-dir', 'test.css')] }
        end

        context 'and they contain more directories with files with recognized extensions' do
          before do
            `mkdir -p some-dir/more-dir`
            FileUtils.mkdir_p(File.join('some-dir', 'more-dir'))
            FileUtils.touch(File.join('some-dir', 'more-dir', 'test.scss'))
          end

          it { should == [File.join('some-dir', 'more-dir', 'test.scss')] }

          context 'and those SCSS files are excluded by the config' do
            before do
              config.exclude_file('**/*.scss')
            end

            it { should == [] }
          end
        end

        context 'and they contain no SCSS files' do
          before do
            FileUtils.touch(File.join('some-dir', 'test.txt'))
          end

          it 'raises an error' do
            expect { subject }.to raise_error SCSSLint::Exceptions::NoFilesError
          end
        end
      end

      context 'and those directories do not exist' do
        it { should == ['some-dir'] }
      end
    end

    context 'when the same file is specified multiple times' do
      let(:patterns) { ['test.scss'] * 3 }

      it { should == ['test.scss'] }
    end
  end
end
