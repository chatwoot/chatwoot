# == Schema Information
#
# Table name: calendar_connections
#
#  id                       :bigint           not null, primary key
#  access_token             :text
#  access_token_expires_at  :datetime
#  email                    :string           not null
#  is_active                :boolean          default(TRUE), not null
#  provider                 :string           default("google"), not null
#  refresh_token            :text             not null
#  scopes                   :jsonb            not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint           not null
#  connected_by_id          :bigint
#
class CalendarConnection < ApplicationRecord
  belongs_to :account
  belongs_to :connected_by, class_name: 'User', optional: true
  has_many :connection_calendars, class_name: 'CalendarConnectionCalendar', dependent: :destroy_async
  has_many :calendar_events, dependent: :destroy_async

  encrypts :access_token if Chatwoot.encryption_configured?
  encrypts :refresh_token if Chatwoot.encryption_configured?

  enum :provider, { google: 'google', microsoft: 'microsoft' }

  validates :email, presence: true
  validates :refresh_token, presence: true
  validates :email, uniqueness: { scope: [:account_id, :provider] }

  scope :active, -> { where(is_active: true) }

  def profile_name
    display_name.presence || connected_by&.available_name.presence || connected_by&.name
  end

  def enabled_calendars
    connection_calendars.enabled
  end

  def calendar_enabled?(external_id)
    connection_calendars.enabled.exists?(external_id: external_id)
  end
end

