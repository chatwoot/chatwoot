require 'rails_helper'

RSpec.describe V2::Reports::InboxLabelMatrixBuilder do
  let!(:account) { create(:account) }
  let!(:inbox_one) { create(:inbox, account: account, name: 'Email Support') }
  let!(:inbox_two) { create(:inbox, account: account, name: 'Web Chat') }
  let!(:label_one) { create(:label, account: account, title: 'bug') }
  let!(:label_two) { create(:label, account: account, title: 'feature') }
  let(:params) do
    {
      since: 1.week.ago.beginning_of_day.to_i.to_s,
      until: Time.current.end_of_day.to_i.to_s
    }
  end
  let(:builder) { described_class.new(account: account, params: params) }

  describe '#build' do
    subject(:report) { builder.build }

    context 'when there are conversations with labels across inboxes' do
      before do
        c1 = create(:conversation, account: account, inbox: inbox_one, created_at: 2.days.ago)
        c1.update!(label_list: [label_one.title])

        c2 = create(:conversation, account: account, inbox: inbox_one, created_at: 3.days.ago)
        c2.update!(label_list: [label_one.title, label_two.title])

        c3 = create(:conversation, account: account, inbox: inbox_two, created_at: 1.day.ago)
        c3.update!(label_list: [label_two.title])
      end

      it 'returns inboxes ordered by name' do
        expect(report[:inboxes]).to eq([
                                         { id: inbox_one.id, name: 'Email Support' },
                                         { id: inbox_two.id, name: 'Web Chat' }
                                       ])
      end

      it 'returns labels ordered by title' do
        expect(report[:labels]).to eq([
                                        { id: label_one.id, title: 'bug' },
                                        { id: label_two.id, title: 'feature' }
                                      ])
      end

      it 'returns correct conversation counts in the matrix' do
        # Email Support: bug=2, feature=1
        # Web Chat: bug=0, feature=1
        expect(report[:matrix]).to eq([[2, 1], [0, 1]])
      end
    end

    context 'when filtering by inbox_ids' do
      let(:params) do
        {
          since: 1.week.ago.beginning_of_day.to_i.to_s,
          until: Time.current.end_of_day.to_i.to_s,
          inbox_ids: [inbox_one.id]
        }
      end

      before do
        c1 = create(:conversation, account: account, inbox: inbox_one, created_at: 2.days.ago)
        c1.update!(label_list: [label_one.title])

        c2 = create(:conversation, account: account, inbox: inbox_two, created_at: 1.day.ago)
        c2.update!(label_list: [label_one.title])
      end

      it 'only includes the specified inboxes and their counts' do
        expect(report[:inboxes]).to eq([{ id: inbox_one.id, name: 'Email Support' }])
        expect(report[:matrix]).to eq([[1, 0]])
      end
    end

    context 'when filtering by label_ids' do
      let(:params) do
        {
          since: 1.week.ago.beginning_of_day.to_i.to_s,
          until: Time.current.end_of_day.to_i.to_s,
          label_ids: [label_one.id]
        }
      end

      before do
        c1 = create(:conversation, account: account, inbox: inbox_one, created_at: 2.days.ago)
        c1.update!(label_list: [label_one.title, label_two.title])
      end

      it 'only includes the specified labels and their counts' do
        expect(report[:labels]).to eq([{ id: label_one.id, title: 'bug' }])
        expect(report[:matrix]).to eq([[1], [0]])
      end
    end

    context 'when conversations are outside the date range' do
      before do
        c1 = create(:conversation, account: account, inbox: inbox_one, created_at: 2.days.ago)
        c1.update!(label_list: [label_one.title])

        c2 = create(:conversation, account: account, inbox: inbox_one, created_at: 2.weeks.ago)
        c2.update!(label_list: [label_one.title])
      end

      it 'only counts conversations within the date range' do
        expect(report[:matrix]).to eq([[1, 0], [0, 0]])
      end
    end

    context 'when there are no conversations with labels' do
      before do
        create(:conversation, account: account, inbox: inbox_one, created_at: 2.days.ago)
      end

      it 'returns a matrix of zeros' do
        expect(report[:matrix]).to eq([[0, 0], [0, 0]])
      end
    end

    context 'when conversations belong to another account' do
      let(:other_account) { create(:account) }
      let(:other_inbox) { create(:inbox, account: other_account) }

      before do
        c1 = create(:conversation, account: other_account, inbox: other_inbox, created_at: 2.days.ago)
        other_label = create(:label, account: other_account, title: 'bug')
        c1.update!(label_list: [other_label.title])
      end

      it 'does not include conversations from other accounts' do
        expect(report[:matrix]).to eq([[0, 0], [0, 0]])
      end
    end
  end
end
