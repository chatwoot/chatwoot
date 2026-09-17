require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Runtime do
  subject(:runtime) { described_class.new }

  {
    '(and #f (error "unreachable"))' => '#f',
    '(or 0 (error "unreachable"))' => '0',
    '(if "" 1 2)' => '1',
    '(cond ((= 1 2) 0) ((+ 2 3)))' => '5',
    '(cond (#f 0) (else 9))' => '9',
    '(case 2 ((1) 0) ((2) => (lambda (x) (+ x 1))))' => '3',
    '(case 3 ((1) 0) (else => (lambda (x) (+ x 1))))' => '4',
    '(let ((x 1)) (let-values (((x) 2) ((y) x)) (list x y)))' => '(2 1)',
    '(let*-values (((x) 1) ((x) (+ x 1))) x)' => '2',
    '(let-values (((x . rest) (values 1 2 3))) (list x rest))' => '(1 (2 3))',
    '(let-values ((rest (values 1 2))) rest)' => '(1 2)',
    '(let-values ((() (values))) 5)' => '5',
    '(call-with-values (lambda () (values)) list)' => '()',
    '(call-with-values (lambda () (and #t (values 1 2))) list)' => '(1 2)',
    '(begin (define-values (x . rest) (values 1 2 3)) (list x rest))' => '(1 (2 3))',
    '(let ((f 9)) (let f ((x f)) x))' => '9',
    '(let ((x 1)) (let ((f (lambda () x))) (let ((x 2)) (f))))' => '1',
    '(let ((x 1)) (let ((f (lambda () x))) (set! x 3) (f)))' => '3',
    '(let ((x 0)) (unless #t (set! x 1)) (when #f (set! x 2)) x)' => '0',
    '(do ((x 1 y) (y 2 x) (n 0 (+ n 1))) ((= n 1) (list x y)))' => '(2 1)',
    '(do ((x 7) (n 0 (+ n 1))) ((= n 2) x))' => '7',
    '`#(1 ,(+ 1 1) ,@(list 3 4))' => '#(1 2 3 4)',
    '(let ((x 3)) `(a `(b ,x) ,x))' => '(a (quasiquote (b (unquote x))) 3)',
    '(list (+ 2) (* 2) (/ 3 2) (/ 4 2) (/ 4.0 2))' => '(2 2 3/2 2 2.0)',
    '(list (min 2 1.0 3) (max 2 1.0 3))' => '(1.0 3.0)',
    '(list (floor -7/3) (ceiling -7/3) (truncate -7/3) (round -5/2) (round 7/2))' => '(-3 -2 -2 -2 4)',
    '(call-with-values (lambda () (floor/ -5 2)) list)' => '(-3 1)',
    '(call-with-values (lambda () (truncate/ -5.0 2)) list)' => '(-2.0 -1.0)',
    '(list (floor-quotient 5 -2) (floor-remainder 5 -2) (truncate-quotient 5 -2) (truncate-remainder 5 -2))' => '(-3 -1 -2 1)',
    '(list (gcd) (lcm) (gcd -12 18.0) (lcm -4 6))' => '(0 1 6.0 12)',
    '(list (numerator 0.5) (denominator 0.5) (abs -1/2) (square 3) (expt 2 -2))' => '(1.0 2.0 1/2 9 1/4)',
    '(list (number? "1") (rational? +inf.0) (integer? 2.5) (exact-integer? 2.0) (odd? -3.0) (even? 4))' => '(#f #f #f #f #t #t)',
    '(list (real? 1/2) (complex? 1) (zero? 0.0) (positive? -1) (negative? -1))' => '(#t #t #t #f #t)',
    '(list (boolean=? #t #t) (boolean=? #t #f) (symbol=? (quote a) (quote a)))' => '(#t #f #t)',
    '(list (string->number "#e#x10") (string->number "#x#i10") (string->number "-10" 2))' => '(16 16.0 -2)',
    '(list (string->number "#e#i1") (string->number "#x#d1") (string->number "1/0") (string->number "#e+inf.0"))' => '(#f #f #f #f)',
    '(list (number->string -10 2) (number->string 3/2) (inexact 1/2))' => '("-1010" "3/2" 0.5)',
    '(list (equal? (vector (list 1) "x") (vector (list 1) "x")) (equal? #(1) #(1 2)) (equal? #u8(1) #(1)))' => '(#t #f #f)',
    '(let ((x (list 1)) (y (list 1))) (set-cdr! x x) (set-cdr! y y) (equal? x y))' => '#t',
    '(let ((x (list 1)) (y (list 2))) (set-cdr! x x) (set-cdr! y y) (equal? x y))' => '#f'
  }.each do |source, expected|
    it "evaluates #{source}" do
      expect(Scheme.write(runtime.evaluate(source))).to eq(expected)
    end
  end

  [
    '(lambda (x x) x)', '(lambda (x . x) x)', '(lambda (1) 1)', '(lambda (x))',
    '(let ((x 1) (x 2)) x)', '(let ((1 2)) 1)', '(letrec ((x x)) x)',
    '(let-values (((x) 1) ((x) 2)) x)', '(let-values (((x y) (values 1))) x)',
    '(let-values (((x) (values 1 2))) x)', '(let-values (((x . 1) 1)) x)',
    '(let-values (((x) (values))) x)', '(+ (values 1 2) 3)', '(+ (values) 1)',
    '(if (values 1 2) 1 2)', '(set! 1 2)', '(define 1 2)', '()', '(1 2)',
    '(cond (else 1) (#t 2))', '(cond (#t =>))', '(case 1 (else 2) ((1) 3))',
    '(do ((x 1) (x 2)) (#t x))', '(do ((x 1)) ())', '`(,@1)', '`,@(list 1)',
    '(quotient 1.5 2)', '(quotient 1 0)', '(+ #t 1)', '(/ 1 0)', '(min)',
    '(boolean=? #t 1)', '(symbol=? (quote a) "a")', '(exact +inf.0)',
    '(number->string 1 3)', '(string->number "1" 3)', '(number->string 1.5 2)'
  ].each do |source|
    it "rejects invalid forms and numeric contracts: #{source}" do
      expect { runtime.evaluate(source) }.to raise_error(Scheme::Error)
    end
  end

  it 'returns an unspecified value for unmatched conditionals and empty sequences' do
    ['(begin)', '(cond (#f 1))', '(case 3 ((1 2) 4))'].each do |source|
      expect(runtime.evaluate(source)).to equal(Scheme::UNSPECIFIED)
    end
  end
end
