# frozen_string_literal: true

require 'spec_helper'

describe Hashdiff::LinearCompareArray do
  it 'finds no differences between two empty arrays' do
    difference = described_class.call([], [])
    difference.should == []
  end

  it 'finds added items when the old array is empty' do
    difference = described_class.call([], %i[a b])
    difference.should == [['+', '[0]', :a], ['+', '[1]', :b]]
  end

  it 'finds removed items when the new array is empty' do
    difference = described_class.call(%i[a b], [])
    difference.should == [['-', '[1]', :b], ['-', '[0]', :a]]
  end

  it 'finds no differences between identical arrays' do
    difference = described_class.call(%i[a b], %i[a b])
    difference.should == []
  end

  it 'finds added items in an array' do
    difference = described_class.call(%i[a d], %i[a b c d])
    difference.should == [['+', '[1]', :b], ['+', '[2]', :c]]
  end

  it 'finds removed items in an array' do
    difference = described_class.call(%i[a b c d e f], %i[a d f])
    difference.should == [['-', '[4]', :e], ['-', '[2]', :c], ['-', '[1]', :b]]
  end

  it 'shows additions and deletions as changed items' do
    difference = described_class.call(%i[a b c], %i[c b a])
    difference.should == [['~', '[0]', :a, :c], ['~', '[2]', :c, :a]]
  end

  it 'shows changed items in a hash' do
    difference = described_class.call([{ a: :b }], [{ a: :c }])
    difference.should == [['~', '[0].a', :b, :c]]
  end

  it 'shows changed items and added items' do
    difference = described_class.call([{ a: 1, b: 2 }], [{ a: 2, b: 2 }, :item])
    difference.should == [['~', '[0].a', 1, 2], ['+', '[1]', :item]]
  end
end
