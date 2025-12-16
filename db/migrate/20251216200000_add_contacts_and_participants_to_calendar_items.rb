class AddContactsAndParticipantsToCalendarItems < ActiveRecord::Migration[7.0]
  def change
    # Tabela de contatos vinculados (referência, sem notificação)
    create_table :ottiv_calendar_item_contacts do |t|
      t.bigint :ottiv_calendar_item_id, null: false
      t.bigint :contact_id, null: false
      t.timestamps
    end

    add_index :ottiv_calendar_item_contacts,
              [:ottiv_calendar_item_id, :contact_id],
              unique: true,
              name: 'idx_calendar_item_contacts_unique'
    add_foreign_key :ottiv_calendar_item_contacts, :ottiv_calendar_items
    add_foreign_key :ottiv_calendar_item_contacts, :contacts

    # Tabela de participantes (usuários notificados)
    # Nota: O criador sempre é incluído automaticamente como participante
    create_table :ottiv_calendar_item_participants do |t|
      t.bigint :ottiv_calendar_item_id, null: false
      t.bigint :user_id, null: false
      t.timestamps
    end

    add_index :ottiv_calendar_item_participants,
              [:ottiv_calendar_item_id, :user_id],
              unique: true,
              name: 'idx_calendar_item_participants_unique'
    add_foreign_key :ottiv_calendar_item_participants, :ottiv_calendar_items
    add_foreign_key :ottiv_calendar_item_participants, :users
  end
end

