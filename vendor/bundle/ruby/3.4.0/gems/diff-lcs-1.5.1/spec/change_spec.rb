# frozen_string_literal: true

require "spec_helper"

describe Diff::LCS::Change do
  describe "an add" do
    subject { described_class.new("+", 0, "element") }
    it { should_not be_deleting }
    it { should be_adding }
    it { should_not be_unchanged }
    it { should_not be_changed }
    it { should_not be_finished_a }
    it { should_not be_finished_b }
  end

  describe "a delete" do
    subject { described_class.new("-", 0, "element") }
    it { should be_deleting }
    it { should_not be_adding }
    it { should_not be_unchanged }
    it { should_not be_changed }
    it { should_not be_finished_a }
    it { should_not be_finished_b }
  end

  describe "an unchanged" do
    subject { described_class.new("=", 0, "element") }
    it { should_not be_deleting }
    it { should_not be_adding }
    it { should be_unchanged }
    it { should_not be_changed }
    it { should_not be_finished_a }
    it { should_not be_finished_b }
  end

  describe "a changed" do
    subject { described_class.new("!", 0, "element") }
    it { should_not be_deleting }
    it { should_not be_adding }
    it { should_not be_unchanged }
    it { should be_changed }
    it { should_not be_finished_a }
    it { should_not be_finished_b }
  end

  describe "a finished_a" do
    subject { described_class.new(">", 0, "element") }
    it { should_not be_deleting }
    it { should_not be_adding }
    it { should_not be_unchanged }
    it { should_not be_changed }
    it { should be_finished_a }
    it { should_not be_finished_b }
  end

  describe "a finished_b" do
    subject { described_class.new("<", 0, "element") }
    it { should_not be_deleting }
    it { should_not be_adding }
    it { should_not be_unchanged }
    it { should_not be_changed }
    it { should_not be_finished_a }
    it { should be_finished_b }
  end

  describe "as array" do
    it "should be converted" do
      action, position, element = described_class.new("!", 0, "element")
      expect(action).to eq "!"
      expect(position).to eq 0
      expect(element).to eq "element"
    end
  end
end

describe Diff::LCS::ContextChange do
  describe "as array" do
    it "should be converted" do
      action, (old_position, old_element), (new_position, new_element) =
        described_class.new("!", 1, "old_element", 2, "new_element")

      expect(action).to eq "!"
      expect(old_position).to eq 1
      expect(old_element).to eq "old_element"
      expect(new_position).to eq 2
      expect(new_element).to eq "new_element"
    end
  end
end
