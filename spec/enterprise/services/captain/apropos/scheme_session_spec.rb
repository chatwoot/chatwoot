require 'rails_helper'

RSpec.describe Captain::Apropos::SchemeSession do
  subject(:scheme) { described_class.new }

  it 'uses Scheme arithmetic, rest arguments, pairs and multiple values' do
    expect(scheme.execute('(/ 1 2)')).to eq(Rational(1, 2))
    expect(scheme.execute('(let-values (((a b) (values 2 3))) (+ a b))')).to eq(5)
    expect(scheme.execute('((lambda (x . rest) (+ x (car rest))) 2 3)')).to eq(5)
    expect(scheme.execute('(cdr (cons 1 2))')).to eq(2)
    expect(scheme.execute('(define-values (first . rest) (values 1 2 3)) (+ first (car rest))')).to eq(3)
  end

  it 'converts nested tool data to proper lists and back at the host boundary' do
    scheme.register('rows') { [{ 'id' => 1, 'labels' => %w[a b] }] }
    received = nil
    scheme.register('capture') { |value| received = value }
    scheme.execute('(capture (map (lambda (row) (car (get row "labels"))) (rows)))')
    expect(received).to eq(['a'])
  end

  it 'keeps hash-values distinct from standard values' do
    expect(Scheme.to_a(scheme.execute('(hash-values (hash "a" 1 "b" 2))'))).to eq([1, 2])
    expect(scheme.execute('(values 1 2)')).to be_a(Scheme::MultipleValues)
  end

  it 'shares its evaluation budget with callbacks invoked by host extensions' do
    expect { scheme.execute('(fold (lambda (acc x) (let loop () (loop))) 0 (list 1))') }.to raise_error(StandardError, /exceeded/)
    expect(scheme.execute('(+ 1 2)')).to eq(3)
  end

  it 'retains completed definitions and reports a later failed definition' do
    expect { scheme.execute('(define ok 1) (define broken (car 9))') }.to raise_error(Scheme::Error)
    expect(scheme.completed_bindings).to eq(['ok'])
    expect(scheme.failed_binding).to eq('broken')
    expect(scheme.execute('ok')).to eq(1)
  end

  it 'rejects invalid literal schemas before an earlier tool can perform an action' do
    calls = []
    scheme.register('action') { calls << :called }
    expect { scheme.execute('(action) (reason (list) "test" (hash "x" "unsupported_type"))') }
      .to raise_error(Captain::Apropos::Error, /preflight/)
    expect(calls).to be_empty
  end

  it 'does not execute any expression when parsing fails' do
    calls = []
    scheme.register('action') { calls << :called }
    expect { scheme.execute('(action) (') }.to raise_error(Scheme::ReadError)
    expect(calls).to be_empty
  end

  it 'rejects an unpersistable global without losing its previous value' do
    scheme.execute('(define saved 9)')
    expect { scheme.execute('(call/cc (lambda (k) (set! saved k)))') }.to raise_error(Captain::Apropos::Error, /Cannot persist/)
    expect(scheme.execute('saved')).to eq(9)
    expect { Captain::Apropos::Codec.dump(scheme.workspace, roots: scheme.roots) }.not_to raise_error
  end
end
