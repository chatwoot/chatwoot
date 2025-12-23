# frozen_string_literal: true

require 'spec_helper'

describe Hashdiff do
  it 'is able to best diff' do
    a = { 'x' => [{ 'a' => 1, 'c' => 3, 'e' => 5 }, { 'y' => 3 }] }
    b = { 'x' => [{ 'a' => 1, 'b' => 2, 'e' => 5 }] }

    diff = described_class.best_diff(a, b)
    diff.should == [['-', 'x[0].c', 3], ['+', 'x[0].b', 2], ['-', 'x[1]', { 'y' => 3 }]]
  end

  it 'uses custom delimiter when provided' do
    a = { 'x' => [{ 'a' => 1, 'c' => 3, 'e' => 5 }, { 'y' => 3 }] }
    b = { 'x' => [{ 'a' => 1, 'b' => 2, 'e' => 5 }] }

    diff = described_class.best_diff(a, b, delimiter: "\t")
    diff.should == [['-', "x[0]\tc", 3], ['+', "x[0]\tb", 2], ['-', 'x[1]', { 'y' => 3 }]]
  end

  it 'uses custom comparison when provided' do
    a = { 'x' => [{ 'a' => 'foo', 'c' => 'goat', 'e' => 'snake' }, { 'y' => 'baz' }] }
    b = { 'x' => [{ 'a' => 'bar', 'b' => 'cow', 'e' => 'puppy' }] }

    diff = described_class.best_diff(a, b) do |path, obj1, obj2|
      case path
      when /^x\[.\]\..$/
        obj1.length == obj2.length if obj1 && obj2
      end
    end

    diff.should == [['-', 'x[0].c', 'goat'], ['+', 'x[0].b', 'cow'], ['-', 'x[1]', { 'y' => 'baz' }]]
  end

  it 'is able to best diff array in hash' do
    a = { 'menu' => {
      'id' => 'file',
      'value' => 'File',
      'popup' => {
        'menuitem' => [
          { 'value' => 'New', 'onclick' => 'CreateNewDoc()' },
          { 'value' => 'Close', 'onclick' => 'CloseDoc()' }
        ]
      }
    } }

    b = { 'menu' => {
      'id' => 'file 2',
      'value' => 'File',
      'popup' => {
        'menuitem' => [
          { 'value' => 'New1', 'onclick' => 'CreateNewDoc()' },
          { 'value' => 'Open', 'onclick' => 'OpenDoc()' },
          { 'value' => 'Close', 'onclick' => 'CloseDoc()' }
        ]
      }
    } }

    diff = described_class.best_diff(a, b)
    diff.should == [
      ['~', 'menu.id', 'file', 'file 2'],
      ['~', 'menu.popup.menuitem[0].value', 'New', 'New1'],
      ['+', 'menu.popup.menuitem[1]', { 'value' => 'Open', 'onclick' => 'OpenDoc()' }]
    ]
  end

  it 'is able to have an array_path specified' do
    a = { 'x' => [{ 'a' => 1, 'c' => 3, 'e' => 5 }, { 'y' => 3 }] }
    b = { 'x' => [{ 'a' => 1, 'b' => 2, 'e' => 5 }] }

    diff = described_class.best_diff(a, b, array_path: true)
    diff.should == [['-', ['x', 0, 'c'], 3], ['+', ['x', 0, 'b'], 2], ['-', ['x', 1], { 'y' => 3 }]]
  end
end
