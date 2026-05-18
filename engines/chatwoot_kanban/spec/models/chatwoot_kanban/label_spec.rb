require 'rails_helper'

RSpec.describe ChatwootKanban::Label, type: :model do
  let(:account) { create(:account) }

  it 'enforces unique name per account' do
    create(:kanban_label, account: account, name: 'Bug')
    dup = build(:kanban_label, account: account, name: 'Bug')
    expect(dup).not_to be_valid
  end

  it 'validates hex color' do
    expect(build(:kanban_label, color: 'red')).not_to be_valid
    expect(build(:kanban_label, color: '#abcdef')).to be_valid
  end
end
