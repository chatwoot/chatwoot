require 'rails_helper'

describe Whatsapp::GraphDeadline do
  let(:ceiling) { { timeout: 10, max_retries: 0 }.freeze }
  let(:now) { [100.0] }

  before do
    allow(Process).to receive(:clock_gettime).and_call_original
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC) { now.first }
  end

  def elapse(seconds) = now[0] += seconds

  it 'leaves the per-call ceiling alone while more than the ceiling is left' do
    deadline = described_class.in(12)
    elapse(1)

    expect(deadline.cut(ceiling)).to eq(timeout: 10)
  end

  it 'cuts the ceiling to what is left of the request' do
    deadline = described_class.in(12)
    elapse(9.5)

    expect(deadline.cut(ceiling)).to eq(timeout: 2.5)
  end

  it 'refuses a call that could not even open a connection in what is left' do
    deadline = described_class.in(12)
    elapse(11.5)

    expect { deadline.cut(ceiling) }.to raise_error(described_class::Exceeded, /no time left/)
  end

  it 'still lets a call through with exactly the minimum left' do
    deadline = described_class.in(12)
    elapse(12 - described_class::MINIMUM_CALL_SECONDS)

    expect(deadline.cut(ceiling)).to eq(timeout: described_class::MINIMUM_CALL_SECONDS)
  end

  it 'answers the ceiling as it is when there is no deadline' do
    elapse(1_000)

    expect(described_class::NONE.cut(ceiling)).to eq(timeout: 10)
  end
end
