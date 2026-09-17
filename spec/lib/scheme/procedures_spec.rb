require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe 'Scheme standard procedures' do
  subject(:runtime) { Scheme::Runtime.new }

  {
    '(cons 1 2)' => '(1 . 2)',
    '(append (list 1 2) (list 3) 4)' => '(1 2 3 . 4)',
    '(map + (list 1 2 3) (list 10 20 30))' => '(11 22 33)',
    '(map + (list 1 2) (list 10))' => '(11)',
    '(member 2 (list 1 2 3))' => '(2 3)',
    '(member 7 (list 1 2 3))' => '#f',
    '(assoc (quote b) (quote ((a . 1) (b . 2))))' => '(b . 2)',
    '(list-tail (quote (1 2 . 3)) 2)' => '3',
    '(reverse (list 1 2 3))' => '(3 2 1)',
    '(let ((xs (list 1 2))) (set-car! xs 3) (set-cdr! (cdr xs) 4) xs)' => '(3 2 . 4)',
    '(let ((xs (list 1))) (set-cdr! xs xs) (list? xs))' => '#f',
    '(let ((x (list 1 2))) (eq? (cdr x) (cdr x)))' => '#t',
    '(let ((n 0)) (for-each (lambda (x) (set! n (+ n x))) (list 1 2 3)) n)' => '6',
    '`(1 ,(+ 1 1) ,@(list 3 4) . 5)' => '(1 2 3 4 . 5)',
    '(symbol->string (quote hello))' => '"hello"',
    '(string->symbol "hello")' => 'hello',
    '(string #\\h #\\i)' => '"hi"',
    '(string-ref "abc" 1)' => '#\\b',
    '(string->list "abc" 1)' => '(#\\b #\\c)',
    '(list->string (list #\\a #\\b))' => '"ab"',
    '(string<? "a" "b" "c")' => '#t',
    '(let ((s (string-copy "abc"))) (string-set! s 1 #\\x) s)' => '"axc"',
    '(vector->list (vector 1 2 3) 1)' => '(2 3)',
    '(let ((v (vector 1 2))) (vector-set! v 1 3) v)' => '#(1 3)',
    '(utf8->string (string->utf8 "λ"))' => '"λ"',
    '(list (floor -4.3) (ceiling -4.3) (truncate -4.3) (round 2.5))' => '(-5.0 -4.0 -4.0 2.0)',
    '(list (quotient -13 4) (remainder -13 4) (modulo -13 4))' => '(-3 -1 3)',
    '(list (numerator 3/4) (denominator 3/4) (gcd 12 18) (lcm 4 6))' => '(3 4 6 12)',
    '(list (number->string 255 16) (string->number "ff" 16) (string->number "no"))' => '("ff" 255 #f)',
    '(list (exact? 1/3) (inexact? 1.0) (integer? 3.0) (exact 0.5))' => '(#t #t #t 1/2)'
  }.each do |source, expected|
    it "evaluates #{source}" do
      expect(Scheme.write(runtime.evaluate(source))).to eq(expected)
    end
  end

  it 'rejects mutation of literal pairs' do
    expect { runtime.evaluate('(set-car! (quote (1 2)) 3)') }.to raise_error(Scheme::Error, /literal|immutable/)
  end

  it 'rejects lengths of improper and cyclic lists rather than hanging' do
    expect { runtime.evaluate('(length (cons 1 2))') }.to raise_error(Scheme::Error, /list/)
    expect { runtime.evaluate('(let ((xs (list 1))) (set-cdr! xs xs) (length xs))') }.to raise_error(Scheme::Error, /cyclic/)
  end
end
