require "spec_helper"
require "foreman/export"

describe "Foreman::Export" do
  subject { Foreman::Export }

  describe "with a formatter that doesn't declare the appropriate class" do
    it "prints an error" do
      expect(subject).to receive(:require).with("foreman/export/invalidformatter")
      mock_export_error("Unknown export format: invalidformatter (no class Foreman::Export::Invalidformatter).") do
        subject.formatter("invalidformatter") 
      end
    end
  end

  describe "with an invalid formatter" do

    it "prints an error" do
      mock_export_error("Unknown export format: invalidformatter (unable to load file 'foreman/export/invalidformatter').") do
        subject.formatter("invalidformatter")
      end
    end
  end
end
