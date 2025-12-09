# == Schema Information
#
# Table name: funnel_contacts
#
#  id         :bigint           not null, primary key
#  position   :integer          default(0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  column_id  :string           not null
#  contact_id :bigint           not null
#  funnel_id  :bigint           not null
#
# Indexes
#
#  index_funnel_contacts_on_contact_id                (contact_id)
#  index_funnel_contacts_on_funnel_id                 (funnel_id)
#  index_funnel_contacts_on_funnel_id_and_column_id   (funnel_id,column_id)
#  index_funnel_contacts_on_funnel_id_and_contact_id  (funnel_id,contact_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => cascade
#  fk_rails_...  (funnel_id => funnels.id) ON DELETE => cascade
#
class FunnelContact < ApplicationRecord
  belongs_to :funnel
  belongs_to :contact

  validates :column_id, presence: true
  validates :contact_id, uniqueness: { scope: :funnel_id }
end
