require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Runtime do
  subject(:runtime) { described_class.new }

  # R7RS-small 5.3.2: internal bindings cover the entire body, as in letrec*.
  # https://standards.scheme.org/r7rs-html5/index.html
  {
    '((lambda () (define begin (lambda args 99)) 0 (begin 1 2)))' => '99',
    '(let () (define (begin x y) (+ x y)) 0 (begin 1 2))' => '3',
    '(let () (define-values (begin) (values list)) 0 (begin 1 2))' => '(1 2)',
    '(let () (define begin list) (define x (begin 1 2)) x)' => '(1 2)',
    '(let () (define begin list) (define (f) (begin 1 2)) (f))' => '(1 2)',
    '(let ((begin list)) (begin 1 2))' => '(1 2)',
    '(let () (begin (define x 1) (begin (define y 2))) (+ x y))' => '3',
    '(let () (begin) (begin (define x 1)) (begin (define y 2)) (+ x y))' => '3',
    '(let () (begin (define (f) (g)) (define (g) 42)) (f))' => '42',
    '(let () (begin (define x 1) (define y 2) (+ x y)))' => '3'
  }.each do |source, expected|
    it "resolves internal definitions and begin in #{source}" do
      expect(Scheme.write(runtime.evaluate(source))).to eq(expected)
    end
  end

  it 'reserves definitions inside nested begins before evaluating any initializer' do
    source = '(let ((y 99)) (let () (begin (define x y) (begin (define y 2))) x))'
    expect { runtime.evaluate(source) }.to raise_error(Scheme::Error, /before initialization: y/)
  end

  it 'preserves side effects and multiple values in expression begins' do
    source = <<~SCHEME
      (let ((x 0))
        (define (f)
          (begin (set! x (+ x 1)) (values x (+ x 1))))
        (call-with-values f list))
    SCHEME
    expect(Scheme.write(runtime.evaluate(source))).to eq('(1 2)')
  end
end
