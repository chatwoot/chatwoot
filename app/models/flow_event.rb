# == Schema Information
#
# Table name: flow_events
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  data        :jsonb
#  event_type  :string           not null
#  node_id     :string
#  flow_run_id :bigint           not null
#
class FlowEvent < ApplicationRecord
  belongs_to :flow_run

  validates :event_type, presence: true
end
