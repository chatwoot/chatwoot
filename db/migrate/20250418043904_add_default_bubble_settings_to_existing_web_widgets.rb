class AddDefaultBubbleSettingsToExistingWebWidgets < ActiveRecord::Migration[7.0]
  def change
    # Find all web widgets that don't have bubble settings
    web_widgets_without_settings = Channel::WebWidget.where.not(
      id: WidgetBubbleSetting.select(:channel_web_widget_id)
    )

    # Add default settings for each web widget
    web_widgets_without_settings.find_each do |web_widget|
      WidgetBubbleSetting.create!(
        channel_web_widget_id: web_widget.id,
        position: 'right',
        bubble_type: 'standard',
        launcher_title: 'Chat with us'
      )
    end
  end
end
