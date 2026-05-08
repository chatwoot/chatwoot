require 'rails_helper'

RSpec.describe Kanban::CardSyncService do
  let(:account) { create(:account) }
  let(:consultor) { create(:user, account: account, role: :agent) }
  let(:outro_agente) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account, consultant_id: consultor.id) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }

  let!(:receive_column) do
    KanbanColumn.create!(account: account, name: 'Aguardando',
                         column_type: :standard, column_function: :auto_receive, position: 1)
  end
  let!(:won_column) do
    KanbanColumn.create!(account: account, name: 'Venda ganha',
                         column_type: :won, column_function: :no_function, position: 2)
  end
  let!(:lost_column) do
    KanbanColumn.create!(account: account, name: 'Venda perdida',
                         column_type: :lost, column_function: :no_function, position: 3)
  end

  let(:classificacao_ganha) do
    ConversationClassification.create!(account: account, name: 'Venda Ganha',
                                       classification_type: :won, position: 0)
  end

  def card_for(conversation)
    KanbanCard.find_by(conversation_id: conversation.id)
  end

  describe '#sync' do
    context 'quando uma conversa nova é criada com consultant_id no contato' do
      it 'cria card no board do consultor na coluna de auto_receive' do
        conversation = create(:conversation, account: account, contact: contact, inbox: inbox, contact_inbox: contact_inbox)

        card = card_for(conversation)
        expect(card).to be_present
        expect(card.kanban_board.user).to eq(consultor)
        expect(card.kanban_column).to eq(receive_column)
        expect(card.contact).to eq(contact)
      end
    end

    context 'quando o assignee da conversa muda' do
      it 'move o card para o board do novo assignee, na coluna de auto_receive' do
        conversation = create(:conversation, account: account, contact: contact, inbox: inbox, contact_inbox: contact_inbox)

        conversation.update!(assignee: outro_agente)

        card = card_for(conversation).reload
        expect(card.kanban_board.user).to eq(outro_agente)
        expect(card.kanban_column).to eq(receive_column)
      end
    end

    context 'quando a conversa é resolvida com classificação tipada' do
      it 'move o card para a coluna won correspondente, mantendo o board' do
        conversation = create(:conversation, account: account, contact: contact, inbox: inbox, contact_inbox: contact_inbox)
        board_antes = card_for(conversation).kanban_board

        conversation.update!(status: :resolved, classification_id: classificacao_ganha.id)

        card = card_for(conversation).reload
        expect(card.kanban_column).to eq(won_column)
        expect(card.kanban_board).to eq(board_antes)
      end
    end

    context 'quando uma conversa resolvida é reaberta' do
      it 'tira o card de won/lost e o devolve para a coluna de auto_receive' do
        conversation = create(:conversation, account: account, contact: contact, inbox: inbox, contact_inbox: contact_inbox)
        conversation.update!(status: :resolved, classification_id: classificacao_ganha.id)
        expect(card_for(conversation).reload.kanban_column).to eq(won_column)

        conversation.update!(status: :open)

        expect(card_for(conversation).reload.kanban_column).to eq(receive_column)
      end
    end

    context 'quando o contato volta com uma nova conversa após ter resolvido a anterior' do
      it 'cria um novo card sem reaproveitar o card antigo (que fica em won/lost)' do
        conversation_1 = create(:conversation, account: account, contact: contact, inbox: inbox, contact_inbox: contact_inbox)
        conversation_1.update!(status: :resolved, classification_id: classificacao_ganha.id)
        card_antigo = card_for(conversation_1)

        outro_contact_inbox = create(:contact_inbox, contact: contact, inbox: inbox)
        conversation_2 = create(:conversation, account: account, contact: contact, inbox: inbox, contact_inbox: outro_contact_inbox)

        card_novo = card_for(conversation_2)
        expect(card_novo).to be_present
        expect(card_novo.id).not_to eq(card_antigo.id)
        expect(card_novo.kanban_column).to eq(receive_column)
        expect(card_antigo.reload.kanban_column).to eq(won_column)
        expect(KanbanCard.where(contact_id: contact.id).count).to eq(2)
      end
    end
  end
end
