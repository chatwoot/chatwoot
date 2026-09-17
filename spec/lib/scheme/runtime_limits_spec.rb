require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Runtime do
  it 'shares the evaluation budget with collection callbacks' do
    runtime = described_class.new(max_steps: 500)
    expect { runtime.evaluate('(map (lambda (x) (let loop () (loop))) (list 1))') }.to raise_error(Scheme::LimitError)
    expect(runtime.evaluate('(+ 1 2)')).to eq(3)
  end

  it 'does not allow Scheme handlers to bypass the host step limit' do
    runtime = described_class.new(max_steps: 500)
    expect { runtime.evaluate('(guard (e (else 42)) (let loop () (loop)))') }.to raise_error(Scheme::LimitError)
  end

  it 'bounds reader nesting with a Scheme error rather than a Ruby stack overflow' do
    source = "#{'(' * 600}1#{')' * 600}"
    expect { Scheme::Reader.new(source).read_all }.to raise_error(Scheme::ReadError, /nesting limit/)
  end

  it 'includes discarded datums in the reader nesting limit' do
    source = "#{'(#; ' * 600}0#{')' * 600}"
    expect { Scheme::Reader.new(source).read_all }.to raise_error(Scheme::ReadError, /nesting limit/)
  end

  it 'can process moderately sized allocated collections' do
    runtime = described_class.new
    source = '(list (length (make-list 10000 1)) (vector-length (make-vector 10000)) (string-length (make-string 10000)))'
    expect(Scheme.write(runtime.evaluate(source))).to eq('(10000 10000 10000)')
  end

  it 'resolves procedures through many sequential lexical bindings without overflowing the Ruby stack' do
    bindings = Array.new(15_000) { |index| "(x#{index} #{index})" }.join(' ')
    expect(described_class.new.evaluate("(let* (#{bindings}) (+ 1 2))")).to eq(3)
  end

  it 'can quote and compare long flat lists without consuming the Ruby stack' do
    runtime = described_class.new
    source = "(length '(#{Array.new(10_000, '1').join(' ')}))"
    expect(runtime.evaluate(source)).to eq(10_000)
    expect(runtime.evaluate('(equal? (make-list 10000 1) (make-list 10000 1))')).to be(true)
  end

  %w[length reverse list-copy].each do |operation|
    it "rejects cyclic input to #{operation} without looping" do
      runtime = described_class.new
      source = "(let ((xs (list 1))) (set-cdr! xs xs) (#{operation} xs))"
      expect { runtime.evaluate(source) }.to raise_error(Scheme::Error, /cyclic/)
    end
  end
end
