# frozen_string_literal: true

require "spec_helper"

describe "Diff::LCS.traverse_balanced" do
  include Diff::LCS::SpecHelper::Matchers

  shared_examples "with a #change callback" do |s1, s2, result|
    it "traverses s1 -> s2 correctly" do
      traversal = balanced_traversal(s1, s2, :balanced_callback)
      expect(traversal.result).to eq(result)
    end

    it "traverses s2 -> s1 correctly" do
      traversal = balanced_traversal(s2, s1, :balanced_callback)
      expect(traversal.result).to eq(balanced_reverse(result))
    end
  end

  shared_examples "without a #change callback" do |s1, s2, result|
    it "traverses s1 -> s2 correctly" do
      traversal = balanced_traversal(s1, s2, :balanced_callback_no_change)
      expect(traversal.result).to eq(map_to_no_change(result))
    end

    it "traverses s2 -> s1 correctly" do
      traversal = balanced_traversal(s2, s1, :balanced_callback_no_change)
      expect(traversal.result).to eq(map_to_no_change(balanced_reverse(result)))
    end
  end

  describe "identical string sequences ('abc')" do
    s1 = s2 = "abc"

    result = [
      ["=", 0, 0],
      ["=", 1, 1],
      ["=", 2, 2]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "identical array sequences %w(a b c)" do
    s1 = s2 = %w[a b c]

    result = [
      ["=", 0, 0],
      ["=", 1, 1],
      ["=", 2, 2]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "sequences %w(a b c) & %w(a x c)" do
    s1 = %w[a b c]
    s2 = %w[a x c]

    result = [
      ["=", 0, 0],
      ["!", 1, 1],
      ["=", 2, 2]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "sequences %w(a x y c) & %w(a v w c)" do
    s1 = %w[a x y c]
    s2 = %w[a v w c]

    result = [
      ["=", 0, 0],
      ["!", 1, 1],
      ["!", 2, 2],
      ["=", 3, 3]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "sequences %w(x y c) & %w(v w c)" do
    s1 = %w[x y c]
    s2 = %w[v w c]
    result = [
      ["!", 0, 0],
      ["!", 1, 1],
      ["=", 2, 2]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "sequences %w(a x y z) & %w(b v w)" do
    s1 = %w[a x y z]
    s2 = %w[b v w]
    result = [
      ["!", 0, 0],
      ["!", 1, 1],
      ["!", 2, 2],
      ["<", 3, 3]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "sequences %w(a z) & %w(a)" do
    s1 = %w[a z]
    s2 = %w[a]
    result = [
      ["=", 0, 0],
      ["<", 1, 1]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "sequences %w(z a) & %w(a)" do
    s1 = %w[z a]
    s2 = %w[a]
    result = [
      ["<", 0, 0],
      ["=", 1, 0]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "sequences %w(a b c) & %w(x y z)" do
    s1 = %w[a b c]
    s2 = %w[x y z]
    result = [
      ["!", 0, 0],
      ["!", 1, 1],
      ["!", 2, 2]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "sequences %w(abcd efgh ijkl mnoopqrstuvwxyz) & []" do
    s1 = %w[abcd efgh ijkl mnopqrstuvwxyz]
    s2 = []
    result = [
      ["<", 0, 0],
      ["<", 1, 0],
      ["<", 2, 0],
      ["<", 3, 0]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "strings %q(a b c) & %q(a x c)" do
    s1 = "a b c"
    s2 = "a x c"

    result = [
      ["=", 0, 0],
      ["=", 1, 1],
      ["!", 2, 2],
      ["=", 3, 3],
      ["=", 4, 4]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "strings %q(a x y c) & %q(a v w c)" do
    s1 = "a x y c"
    s2 = "a v w c"

    result = [
      ["=", 0, 0],
      ["=", 1, 1],
      ["!", 2, 2],
      ["=", 3, 3],
      ["!", 4, 4],
      ["=", 5, 5],
      ["=", 6, 6]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "strings %q(x y c) & %q(v w c)" do
    s1 = "x y c"
    s2 = "v w c"
    result = [
      ["!", 0, 0],
      ["=", 1, 1],
      ["!", 2, 2],
      ["=", 3, 3],
      ["=", 4, 4]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "strings %q(a x y z) & %q(b v w)" do
    s1 = "a x y z"
    s2 = "b v w"
    result = [
      ["!", 0, 0],
      ["=", 1, 1],
      ["!", 2, 2],
      ["=", 3, 3],
      ["!", 4, 4],
      ["<", 5, 5],
      ["<", 6, 5]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "strings %q(a z) & %q(a)" do
    s1 = "a z"
    s2 = "a"
    result = [
      ["=", 0, 0],
      ["<", 1, 1],
      ["<", 2, 1]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "strings %q(z a) & %q(a)" do
    s1 = "z a"
    s2 = "a"
    result = [
      ["<", 0, 0],
      ["<", 1, 0],
      ["=", 2, 0]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "strings %q(a b c) & %q(x y z)" do
    s1 = "a b c"
    s2 = "x y z"
    result = [
      ["!", 0, 0],
      ["=", 1, 1],
      ["!", 2, 2],
      ["=", 3, 3],
      ["!", 4, 4]
    ]

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end

  describe "strings %q(abcd efgh ijkl mnopqrstuvwxyz) & %q()" do
    s1 = "abcd efgh ijkl mnopqrstuvwxyz"
    s2 = ""
    # standard:disable Layout/ExtraSpacing
    result = [
      ["<",  0, 0],
      ["<",  1, 0],
      ["<",  2, 0],
      ["<",  3, 0],
      ["<",  4, 0],
      ["<",  5, 0],
      ["<",  6, 0],
      ["<",  7, 0],
      ["<",  8, 0],
      ["<",  9, 0],
      ["<", 10, 0],
      ["<", 11, 0],
      ["<", 12, 0],
      ["<", 13, 0],
      ["<", 14, 0],
      ["<", 15, 0],
      ["<", 16, 0],
      ["<", 17, 0],
      ["<", 18, 0],
      ["<", 19, 0],
      ["<", 20, 0],
      ["<", 21, 0],
      ["<", 22, 0],
      ["<", 23, 0],
      ["<", 24, 0],
      ["<", 25, 0],
      ["<", 26, 0],
      ["<", 27, 0],
      ["<", 28, 0]
    ]
    # standard:enable Layout/ExtraSpacing

    it_has_behavior "with a #change callback", s1, s2, result
    it_has_behavior "without a #change callback", s1, s2, result
  end
end
