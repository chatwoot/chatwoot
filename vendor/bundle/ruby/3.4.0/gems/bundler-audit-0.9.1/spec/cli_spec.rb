require 'spec_helper'
require 'bundler/audit/cli'

describe Bundler::Audit::CLI do
  describe ".start" do
    context "with wrong arguments" do
      it "exits with error status code" do
        expect {
          described_class.start ["check", "foo/bar/baz"]
        }.to raise_error(SystemExit) do |error|
          expect(error.success?).to eq(false)
          expect(error.status).to eq(1)
        end
      end
    end
  end

  describe "#stats" do
    let(:size) { 1234 }
    let(:last_updated_at) { Time.now }
    let(:commit_id) { 'f0f97c4c493b853319e029d226e96f2c2f0dc539' }

    let(:database) { double(Bundler::Audit::Database) }

    before do
      expect(Bundler::Audit::Database).to receive(:new).and_return(database)

      expect(database).to receive(:size).and_return(size)
      expect(database).to receive(:last_updated_at).and_return(last_updated_at)
      expect(database).to receive(:commit_id).and_return(commit_id)
    end

    it "prints total advisory count" do
      expect { subject.stats }.to output(
        include(
          "advisories:\t#{size} advisories",
          "last updated:\t#{last_updated_at}",
          "commit:\t#{commit_id}"
        )
      ).to_stdout
    end
  end

  describe "#update" do
    let(:database) { double(Bundler::Audit::Database) }

    before do
      allow(Bundler::Audit::Database).to receive(:new).and_return(database)
    end

    context "not --quiet (the default)" do
      context "when update succeeds" do
        let(:size) { 1234 }
        let(:last_updated_at) { Time.now }
        let(:commit_id) { 'f0f97c4c493b853319e029d226e96f2c2f0dc539' }

        before do
          expect(database).to receive(:update!).and_return(true)
          expect(database).to receive(:size).and_return(size)
          expect(database).to receive(:last_updated_at).and_return(last_updated_at)
          expect(database).to receive(:commit_id).and_return(commit_id)
        end

        it "prints updated message and then the stats" do
          expect { subject.update }.to output(
            include(
              "Updated ruby-advisory-db",
              "ruby-advisory-db:",
              "  advisories:\t#{size} advisories",
              "  last updated:\t#{last_updated_at}",
              "  commit:\t#{commit_id}"
            )
          ).to_stdout
        end
      end

      context "when update fails" do
        before do
          expect(database).to receive(:update!).and_return(false)
        end

        it "prints failure message" do
          expect {
            begin
              subject.update
            rescue SystemExit
            end
          }.to output(/Failed updating ruby-advisory-db!/).to_stderr
        end

        it "exits with error status code" do
          expect {
            # Capture output of `update` only to keep spec output clean.
            # The test regarding specific output is above.
            expect { subject.update }.to output.to_stdout
          }.to raise_error(SystemExit) do |error|
            expect(error.success?).to eq(false)
            expect(error.status).to eq(1)
          end
        end
      end

      context "when git is not installed" do
        before do
          expect(database).to receive(:update!).and_return(nil)

          expect(Bundler).to receive(:git_present?).and_return(false)
        end

        it "prints failure message" do
          expect {
            begin
              subject.update
            rescue SystemExit
            end
          }.to output(/Git is not installed!/).to_stderr
        end

        it "exits with error status code" do
          expect {
            # Capture output of `update` only to keep spec output clean.
            # The test regarding specific output is above.
            expect { subject.update }.to output.to_stdout
          }.to raise_error(SystemExit) do |error|
            expect(error.success?).to eq(false)
            expect(error.status).to eq(1)
          end
        end
      end
    end

    context "--quiet" do
      subject do
        described_class.new([], {quiet: true})
      end

      context "when update succeeds" do
        before do
          expect(database).to(
            receive(:update!).with(quiet: true).and_return(true)
          )
        end

        it "does not print any output" do
          expect { subject.update }.to_not output.to_stdout
        end
      end

      context "when update fails" do
        before do
          expect(database).to(
            receive(:update!).with(quiet: true).and_return(false)
          )
        end

        it "prints failure message" do
          expect {
            begin
              subject.update
            rescue SystemExit
            end
          }.to_not output.to_stderr
        end

        it "exits with error status code" do
          expect {
            # Capture output of `update` only to keep spec output clean.
            # The test regarding specific output is above.
            expect { subject.update }.to output.to_stdout
          }.to raise_error(SystemExit) do |error|
            expect(error.success?).to eq(false)
            expect(error.status).to eq(1)
          end
        end
      end
    end
  end
end
