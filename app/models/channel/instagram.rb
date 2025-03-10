# == Schema Information
#
# Table name: channel_instagram
#
#  id            :bigint           not null, primary key
#  access_token  :string           not null
#  expires_at    :datetime         not null
#  refresh_token :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#  instagram_id  :string           not null
#

class Channel::Instagram < ApplicationRecord
  include Channelable
  include Reauthorizable
  self.table_name = 'channel_instagram'

  def name
    'Instagram'
  end

  def create_contact_inbox(instagram_id, name)
    @contact_inbox = ::ContactInboxWithContactBuilder.new({
                                                            source_id: instagram_id,
                                                            inbox: inbox,
                                                            contact_attributes: { name: name }
                                                          }).perform
  end
end
