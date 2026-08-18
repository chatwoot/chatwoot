require 'rails_helper'

RSpec.describe Tickets::CloseResolvedJob do
  subject(:job) { described_class.perform_now }

  let(:account) { create(:account) }

  def resolved_ticket(resolved_at)
    conversation = create(:conversation, account: account)
    travel_to(resolved_at) { conversation.update!(status: :resolved) }
    create(:ticket, account: account, conversation: conversation)
  end

  it 'closes tickets resolved longer than a week ago' do
    ticket = resolved_ticket(8.days.ago)

    job

    expect(ticket.reload.closed_at).to be_present
  end

  it 'leaves recently resolved tickets alone' do
    ticket = resolved_ticket(2.days.ago)

    job

    expect(ticket.reload.closed_at).to be_nil
  end

  it 'leaves unresolved tickets alone' do
    ticket = create(:ticket, account: account, conversation: create(:conversation, account: account))

    job

    expect(ticket.reload.closed_at).to be_nil
  end

  it 'does not restamp an already closed ticket' do
    ticket = resolved_ticket(8.days.ago)
    ticket.update!(closed_at: 3.days.ago)
    closed_at = ticket.reload.closed_at

    job

    expect(ticket.reload.closed_at).to be_within(1.second).of(closed_at)
  end
end
