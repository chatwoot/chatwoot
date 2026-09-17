require 'rails_helper'

RSpec.describe Captain::Apropos::Codec do
  let(:scheme) { Captain::Apropos::SchemeSession.new }
  let(:restored) { Captain::Apropos::SchemeSession.new }

  it 'restores recursive functions, shared lexical cells and exact numbers without replay' do
    scheme.execute('(define (factorial n) (if (= n 0) 1 (* n (factorial (- n 1)))))
      (define counter (let ((n 0)) (lambda () (set! n (+ n 1)) n)))
      (define half (/ 1 2)) (counter)')
    state = JSON.parse(JSON.generate(described_class.dump(scheme.workspace, roots: scheme.roots)))
    described_class.load(state, roots: restored.roots).each { |name, value| restored.bind(name, value) }
    expect(restored.execute('(factorial 5)')).to eq(120)
    expect(restored.execute('(counter)')).to eq(2)
    expect(restored.execute('half')).to eq(Rational(1, 2))
  end

  it 'preserves shared and cyclic pairs and immutable literal lists' do
    scheme.execute('(define x (list 1)) (define y x) (set-cdr! x x) (define quoted (quote (a b)))')
    state = JSON.parse(JSON.generate(described_class.dump(scheme.workspace, roots: scheme.roots)))
    described_class.load(state, roots: restored.roots).each { |name, value| restored.bind(name, value) }
    expect(restored.execute('(eq? x y)')).to be(true)
    expect(restored.execute('(eq? x (cdr x))')).to be(true)
    expect { restored.execute('(set-car! quoted 1)') }.to raise_error(Scheme::Error, /immutable/)
  end

  it 'migrates a legacy saved lambda without retaining the old interpreter' do
    legacy = {
      'type' => 'closure', 'id' => 0,
      'parameters' => [{ 'type' => 'symbol', 'value' => 'n' }],
      'body' => [[{ 'type' => 'symbol', 'value' => '+' }, { 'type' => 'symbol', 'value' => 'n' }, 1]], 'locals' => nil
    }
    restored.bind(:increment, described_class.load(legacy, roots: restored.roots))
    expect(restored.execute('(increment 4)')).to eq(5)
  end

  it 'round-trips a long list without building a deeply nested JSON document' do
    data = Scheme.list((1..3000).to_a)
    state = JSON.parse(JSON.generate(described_class.dump(data)))
    expect(Scheme.to_a(described_class.load(state))).to eq((1..3000).to_a)
  end
end
