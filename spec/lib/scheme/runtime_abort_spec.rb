require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Runtime do
  subject(:runtime) { described_class.new(max_steps: 2_000) }

  before do
    runtime.evaluate('(define p (make-parameter 1)) (define q (make-parameter 2))')
  end

  {
    '(car 1)' => Scheme::Error,
    '(error "aborted")' => Scheme::UncaughtError,
    '(raise (quote aborted))' => Scheme::UncaughtError,
    '(let loop () (loop))' => Scheme::LimitError
  }.each do |expression, error|
    it "restores dynamic parameters after #{expression}" do
      expect { runtime.evaluate("(parameterize ((p 10) (q 20)) #{expression})") }.to raise_error(error)
      expect(Scheme.write(runtime.evaluate('(list (p) (q))'))).to eq('(1 2)')
      expect(runtime.evaluate('(+ 1 2)')).to eq(3)
    end
  end

  it 'restores nested extents from innermost to outermost' do
    source = '(parameterize ((p 10)) (parameterize ((p 20) (q 30)) (p 40) (error "abort")))'
    expect { runtime.evaluate(source) }.to raise_error(Scheme::UncaughtError, 'abort')
    expect(Scheme.write(runtime.evaluate('(list (p) (q))'))).to eq('(1 2)')
  end

  it 'restores parameters even when a Ruby extension raises a host exception' do
    runtime.define('host-failure', min: 0, max: 0) { raise IOError, 'connection closed' }
    expect { runtime.evaluate('(parameterize ((p 10)) (host-failure))') }.to raise_error(IOError, 'connection closed')
    expect(runtime.evaluate('(p)')).to eq(1)
  end

  it 'does not run parameter converters during abort cleanup' do
    runtime.evaluate('(define conversions 0) (define r (make-parameter 1 (lambda (x) (set! conversions (+ conversions 1)) x)))')
    expect { runtime.evaluate('(parameterize ((r 10)) (error "abort"))') }.to raise_error(Scheme::UncaughtError)
    expect(runtime.evaluate('(r)')).to eq(1)
    expect(runtime.evaluate('conversions')).to eq(2)
  end

  it 'does not give arbitrary Scheme cleanup code a fresh budget after a host abort' do
    runtime.evaluate('(define cleanup-ran #f)')
    source = <<~SCHEME
      (parameterize ((p 10))
        (dynamic-wind
          (lambda () #t)
          (lambda () (let loop () (loop)))
          (lambda () (set! cleanup-ran #t) (let loop () (loop)))))
    SCHEME
    expect { runtime.evaluate(source) }.to raise_error(Scheme::LimitError)
    expect(runtime.evaluate('(p)')).to eq(1)
    expect(runtime.evaluate('cleanup-ran')).to be(false)
  end

  it 'can reenter a captured extent after its original evaluation aborted' do
    runtime.evaluate('(define saved #f)')
    source = '(parameterize ((p 10)) (if (call/cc (lambda (k) (set! saved k) #t)) (error "abort") (p)))'
    expect { runtime.evaluate(source) }.to raise_error(Scheme::UncaughtError)
    expect(runtime.evaluate('(p)')).to eq(1)
    expect(runtime.evaluate('(saved #f)')).to eq(10)
    expect(runtime.evaluate('(p)')).to eq(1)
    expect(runtime.evaluate('(saved #f)')).to eq(10)
    expect(runtime.evaluate('(p)')).to eq(1)
  end

  it 'does not restore away intentional changes outside a dynamic binding' do
    expect { runtime.evaluate('(p 5) (error "abort")') }.to raise_error(Scheme::UncaughtError)
    expect(runtime.evaluate('(p)')).to eq(5)
  end
end
