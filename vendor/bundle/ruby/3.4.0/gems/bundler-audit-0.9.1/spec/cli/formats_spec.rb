require 'spec_helper'
require 'bundler/audit/cli/formats'

describe Bundler::Audit::CLI::Formats do
  describe ".[]" do
    context "when given the name of a registered format" do
      it "should return the format" do
        expect(subject[:text]).to be described_class::Text
      end
    end

    context "when given an unknown name" do
      it { expect(subject[:foo]).to be(nil) }
    end
  end

  describe ".register" do
    context "when given a valid format module" do
      module GoodModule
        def print_report(report)
        end
      end

      let(:name)   { :good_module }
      let(:format) { GoodModule   }

      it "should register the module" do
        subject.register name, format

        expect(subject[name]).to be format
      end
    end

    context "when given a format module that does not define #print_report" do
      module BadModule
        def pront_report(report)
        end
      end

      let(:name)   { :bad_module }
      let(:format) { BadModule   }

      it do
        expect { subject.register(name,format) }.to raise_error(
          NotImplementedError, "#{format.inspect} does not define #print_report"
        )
      end
    end
  end

  describe ".load" do
    LIB_DIR = File.expand_path('../fixtures/lib',File.dirname(__FILE__))

    before(:all) { $LOAD_PATH.unshift(LIB_DIR) }

    context "when given the name of a valid format" do
      let(:name) { :good }

      it "should require and return the format" do
        expect(subject.load(name)).to be described_class::Good
      end
    end

    context "when given the name of a non-existant format" do
      let(:name) { :foo }

      it do
        expect { subject.load(name) }.to raise_error(
          described_class::FormatNotFound, "could not load format \"#{name}\""
        )
      end
    end

    context "when given the name of a printer which incorrectly registers itself" do
      let(:name) { :bad }

      it do
        expect { subject.load(name) }.to raise_error(
          described_class::FormatNotFound, "unknown format \"#{name}\""
        )
      end
    end

    after(:all) { $LOAD_PATH.delete(LIB_DIR) }
  end
end
