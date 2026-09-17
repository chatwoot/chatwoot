require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe 'Scheme preloaded environment' do
  subject(:runtime) { Scheme::Runtime.new }

  it 'provides implemented procedures without import declarations' do
    source = '(list (map car (list (list 1 2) (list 3 4))) (force (delay 5)) ((case-lambda ((x) x)) 6))'

    expect(Scheme.write(runtime.evaluate(source))).to eq('((1 3) 5 6)')
  end

  it 'accepts import declarations as no-ops' do
    expect(runtime.evaluate('(import (scheme base) (scheme lazy) (scheme case-lambda))')).to equal(Scheme::UNSPECIFIED)
    expect(Scheme.write(runtime.evaluate('(map car (list (list 1) (list 2)))'))).to eq('(1 2)')
  end

  it 'does not evaluate the contents of an import declaration' do
    runtime.evaluate('(define counter 0)')
    runtime.evaluate('(import (begin (set! counter 1) (error "must not execute")))')

    expect(runtime.evaluate('counter')).to eq(0)
  end

  it 'does not create aliases or restrict the preloaded environment for import modifiers' do
    runtime.evaluate('(import (only (scheme base) car) (prefix (scheme base) base:) (rename (scheme base) (car first)))')

    expect(runtime.evaluate('(car (list (+ 1 2)))')).to eq(3)
    expect { runtime.evaluate('(first (list 1))') }.to raise_error(Scheme::Error, /unbound identifier: first/)
    expect { runtime.evaluate('(base:car (list 1))') }.to raise_error(Scheme::Error, /unbound identifier: base:car/)
  end

  it 'does not reset existing bindings when imports are repeated' do
    runtime.evaluate('(define car (lambda (x) 42))')
    runtime.evaluate('(import (scheme base)) (import (scheme base))')

    expect(runtime.evaluate('(car (list 1))')).to eq(42)
  end

  it 'does not load or invent procedures for ignored library names' do
    runtime.evaluate('(import (some external library))')

    expect { runtime.evaluate('(external-function)') }.to raise_error(Scheme::Error, /unbound identifier: external-function/)
  end
end
