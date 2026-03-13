require 'rails_helper'

shared_examples_for 'backoffable' do
  let(:obj) { FactoryBot.create(described_class.to_s.underscore.tr('/', '_').to_sym) }

  before do
    allow(GlobalConfigService).to receive(:load).with('BACKOFF_MAX_INTERVAL_MINUTES', 5).and_return(2)
    allow(GlobalConfigService).to receive(:load).with('BACKOFF_MAX_INTERVAL_COUNT', 10).and_return(3)
    # max_interval=2, max_retries=(2-1)+3=4; exhausts on 5th apply_backoff!
  end

  it 'starts with no backoff' do
    expect(obj.in_backoff?).to be false
    expect(obj.backoff_retry_count).to eq 0
  end

  it 'ramps backoff on each failure' do
    obj.apply_backoff!
    expect(obj.backoff_retry_count).to eq 1
    expect(obj.in_backoff?).to be true
  end

  it 'caps wait time at max interval' do
    4.times { obj.apply_backoff! }
    expect(obj.backoff_retry_count).to eq 4
    expect(obj.in_backoff?).to be true
  end

  it 'exhausts backoff and calls prompt_reauthorization! after max retries' do
    allow(obj).to receive(:prompt_reauthorization!)
    5.times { obj.apply_backoff! }
    expect(obj).to have_received(:prompt_reauthorization!)
    expect(obj.backoff_retry_count).to eq 0
    expect(obj.in_backoff?).to be false
  end

  it 'clear_backoff! resets retry count and backoff window' do
    obj.apply_backoff!
    obj.clear_backoff!
    expect(obj.in_backoff?).to be false
    expect(obj.backoff_retry_count).to eq 0
  end
end
