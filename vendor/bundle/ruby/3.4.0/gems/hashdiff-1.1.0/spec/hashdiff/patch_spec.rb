# frozen_string_literal: true

require 'spec_helper'

describe Hashdiff do
  it 'is able to patch key addition' do
    a = { 'a' => 3, 'c' => 11, 'd' => 45, 'e' => 100, 'f' => 200 }
    b = { 'a' => 3, 'c' => 11, 'd' => 45, 'e' => 100, 'f' => 200, 'g' => 300 }
    diff = described_class.diff(a, b)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 3, 'c' => 11, 'd' => 45, 'e' => 100, 'f' => 200 }
    b = { 'a' => 3, 'c' => 11, 'd' => 45, 'e' => 100, 'f' => 200, 'g' => 300 }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch value type changes' do
    a = { 'a' => 3 }
    b = { 'a' => { 'a1' => 1, 'a2' => 2 } }
    diff = described_class.diff(a, b)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 3 }
    b = { 'a' => { 'a1' => 1, 'a2' => 2 } }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch value array <=> []' do
    a = { 'a' => 1, 'b' => [1, 2] }
    b = { 'a' => 1, 'b' => [] }
    diff = described_class.diff(a, b)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 1, 'b' => [1, 2] }
    b = { 'a' => 1, 'b' => [] }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch value array <=> nil' do
    a = { 'a' => 1, 'b' => [1, 2] }
    b = { 'a' => 1, 'b' => nil }
    diff = described_class.diff(a, b)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 1, 'b' => [1, 2] }
    b = { 'a' => 1, 'b' => nil }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch array value removal' do
    a = { 'a' => 1, 'b' => [1, 2] }
    b = { 'a' => 1 }
    diff = described_class.diff(a, b)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 1, 'b' => [1, 2] }
    b = { 'a' => 1 }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch array under hash key with non-word characters' do
    a = { 'a' => 1, 'b-b' => [1, 2] }
    b = { 'a' => 1, 'b-b' => [2, 1] }
    diff = described_class.diff(a, b)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 1, 'b-b' => [1, 2] }
    b = { 'a' => 1, 'b-b' => [2, 1] }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch hash value removal' do
    a = { 'a' => 1, 'b' => { 'b1' => 1, 'b2' => 2 } }
    b = { 'a' => 1 }
    diff = described_class.diff(a, b)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 1, 'b' => { 'b1' => 1, 'b2' => 2 } }
    b = { 'a' => 1 }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch value hash <=> {}' do
    a = { 'a' => 1, 'b' => { 'b1' => 1, 'b2' => 2 } }
    b = { 'a' => 1, 'b' => {} }
    diff = described_class.diff(a, b)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 1, 'b' => { 'b1' => 1, 'b2' => 2 } }
    b = { 'a' => 1, 'b' => {} }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch value hash <=> nil' do
    a = { 'a' => 1, 'b' => { 'b1' => 1, 'b2' => 2 } }
    b = { 'a' => 1, 'b' => nil }
    diff = described_class.diff(a, b)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 1, 'b' => { 'b1' => 1, 'b2' => 2 } }
    b = { 'a' => 1, 'b' => nil }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch value nil removal' do
    a = { 'a' => 1, 'b' => nil }
    b = { 'a' => 1 }
    diff = described_class.diff(a, b)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 1, 'b' => nil }
    b = { 'a' => 1 }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch similar objects between arrays' do
    a = [{ 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5 }, 3]
    b = [1, { 'a' => 1, 'b' => 2, 'c' => 3, 'e' => 5 }]

    diff = described_class.diff(a, b)
    expect(described_class.patch!(a, diff)).to eq(b)

    a = [{ 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5 }, 3]
    b = [1, { 'a' => 1, 'b' => 2, 'c' => 3, 'e' => 5 }]
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch similar & equal objects between arrays' do
    a = [{ 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5 }, { 'x' => 5, 'y' => 6, 'z' => 3 }, 1]
    b = [1, { 'a' => 1, 'b' => 2, 'c' => 3, 'e' => 5 }]

    diff = described_class.diff(a, b)
    expect(described_class.patch!(a, diff)).to eq(b)

    a = [{ 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5 }, { 'x' => 5, 'y' => 6, 'z' => 3 }, 1]
    b = [1, { 'a' => 1, 'b' => 2, 'c' => 3, 'e' => 5 }]
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to patch hash value removal with custom delimiter' do
    a = { 'a' => 1, 'b' => { 'b1' => 1, 'b2' => 2 } }
    b = { 'a' => 1, 'b' => { 'b1' => 3 } }
    diff = described_class.diff(a, b, delimiter: "\n")

    expect(described_class.patch!(a, diff, delimiter: "\n")).to eq(b)

    a = { 'a' => 1, 'b' => { 'b1' => 1, 'b2' => 2 } }
    b = { 'a' => 1, 'b' => { 'b1' => 3 } }
    described_class.unpatch!(b, diff, delimiter: "\n").should == a
  end

  it 'is able to patch when the diff is generated with an array_path' do
    a = { 'a' => 1, 'b' => 1 }
    b = { 'a' => 1, 'b' => 2 }
    diff = described_class.diff(a, b, array_path: true)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 1, 'b' => 1 }
    b = { 'a' => 1, 'b' => 2 }
    described_class.unpatch!(b, diff).should == a
  end

  it 'is able to use non string keys when diff is generated with an array_path' do
    a = { 'a' => 1, :a => 2, 0 => 3 }
    b = { 'a' => 5, :a => 6, 0 => 7 }
    diff = described_class.diff(a, b, array_path: true)

    expect(described_class.patch!(a, diff)).to eq(b)

    a = { 'a' => 1, :a => 2, 0 => 3 }
    b = { 'a' => 5, :a => 6, 0 => 7 }
    described_class.unpatch!(b, diff).should == a
  end
end
