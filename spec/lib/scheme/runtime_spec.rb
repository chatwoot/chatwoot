require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Runtime do
  subject(:runtime) { described_class.new }

  {
    '(+)' => 0,
    '(*)' => 1,
    '(+ 1 2 3 4)' => 10,
    '(- 4)' => -4,
    '(- 10 2 3)' => 5,
    '(/ 5 2)' => Rational(5, 2),
    '(/ 2)' => Rational(1, 2),
    '(/ 12 2 3)' => 2,
    '(< 1 2 3)' => true,
    '(= 1 1.0)' => true,
    '(eqv? 1 1.0)' => false,
    '(if (quote ()) 1 2)' => 1,
    '(if #f 1)' => Scheme::UNSPECIFIED,
    '(and)' => true,
    '(or)' => false,
    '(and 1 2)' => 2,
    '(or #f 3)' => 3,
    '((lambda args (length args)) 1 2 3)' => 3,
    '((lambda (x . rest) (+ x (length rest))) 10 20 30)' => 12,
    '(let ((x 2)) (let ((x 3) (y x)) (+ x y)))' => 5,
    '(let* ((x 2) (x (+ x 1))) x)' => 3,
    '(letrec ((even? (lambda (n) (if (= n 0) #t (odd? (- n 1))))) (odd? (lambda (n) (if (= n 0) #f (even? (- n 1)))))) (even? 1000))' => true,
    '(letrec* ((x 1) (y (+ x 1))) y)' => 2,
    '(let ((x 10)) ((lambda () (define x 1) (define y x) y)))' => 1,
    '(cond ((member 2 (quote (1 2 3))) => car) (else 0))' => 2,
    '(case (* 2 3) ((2 3 5 7) (quote prime)) ((1 4 6 8 9) (quote composite)))' => :composite,
    '(let ((x 0)) (when #t (set! x 5)) (unless #f (set! x (+ x 2))) x)' => 7,
    '(do ((i 0 (+ i 1)) (total 0 (+ total i))) ((= i 10) total))' => 45,
    '(call-with-values (lambda () (values 4 5)) +)' => 9,
    '(let-values (((x y) (values 2 3))) (* x y))' => 6,
    '(let*-values (((x) 2) ((y) (+ x 3))) (* x y))' => 10,
    '(begin (define-values (x y) (values 2 3)) (+ x y))' => 5,
    '(let ((if +)) (if 1 2 3))' => 6
  }.each do |source, expected|
    it "evaluates #{source}" do
      expect(runtime.evaluate(source)).to eq(expected)
    end
  end

  it 'keeps lexical state between calls' do
    runtime.evaluate('(define counter (let ((n 0)) (lambda () (set! n (+ n 1)) n)))')
    expect(runtime.evaluate('(counter)')).to eq(1)
    expect(runtime.evaluate('(counter)')).to eq(2)
  end

  it 'supports tail calls through apply without consuming the Ruby stack' do
    expect(runtime.evaluate('(let loop ((n 10000)) (if (= n 0) n (apply loop (list (- n 1)))))')).to eq(0)
  end

  it 'does not let an internal definition read an outer binding of the same name before initialization' do
    expect { runtime.evaluate('(let ((x 10)) ((lambda () (define x x) x)))') }.to raise_error(Scheme::Error, /initializ/)
  end

  ['(car)', '(car (list 1) 2)', '((lambda (x) x) 1 2)', '(+ 1 "2")', '(if #t)', '(set! missing 1)'].each do |source|
    it "rejects invalid calls without silently discarding arguments: #{source}" do
      expect { runtime.evaluate(source) }.to raise_error(Scheme::Error)
    end
  end

  it 'provides an explicit Ruby extension boundary with checked arity' do
    runtime.define('double', min: 1, max: 1) { |value| value * 2 }
    expect(runtime.evaluate('(double 4)')).to eq(8)
    expect { runtime.evaluate('(double 4 5)') }.to raise_error(Scheme::Error, /argument/)
  end

  it 'enforces a shared evaluation budget during recursion' do
    bounded = described_class.new(max_steps: 200)
    expect { bounded.evaluate('(let loop () (loop))') }.to raise_error(Scheme::LimitError)
    expect(bounded.evaluate('(+ 1 2)')).to eq(3)
  end
end
