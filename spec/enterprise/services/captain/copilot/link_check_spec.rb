require 'rails_helper'

RSpec.describe Captain::Copilot::LinkCheck do
  let(:check) { described_class.new(['{"url":"https://help.example.com/hc/docs/articles/refunds"}'], run_id: 1) }

  it 'removes an unknown bare URL and keeps a known one' do
    draft = 'Share https://help.example.com/hc/docs/articles/refunds. The old page was https://example.com/refunds.'

    expect(check.strip(draft)).to eq('Share https://help.example.com/hc/docs/articles/refunds. The old page was .')
  end

  it 'keeps a chart marker written as a link, so its chart is still attached' do
    expect(check.strip('Monthly volume: [copilot-chart:12](https://example.com/chart)')).to eq('Monthly volume: [copilot-chart:12]')
  end
end
