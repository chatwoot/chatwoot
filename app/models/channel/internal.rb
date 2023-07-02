# == Schema Information
#
# Table name: channel_internal
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer          not null
#

class Channel::Internal < ApplicationRecord
  include Channelable
  EDITABLE_ATTRS = [:name].freeze

  def name
    'Internal'
  end

  self.table_name = 'channel_internal'
end
