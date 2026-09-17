require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe 'Scheme control features' do
  subject(:runtime) { Scheme::Runtime.new }

  {
    '(+ 1 (call/cc (lambda (escape) (+ 2 (escape 5)))))' => '6',
    '(call-with-values (lambda () (call/cc (lambda (k) (k 1 2)))) list)' => '(1 2)',
    '(call/cc (lambda (exit) (map (lambda (x) (if (= x 3) (exit x) x)) (list 1 2 3 4))))' => '3',
    '(let ((p (delay (+ 2 3)))) (list (promise? p) (force p) (force p)))' => '(#t 5 5)',
    '(let ((n 0)) (let ((p (delay (begin (set! n (+ n 1)) n)))) (list (force p) (force p) n)))' => '(1 1 1)',
    '(force (delay-force (delay 7)))' => '7',
    '(force (make-promise 12))' => '12',
    '(let ((p (make-parameter 1))) (list (p) (parameterize ((p 2)) (p)) (p)))' => '(1 2 1)',
    '(let ((p (make-parameter 1 abs))) (parameterize ((p -3)) (p)))' => '3',
    '(let ((f (case-lambda (() 0) ((x) x) ((x y . rest) (+ x y (length rest)))))) (list (f) (f 3) (f 1 2 3 4)))' => '(0 3 5)',
    '(with-exception-handler (lambda (x) (+ x 1)) (lambda () (+ 1 (raise-continuable 4))))' => '6',
    '(call/cc (lambda (exit) (with-exception-handler (lambda (x) (exit x)) (lambda () (raise 42)))))' => '42',
    '(guard (e ((number? e) (+ e 1)) (else 0)) (raise 5))' => '6',
    '(guard (e (else (list (error-object? e) (error-object-message e) (error-object-irritants e)))) (error "bad input" 1 2))' => '(#t "bad input" (1 2))',
    '(guard (e (else (error-object? e))) (car 1))' => '#t'
  }.each do |source, expected|
    it "evaluates #{source}" do
      expect(Scheme.write(runtime.evaluate(source))).to eq(expected)
    end
  end

  it 'supports reusable continuations after the original evaluation returns' do
    expect(runtime.evaluate('(define saved #f) (+ 10 (call/cc (lambda (k) (set! saved k) 1)))')).to eq(11)
    expect(runtime.evaluate('(saved 5)')).to eq(15)
    expect(runtime.evaluate('(saved 8)')).to eq(18)
  end

  it 'executes dynamic-wind exit and reentry callbacks' do
    source = <<~SCHEME
      (define log '())
      (define saved #f)
      (define (record x) (set! log (append log (list x))))
      (dynamic-wind
        (lambda () (record 'enter))
        (lambda () (call/cc (lambda (k) (set! saved k))) (record 'body))
        (lambda () (record 'exit)))
    SCHEME
    runtime.evaluate(source)
    runtime.evaluate('(saved 0)')
    expect(Scheme.write(runtime.evaluate('log'))).to eq('(enter body exit enter body exit)')
  end

  it 'restores parameters across escaping and reentering a continuation' do
    runtime.evaluate('(define p (make-parameter 1)) (define saved #f)')
    expect(runtime.evaluate('(parameterize ((p 2)) (call/cc (lambda (k) (set! saved k))) (p))')).to eq(2)
    expect(runtime.evaluate('(p)')).to eq(1)
    expect(runtime.evaluate('(saved 5)')).to eq(2)
    expect(runtime.evaluate('(p)')).to eq(1)
  end

  it 'supports records with type-specific predicates, constructors, readers, and writers' do
    runtime.evaluate(<<~SCHEME)
      (define-record-type <point>
        (make-point x y) point?
        (x point-x set-point-x!)
        (y point-y))
      (define point (make-point 2 3))
      (set-point-x! point 4)
    SCHEME
    expect(Scheme.write(runtime.evaluate('(list (point? point) (point? 4) (point-x point) (point-y point))'))).to eq('(#t #f 4 3)')
    expect { runtime.evaluate('(point-x 1)') }.to raise_error(Scheme::Error, /record/)
  end

  it 'keeps tail calls bounded through call-with-values' do
    source = '(let loop ((n 10000)) (if (= n 0) n (call-with-values (lambda () (- n 1)) loop)))'
    expect(runtime.evaluate(source)).to eq(0)
  end
end
