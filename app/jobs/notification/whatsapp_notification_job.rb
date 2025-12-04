# frozen_string_literal: true

class Notification::WhatsappNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification)
    Notification::WhatsappNotificationService.new(notification: notification).perform
  end
end
