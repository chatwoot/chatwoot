# CUSTOMIZAÇÃO_SYNAPSEOS
# Relatório mensal da Elisa. O n8n (cron dia 1) calcula os números e faz upsert
# aqui via API; o HTML é renderizado sob demanda a partir de `data` + do template
# ERB (Synapseos::MonthlyReportRenderer). Um registro por (conta, período).
module Synapseos
  class MonthlyReport < ApplicationRecord
    self.table_name = 'synapseos_monthly_reports'

    belongs_to :account

    validates :period, presence: true, uniqueness: { scope: :account_id }

    scope :recent_first, -> { order(period: :desc) }
  end
end
