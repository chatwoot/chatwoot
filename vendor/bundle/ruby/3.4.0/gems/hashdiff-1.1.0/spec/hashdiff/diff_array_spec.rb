# frozen_string_literal: true

require 'spec_helper'

describe Hashdiff do
  it 'is able to diff two equal array' do
    a = [1, 2, 3]
    b = [1, 2, 3]

    diff = described_class.diff_array_lcs(a, b)
    diff.should == []
  end

  it 'is able to diff two arrays with one element in common' do
    a = [1, 2, 3]
    b = [1, 8, 7]

    diff = described_class.diff_array_lcs(a, b)
    diff.should == [['-', 2, 3], ['-', 1, 2], ['+', 1, 8], ['+', 2, 7]]
  end

  it 'is able to diff two arrays with nothing in common' do
    a = [1, 2]
    b = []

    diff = described_class.diff_array_lcs(a, b)
    diff.should == [['-', 1, 2], ['-', 0, 1]]
  end

  it 'is able to diff an empty array with an non-empty array' do
    a = []
    b = [1, 2]

    diff = described_class.diff_array_lcs(a, b)
    diff.should == [['+', 0, 1], ['+', 1, 2]]
  end

  it 'is able to diff two arrays with two elements in common' do
    a = [1, 3, 5, 7]
    b = [2, 3, 7, 5]

    diff = described_class.diff_array_lcs(a, b)
    diff.should == [['-', 0, 1], ['+', 0, 2], ['+', 2, 7], ['-', 4, 7]]
  end

  it 'is able to test two arrays with two common elements in different order' do
    a = [1, 3, 4, 7]
    b = [2, 3, 7, 5]

    diff = described_class.diff_array_lcs(a, b)
    diff.should == [['-', 0, 1], ['+', 0, 2], ['-', 2, 4], ['+', 3, 5]]
  end

  it 'is able to diff two arrays with similar elements' do
    a = [{ 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5 }, 3]
    b = [1, { 'a' => 1, 'b' => 2, 'c' => 3, 'e' => 5 }]
    diff = described_class.diff_array_lcs(a, b)
    diff.should == [['+', 0, 1], ['-', 2, 3]]
  end
end
