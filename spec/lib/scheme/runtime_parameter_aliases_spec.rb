require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Runtime do
  subject(:runtime) { described_class.new(max_steps: 2_000) }

  before do
    runtime.evaluate('(define p (make-parameter 0)) (define q (make-parameter 100))')
  end

  ['((p 1) (p 2))', '((p 1) (p 2) (p 3))', '((p 1) (q 101) (p 2) (q 102))'].each do |bindings|
    it "restores the original values after duplicate bindings #{bindings}" do
      runtime.evaluate("(parameterize #{bindings} (list (p) (q)))")
      expect(Scheme.write(runtime.evaluate('(list (p) (q))'))).to eq('(0 100)')
    end
  end

  it 'handles aliases that resolve to the same parameter object' do
    runtime.evaluate('(define alias p)')
    runtime.evaluate('(parameterize ((p 1) (alias 2)) (p))')
    expect(runtime.evaluate('(p)')).to eq(0)
    expect(runtime.evaluate('(alias)')).to eq(0)
  end

  it 'restores nested duplicate bindings and changes made inside the body' do
    source = <<~SCHEME
      (parameterize ((p 1) (p 2))
        (let ((outer (p)))
          (parameterize ((p 3) (p 4)) (p 5))
          (= outer (p))))
    SCHEME
    expect(runtime.evaluate(source)).to be(true)
    expect(runtime.evaluate('(p)')).to eq(0)
  end

  it 'restores duplicate bindings when a continuation escapes' do
    expect(runtime.evaluate('(call/cc (lambda (exit) (parameterize ((p 1) (p 2)) (exit 42))))')).to eq(42)
    expect(runtime.evaluate('(p)')).to eq(0)
  end

  it 'restores duplicate bindings before evaluating an outer guard clause' do
    expect(runtime.evaluate('(guard (e (else (p))) (parameterize ((p 1) (p 2)) (raise 42)))')).to eq(0)
    expect(runtime.evaluate('(p)')).to eq(0)
  end

  {
    '(error "abort")' => Scheme::UncaughtError,
    '(let loop () (loop))' => Scheme::LimitError
  }.each do |expression, error|
    it "restores duplicate bindings after host abort #{expression}" do
      expect { runtime.evaluate("(parameterize ((p 1) (p 2)) #{expression})") }.to raise_error(error)
      expect(runtime.evaluate('(p)')).to eq(0)
    end
  end

  it 'preserves temporary values across repeated continuation reentry' do
    runtime.evaluate('(define saved #f)')
    source = '(parameterize ((p 1) (p 2)) (p 3) (call/cc (lambda (k) (set! saved k))) (p))'
    expect(runtime.evaluate(source)).to eq(3)
    expect(runtime.evaluate('(p)')).to eq(0)
    3.times do
      expect(runtime.evaluate('(saved #f)')).to eq(3)
      expect(runtime.evaluate('(p)')).to eq(0)
    end
  end

  it 'does not rerun converters when restoring or reentering duplicate bindings' do
    runtime.evaluate('(define calls 0) (define saved #f)')
    runtime.evaluate('(define r (make-parameter 0 (lambda (x) (set! calls (+ calls 1)) x)))')
    runtime.evaluate('(parameterize ((r 1) (r 2)) (call/cc (lambda (k) (set! saved k))) (r))')
    expect(runtime.evaluate('(r)')).to eq(0)
    runtime.evaluate('(saved #f)')
    expect(runtime.evaluate('(r)')).to eq(0)
    expect(runtime.evaluate('calls')).to eq(3)
  end

  it 'can reenter duplicate bindings captured before an abort' do
    runtime.evaluate('(define saved #f)')
    source = '(parameterize ((p 1) (p 2)) (p 3) (if (call/cc (lambda (k) (set! saved k) #t)) (error "abort") (p)))'
    expect { runtime.evaluate(source) }.to raise_error(Scheme::UncaughtError)
    expect(runtime.evaluate('(p)')).to eq(0)
    expect(runtime.evaluate('(saved #f)')).to eq(3)
    expect(runtime.evaluate('(p)')).to eq(0)
  end
end
