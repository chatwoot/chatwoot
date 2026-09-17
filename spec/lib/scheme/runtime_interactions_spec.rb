require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Runtime do
  subject(:runtime) { described_class.new(max_steps: 200_000) }

  it 'unwinds nested dynamic extents in reverse order when a continuation escapes' do
    source = <<~SCHEME
      (define log '())
      (define (record x) (set! log (cons x log)))
      (call/cc (lambda (exit)
        (dynamic-wind
          (lambda () (record 'outer-in))
          (lambda () (dynamic-wind
            (lambda () (record 'inner-in))
            (lambda () (exit 42))
            (lambda () (record 'inner-out))))
          (lambda () (record 'outer-out)))))
      (reverse log)
    SCHEME
    expect(Scheme.write(runtime.evaluate(source))).to eq('(outer-in inner-in inner-out outer-out)')
  end

  it 'does not reenter a shared dynamic extent when invoking a continuation within it' do
    source = <<~SCHEME
      (define log '())
      (dynamic-wind
        (lambda () (set! log (cons 'in log)))
        (lambda () (call/cc (lambda (k) (k 1))))
        (lambda () (set! log (cons 'out log))))
      (reverse log)
    SCHEME
    expect(Scheme.write(runtime.evaluate(source))).to eq('(in out)')
  end

  it 'preserves partial map results when a captured callback is resumed more than once' do
    runtime.evaluate('(define saved #f)')
    result = runtime.evaluate('(map (lambda (x) (if (= x 2) (call/cc (lambda (k) (set! saved k) x)) x)) (list 1 2 3))')
    expect(Scheme.write(result)).to eq('(1 2 3)')
    expect(Scheme.write(runtime.evaluate('(saved 20)'))).to eq('(1 20 3)')
    expect(Scheme.write(runtime.evaluate('(saved 30)'))).to eq('(1 30 3)')
  end

  it 'does not rerun parameter converters on continuation reentry' do
    runtime.evaluate('(define conversions 0) (define saved #f)')
    runtime.evaluate('(define p (make-parameter 1 (lambda (x) (set! conversions (+ conversions 1)) x)))')
    runtime.evaluate('(parameterize ((p 2)) (call/cc (lambda (k) (set! saved k))) (p))')
    expect(runtime.evaluate('(saved 0)')).to eq(2)
    expect(runtime.evaluate('(p)')).to eq(1)
    expect(runtime.evaluate('conversions')).to eq(2)
  end

  it 'runs guard clauses outside the protected dynamic extent' do
    source = <<~SCHEME
      (define p (make-parameter 1))
      (guard (e (else (list e (p))))
        (parameterize ((p 2)) (raise 'problem)))
    SCHEME
    expect(Scheme.write(runtime.evaluate(source))).to eq('(problem 1)')
    expect(runtime.evaluate('(p)')).to eq(1)
  end

  it 'propagates an unmatched guard to the outer handler' do
    source = '(guard (outer (else outer)) (guard (inner ((number? inner) 0)) (raise (quote problem))))'
    expect(runtime.evaluate(source)).to eq(:problem)
  end

  it 'resumes the original raise-continuable when an unmatched guard is handled outside' do
    source = <<~SCHEME
      (with-exception-handler
        (lambda (e) 10)
        (lambda () (guard (e ((number? e) 0)) (+ 1 (raise-continuable 'problem)))))
    SCHEME
    expect(runtime.evaluate(source)).to eq(11)
  end

  it 'delivers errors raised by a handler to the enclosing handler' do
    source = '(guard (outer (else outer)) (with-exception-handler (lambda (e) (raise 7)) (lambda () (raise 1))))'
    expect(runtime.evaluate(source)).to eq(7)
  end

  it 'signals an error if a non-continuable handler returns' do
    source = '(guard (e (else (error-object? e))) (with-exception-handler (lambda (e) 1) (lambda () (raise 2))))'
    expect(runtime.evaluate(source)).to be(true)
  end

  it 'retains the handler for successive continuable exceptions' do
    source = '(with-exception-handler (lambda (e) (+ e 1)) (lambda () (list (raise-continuable 1) (raise-continuable 2))))'
    expect(Scheme.write(runtime.evaluate(source))).to eq('(2 3)')
  end

  it 'memoizes a promise even if its computation recursively forces itself' do
    source = <<~SCHEME
      (define count 0)
      (define p (delay (begin
        (set! count (+ count 1))
        (if (> count 5) count (force p)))))
      (list (force p) (force p) count)
    SCHEME
    expect(Scheme.write(runtime.evaluate(source))).to eq('(6 6 6)')
  end

  it 'preserves sharing between lazy promises' do
    source = <<~SCHEME
      (define count 0)
      (define p (delay (begin (set! count (+ count 1)) count)))
      (define q (delay-force p))
      (list (force q) (force p) count)
    SCHEME
    expect(Scheme.write(runtime.evaluate(source))).to eq('(1 1 1)')
  end

  it 'can retry a promise whose evaluation raised a handled exception' do
    runtime.evaluate('(define ready #f) (define p (delay (if ready 42 (error "not ready"))))')
    expect(runtime.evaluate('(guard (e (else 0)) (force p))')).to eq(0)
    runtime.evaluate('(set! ready #t)')
    expect(runtime.evaluate('(force p)')).to eq(42)
  end

  it 'keeps separately defined record types distinct' do
    runtime.evaluate('(define-record-type a (make-a x) a? (x a-x set-a-x!))')
    runtime.evaluate('(define-record-type b (make-b x) b? (x b-x))')
    expect(runtime.evaluate('(a? (make-b 1))')).to be(false)
    expect { runtime.evaluate('(a-x (make-b 1))') }.to raise_error(Scheme::Error, /record/)
    expect { runtime.evaluate('(set-a-x! (make-b 1) 2)') }.to raise_error(Scheme::Error, /record/)
  end

  it 'rejects continuations captured by a different runtime' do
    other = described_class.new
    captured = other.evaluate('(call/cc (lambda (k) k))')
    runtime.define('foreign-continuation', min: 0, max: 0) { captured }

    expect { runtime.evaluate('((foreign-continuation) 1)') }.to raise_error(Scheme::Error, /another runtime/)
  end

  [
    '(force (delay-force 1))', '(parameterize ((1 2)) 3)', '((make-parameter 1) 2 3)',
    '((case-lambda ((x) x)))', '(guard (1 (else 2)) 3)',
    '(define-record-type a (make-a x) a? (x a-x) (x other-x))',
    '(define-record-type a (make-a y) a? (x a-x))',
    '(define-record-type a (make-a x) a? (x 1))'
  ].each do |source|
    it "rejects invalid control contracts: #{source}" do
      expect { runtime.evaluate(source) }.to raise_error(Scheme::Error)
    end
  end
end
