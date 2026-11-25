module PushDataHelper
  extend ActiveSupport::Concern

  def push_event_data
    Conversations::EventDataPresenter.new(self).push_data
  end

  # The narrowed copy for broadcasts that reach the contact. Anything Pro or
  # Enterprise bolts onto `push_data` is excluded automatically, because the
  # presenter allowlists rather than denylists.
  def contact_push_event_data
    Conversations::EventDataPresenter.new(self).contact_push_data
  end

  def lock_event_data
    Conversations::EventDataPresenter.new(self).lock_data
  end

  def widget_push_event_data
    Conversations::EventDataPresenter.new(self).widget_data
  end

  def webhook_data
    Conversations::EventDataPresenter.new(self).webhook_data
  end
end
