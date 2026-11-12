module Enterprise::Campaign
  extend ActiveSupport::Concern

  included do
    has_many :campaign_recipients, dependent: :delete_all
    before_update :initialize_whatsapp_cursor, if: :starting_whatsapp_campaign?
  end

  private

  def starting_whatsapp_campaign?
    return false unless will_save_change_to_campaign_status? && processing? && one_off?

    inbox.inbox_type == 'Whatsapp' && inbox.channel.provider == 'whatsapp_cloud'
  end

  def initialize_whatsapp_cursor
    # Commit recovery eligibility in the same update as the transition to Processing.
    self.whatsapp_cursor ||= 0
  end
end
