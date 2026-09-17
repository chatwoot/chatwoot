require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Reader do
  {
    '#t #false #true #f' => [true, false, true, false],
    '123 -12 +12 #xFF #b101 #o17 #d19' => [123, -12, 12, 255, 5, 15, 19],
    '1/3 #e1.25 #i3 .5 1e2' => [Rational(1, 3), Rational(5, 4), 3.0, 0.5, 100.0],
    '"hello\\nworld"' => ["hello\nworld"],
    "\"hello\nworld\"" => ["hello\nworld"],
    '"\\x3bb;"' => ['λ'],
    '#| outer #| inner |# comment |# 1 #; (+ 2 3) 4' => [1, 4],
    '#!fold-case HELLO #!no-fold-case World |Two Words|' => [:hello, :World, :'Two Words']
  }.each do |source, expected|
    it "reads #{source.inspect}" do
      expect(described_class.new(source).read_all).to eq(expected)
    end
  end

  it 'reads proper and dotted lists as pairs' do
    values = described_class.new('(a b) (a . b) (a . (b c))').read_all
    expect(values.map { |value| Scheme.write(value) }).to eq(['(a b)', '(a . b)', '(a b c)'])
  end

  it 'distinguishes characters, strings, vectors, and bytevectors' do
    values = described_class.new('#\\a "a" #(1 2) #u8(0 255)').read_all
    expect(values.map(&:class)).to eq([Scheme::Character, String, Scheme::Vector, Scheme::Bytevector])
  end

  it 'reads abbreviations without evaluating their contents' do
    expect(Scheme.write(described_class.new('`(a ,b ,@c)').read_all.first)).to eq('(quasiquote (a (unquote b) (unquote-splicing c)))')
  end

  ['(', '(a . b c)', '(. a)', ')', '"unfinished', '#u8(256)', '#\\unknown', '#| unfinished'].each do |source|
    it "reports a source location for invalid syntax #{source.inspect}" do
      expect { described_class.new(source).read_all }.to raise_error(Scheme::ReadError, /line \d+, column \d+/)
    end
  end

  {
    '; comment without a final newline' => [],
    '#; #; 1 2 3' => [3],
    '#e#x10 #x#i10 #i1/2' => [16, 16.0, 0.5],
    '1. 1.e2 -.5 2.5e-2' => [1.0, 100.0, -0.5, 0.025],
    '"a\\n  b"' => ["a\n  b"],
    "\"a\\ \n  b\"" => ['ab'],
    "\"a\\ \r\n  b\"" => ['ab'],
    '#!fold-case |MiXeD| HELLO' => [:MiXeD, :hello],
    '|a\\|b| |a\\x20;b|' => [:'a|b', :'a b']
  }.each do |source, expected|
    it "handles reader boundary #{source.inspect}" do
      expect(described_class.new(source).read_all).to eq(expected)
    end
  end

  [
    '#;', '#!unknown', '#e#e1', '#x#d1', '#b102', '#u8(1 . 2)', '#u8(-1)',
    '#\\', '#\\x110000', '"\\q"', '"\\x;"', '"\\xzz;"', '"\\x110000;"',
    '"a\\  b"', '(a .)', '(a . b . c)', '123abc', '|unfinished'
  ].each do |source|
    it "rejects malformed reader input #{source.inspect}" do
      expect { described_class.new(source).read_all }.to raise_error(Scheme::ReadError, /line \d+, column \d+/)
    end
  end

  it 'reports the line containing the invalid datum' do
    expect { described_class.new("1\n)").read_all }.to raise_error(Scheme::ReadError, /line 2, column 1/)
  end
end
