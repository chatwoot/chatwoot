class AddLifecycleFieldsToSynapseosLeads < ActiveRecord::Migration[7.1]
  # ADR-003: máquina de estados de lead. Adiciona o estado de 1ª classe, o
  # próximo passo agendado (I2), o contador de cadência, a data de retomada, o
  # motivo do desfecho e os campos de negócio (I3). `estado` é nullable de
  # propósito: leads legados ficam sem estado até a 1ª transição.
  def change
    add_column :synapseos_leads, :estado, :string
    add_column :synapseos_leads, :next_action_at, :datetime
    add_column :synapseos_leads, :cadence_touch, :integer, null: false, default: 0
    add_column :synapseos_leads, :retomada_at, :datetime
    add_column :synapseos_leads, :motivo, :text

    # Campos de negócio (antes só detectados por keyword e perdidos).
    add_column :synapseos_leads, :modelo_interesse, :string
    # tem_troca é tri-state de propósito: NULL = ainda não detectado pelo SDR,
    # true/false = detectado. Não usar default.
    add_column :synapseos_leads, :tem_troca, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
    add_column :synapseos_leads, :forma_pagamento, :string
    add_column :synapseos_leads, :urgencia, :string
    add_column :synapseos_leads, :horizonte_compra, :string

    # Suporta a query do sweeper e do motor de cadência: "leads num estado
    # cujo próximo passo já venceu".
    add_index :synapseos_leads, [:account_id, :estado, :next_action_at],
              name: 'idx_synapseos_leads_estado_next_action'
  end
end
