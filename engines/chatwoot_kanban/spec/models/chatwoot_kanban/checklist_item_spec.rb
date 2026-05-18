require 'rails_helper'

RSpec.describe ChatwootKanban::ChecklistItem, type: :model do
  let(:card) { create(:kanban_card, column: create(:kanban_board).columns.first) }

  it 'stamps completed_at when checked' do
    item = create(:kanban_checklist_item, card: card, completed: false)
    expect { item.update!(completed: true) }.to change { item.completed_at }.from(nil)
  end

  it 'clears completed_at when unchecked' do
    item = create(:kanban_checklist_item, card: card, completed: true)
    expect { item.update!(completed: false) }.to change { item.reload.completed_at }.to(nil)
  end

  it 'card#checklist_progress reflects completion %' do
    create(:kanban_checklist_item, card: card, completed: true,  position: 1)
    create(:kanban_checklist_item, card: card, completed: false, position: 2)
    create(:kanban_checklist_item, card: card, completed: false, position: 3)
    expect(card.reload.checklist_progress).to eq(33)
  end
end
