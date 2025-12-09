# == Schema Information
#
# Table name: funnels
#
#  id         :bigint           not null, primary key
#  columns    :jsonb            not null
#  is_default :boolean          default(FALSE), not null
#  name       :string           not null
#  position   :integer          default(0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  team_id    :bigint
#
# Indexes
#
#  index_funnels_on_account_id                 (account_id)
#  index_funnels_on_account_id_and_is_default  (account_id,is_default) UNIQUE WHERE (is_default = true)
#  index_funnels_on_account_id_and_name        (account_id,name) UNIQUE
#  index_funnels_on_team_id                    (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (team_id => teams.id) ON DELETE => nullify
#
class Funnel < ApplicationRecord
  belongs_to :account
  belongs_to :team, optional: true
  has_many :funnel_contacts, dependent: :destroy_async
  has_many :contacts, through: :funnel_contacts

  validates :name, presence: { message: I18n.t('errors.validations.presence') },
                   uniqueness: { scope: :account_id }
  validates :columns, presence: true

  before_validation :set_default_columns, on: :create
  before_validation :ensure_single_default, on: :create, if: :is_default?

  DEFAULT_COLUMNS = [
    { 'id' => 'recentes', 'name' => 'Recentes', 'position' => 0 },
    { 'id' => 'backlog', 'name' => 'Backlog', 'position' => 1 },
    { 'id' => 'prioridade', 'name' => 'Prioridade', 'position' => 2 },
    { 'id' => 'em_execucao', 'name' => 'Em Execução', 'position' => 3 },
    { 'id' => 'aguardando_terceiros', 'name' => 'Aguardando Terceiros', 'position' => 4 }
  ].freeze

  def default_columns
    DEFAULT_COLUMNS
  end

  private

  def set_default_columns
    self.columns = default_columns if columns.blank?
  end

  def ensure_single_default
    return unless is_default?

    account.funnels.where(is_default: true).update_all(is_default: false)
  end
end
