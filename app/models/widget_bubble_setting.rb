class WidgetBubbleSetting < ApplicationRecord
  self.inheritance_column = nil
  belongs_to :channel_web_widget, class_name: 'Channel::WebWidget'

  validates :position, presence: true, inclusion: { in: %w[left right] }
  validates :bubble_type, presence: true, inclusion: { in: %w[standard expanded_bubble] }
  validates :launcher_title, presence: true

  def self.default_settings
    {
      position: 'right',
      bubble_type: 'standard',
      launcher_title: 'Chat with us'
    }
  end
end 