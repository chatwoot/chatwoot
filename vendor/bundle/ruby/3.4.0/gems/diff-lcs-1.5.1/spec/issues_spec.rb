# frozen_string_literal: true

require "spec_helper"
require "diff/lcs/hunk"

describe "Diff::LCS Issues" do
  include Diff::LCS::SpecHelper::Matchers

  describe "issue #1" do
    shared_examples "handles simple diffs" do |s1, s2, forward_diff|
      before do
        @diff_s1_s2 = Diff::LCS.diff(s1, s2)
      end

      it "creates the correct diff" do
        expect(change_diff(forward_diff)).to eq(@diff_s1_s2)
      end

      it "creates the correct patch s1->s2" do
        expect(Diff::LCS.patch(s1, @diff_s1_s2)).to eq(s2)
      end

      it "creates the correct patch s2->s1" do
        expect(Diff::LCS.patch(s2, @diff_s1_s2)).to eq(s1)
      end
    end

    describe "string" do
      it_has_behavior "handles simple diffs", "aX", "bXaX", [
        [
          ["+", 0, "b"],
          ["+", 1, "X"]
        ]
      ]
      it_has_behavior "handles simple diffs", "bXaX", "aX", [
        [
          ["-", 0, "b"],
          ["-", 1, "X"]
        ]
      ]
    end

    describe "array" do
      it_has_behavior "handles simple diffs", %w[a X], %w[b X a X], [
        [
          ["+", 0, "b"],
          ["+", 1, "X"]
        ]
      ]
      it_has_behavior "handles simple diffs", %w[b X a X], %w[a X], [
        [
          ["-", 0, "b"],
          ["-", 1, "X"]
        ]
      ]
    end
  end

  describe "issue #57" do
    it "should fail with a correct error" do
      # standard:disable Style/HashSyntax
      expect {
        actual = {:category => "app.rack.request"}
        expected = {:category => "rack.middleware", :title => "Anonymous Middleware"}
        expect(actual).to eq(expected)
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      # standard:enable Style/HashSyntax
    end
  end

  describe "issue #60" do
    it "should produce unified output with correct context" do
      # standard:disable Layout/HeredocIndentation
      old_data = <<-DATA_OLD.strip.split("\n").map(&:chomp)
{
  "name": "x",
  "description": "hi"
}
      DATA_OLD

      new_data = <<-DATA_NEW.strip.split("\n").map(&:chomp)
{
  "name": "x",
  "description": "lo"
}
      DATA_NEW

      diff = ::Diff::LCS.diff(old_data, new_data)
      hunk = ::Diff::LCS::Hunk.new(old_data, new_data, diff.first, 3, 0)

      expect(hunk.diff(:unified)).to eq(<<-EXPECTED.chomp)
@@ -1,5 +1,5 @@
 {
   "name": "x",
-  "description": "hi"
+  "description": "lo"
 }
      EXPECTED
      # standard:enable Layout/HeredocIndentation
    end
  end

  describe "issue #65" do
    def diff_lines(old_lines, new_lines)
      file_length_difference = 0
      previous_hunk = nil
      output = []

      Diff::LCS.diff(old_lines, new_lines).each do |piece|
        hunk = Diff::LCS::Hunk.new(old_lines, new_lines, piece, 3, file_length_difference)
        file_length_difference = hunk.file_length_difference
        maybe_contiguous_hunks = previous_hunk.nil? || hunk.merge(previous_hunk)

        output << "#{previous_hunk.diff(:unified)}\n" unless maybe_contiguous_hunks

        previous_hunk = hunk
      end
      output << "#{previous_hunk.diff(:unified, true)}\n" unless previous_hunk.nil?
      output.join
    end

    it "should not misplace the new chunk" do
      old_data = [
        "recipe[a::default]", "recipe[b::default]", "recipe[c::default]",
        "recipe[d::default]", "recipe[e::default]", "recipe[f::default]",
        "recipe[g::default]", "recipe[h::default]", "recipe[i::default]",
        "recipe[j::default]", "recipe[k::default]", "recipe[l::default]",
        "recipe[m::default]", "recipe[n::default]"
      ]

      new_data = [
        "recipe[a::default]", "recipe[c::default]", "recipe[d::default]",
        "recipe[e::default]", "recipe[f::default]", "recipe[g::default]",
        "recipe[h::default]", "recipe[i::default]", "recipe[j::default]",
        "recipe[k::default]", "recipe[l::default]", "recipe[m::default]",
        "recipe[n::default]", "recipe[o::new]", "recipe[p::new]",
        "recipe[q::new]", "recipe[r::new]"
      ]

      # standard:disable Layout/HeredocIndentation
      expect(diff_lines(old_data, new_data)).to eq(<<-EODIFF)
@@ -1,5 +1,4 @@
 recipe[a::default]
-recipe[b::default]
 recipe[c::default]
 recipe[d::default]
 recipe[e::default]
@@ -12,3 +11,7 @@
 recipe[l::default]
 recipe[m::default]
 recipe[n::default]
+recipe[o::new]
+recipe[p::new]
+recipe[q::new]
+recipe[r::new]
      EODIFF
      # standard:enable Layout/HeredocIndentation
    end
  end
end
