require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Runtime do
  subject(:runtime) { described_class.new }

  it 'preserves an already-inexact complex result produced by expt' do
    runtime.evaluate('(define z (expt -1 1/2))')
    expect(runtime.evaluate('(inexact z)')).to equal(runtime.evaluate('z'))
  end

  it 'converts both components of an exact complex number to inexact numbers' do
    runtime.define('complex-value', min: 0, max: 0) { Complex(Rational(1, 2), Rational(-3, 4)) }
    result = runtime.evaluate('(inexact (complex-value))')
    expect(result).to eq(Complex(0.5, -0.75))
    expect(result.real).to be_a(Float)
    expect(result.imaginary).to be_a(Float)
  end

  it 'preserves an already-inexact mixed-component complex argument' do
    value = Complex(Rational(1, 2), -0.75)
    runtime.define('complex-value', min: 0, max: 0) { value }
    expect(runtime.evaluate('(inexact (complex-value))')).to equal(value)
  end

  it 'converts both components of an inexact complex number to exact numbers' do
    runtime.define('complex-value', min: 0, max: 0) { Complex(0.5, -0.75) }
    result = runtime.evaluate('(exact (complex-value))')
    expect(result.real).to eq(Rational(1, 2))
    expect(result.imaginary).to eq(Rational(-3, 4))
    expect(Scheme::Numbers.exact?(result)).to be(true)
  end

  it 'preserves an already-exact complex number' do
    value = Complex(Rational(1, 2), -3)
    runtime.define('complex-value', min: 0, max: 0) { value }
    expect(runtime.evaluate('(exact (complex-value))')).to equal(value)
  end

  it 'supports converting an interpreter-created complex number back and forth' do
    source = '(let ((z (expt -1 1/2))) (list (exact? (exact z)) (inexact? (inexact (exact z))) (= z (inexact (exact z)))))'
    expect(Scheme.write(runtime.evaluate(source))).to eq('(#t #t #t)')
  end

  it 'preserves real conversions and normalizes exact integral results' do
    source = '(list (exact 0.5) (exact 2.0) (inexact 1/2) (inexact 2) (inexact -0.0) (inexact +inf.0))'
    expect(Scheme.write(runtime.evaluate(source))).to eq('(1/2 2 0.5 2.0 -0.0 +inf.0)')
  end

  it 'reports a catchable Scheme error for complex values with no exact representation' do
    runtime.define('complex-value', min: 0, max: 0) { Complex(1, Float::INFINITY) }
    expect(runtime.evaluate('(guard (e (else (error-object? e))) (exact (complex-value)))')).to be(true)
  end

  %w[exact inexact].each do |operation|
    it "rejects non-numeric arguments to #{operation}" do
      expect { runtime.evaluate("(#{operation} #t)") }.to raise_error(Scheme::Error)
    end
  end
end
