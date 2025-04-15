module PushDataHelper
  extend ActiveSupport::Concern

  def push_event_data
    Conversations::EventDataPresenter.new(self).push_data
  end

  def lock_event_data
    Conversations::EventDataPresenter.new(self).lock_data
  end

  def webhook_data
    {
      **Conversations::EventDataPresenter.new(self).push_data,
      id: self.id,
      account_id: self.account_id,
    }
  end
end
