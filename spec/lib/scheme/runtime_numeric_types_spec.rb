require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Runtime do
  subject(:runtime) { described_class.new }

  # R7RS-small 6.2.6 distinguishes real arguments (x) from complex arguments (z).
  # https://standards.scheme.org/r7rs-html5/index.html
  invalid_values = ['#t', '"wrong"', '#(1)']
  %w[positive? negative? abs floor ceiling truncate round numerator denominator min max].each do |operation|
    it "rejects non-real values in #{operation} as a catchable Scheme error" do
      source = "(#{operation} (expt -1 1/2))"
      expect { runtime.evaluate(source) }.to raise_error(Scheme::Error, /real number/)
      expect(runtime.evaluate("(guard (e (else (error-object? e))) #{source})")).to be(true)
    end

    invalid_values.each do |value|
      it "rejects #{value} in #{operation} without leaking a Ruby exception" do
        expect { runtime.evaluate("(#{operation} #{value})") }.to raise_error(Scheme::Error)
      end
    end
  end

  invalid_operands = ['(expt -1 1/2) 1', '1 (expt -1 1/2)', '3 2 (expt -1 1/2)']
  %w[< > <= >= min max].each do |operation|
    invalid_operands.each do |arguments|
      it "validates every real operand in (#{operation} #{arguments}) before comparing" do
        source = "(#{operation} #{arguments})"
        expect { runtime.evaluate(source) }.to raise_error(Scheme::Error, /real number/)
        expect(runtime.evaluate("(guard (e (else (error-object? e))) #{source})")).to be(true)
      end
    end
  end

  {
    '(list (positive? 1/2) (negative? -2.5) (abs -7/3))' => '(#t #t 7/3)',
    '(list (floor 7/3) (ceiling -7/3) (truncate -2.5) (round 2.5))' => '(2 -2 -2.0 2.0)',
    '(list (< 1 2.5 3) (> 3 2.5 1) (<= 1 1.0) (>= 2.0 2))' => '(#t #t #t #t)',
    '(list (min 2 1/2) (max 2 1/2) (min 2 1.0) (max 2.0 1))' => '(1/2 2 1.0 2.0)',
    '(let ((z (expt -1 1/2))) (list (= z z) (zero? z) (= (+ z 1) (+ 1 z)) (= (* z 2) (+ z z))))' => '(#t #f #t #t)',
    '(list (positive? +inf.0) (negative? -inf.0) (< -inf.0 1 +inf.0))' => '(#t #t #t)',
    '(list (positive? +nan.0) (negative? +nan.0) (< +nan.0 1) (= +nan.0 +nan.0))' => '(#f #f #f #f)'
  }.each do |source, expected|
    it "preserves valid numeric behavior for #{source}" do
      expect(Scheme.write(runtime.evaluate(source))).to eq(expected)
    end
  end

  it 'accepts a complex representation with zero imaginary part in real operations' do
    runtime.define('real-complex', min: 0, max: 0) { Complex(Rational(7, 2), 0) }
    source = '(list (positive? (real-complex)) (< (real-complex) 4) (floor (real-complex)) (min (real-complex) 4))'
    expect(Scheme.write(runtime.evaluate(source))).to eq('(#t #t 3 7/2)')
  end

  it 'does not hide programming errors raised by host extension code' do
    runtime.define('broken-extension', min: 0, max: 0) { Object.new.nonexistent_operation }
    expect { runtime.evaluate('(guard (e (else 42)) (broken-extension))') }.to raise_error(NoMethodError, /nonexistent_operation/)
  end
end
