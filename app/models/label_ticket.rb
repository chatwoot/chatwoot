# == Schema Information
#
# Table name: label_tickets
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  label_id   :bigint           not null
#  ticket_id  :bigint           not null
#
# Indexes
#
#  index_label_tickets_on_label_id                (label_id)
#  index_label_tickets_on_ticket_id               (ticket_id)
#  index_label_tickets_on_ticket_id_and_label_id  (ticket_id,label_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (label_id => labels.id)
#  fk_rails_...  (ticket_id => tickets.id)
#
class LabelTicket < ApplicationRecord
  belongs_to :ticket
  belongs_to :label
end
