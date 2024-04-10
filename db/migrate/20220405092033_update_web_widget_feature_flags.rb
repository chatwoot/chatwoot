class UpdateWebWidgetFeatureFlags < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:channel_web_widgets, :feature_flags, from: 3, to: 7)

    set_end_conversation_to_default
  end

  def set_end_conversation_to_default
    ::Channel::WebWidget.find_in_batches do |widget_batch|
      widget_batch.each do |widget|
        widget.end_conversation = true
        widget.save!
      end
    end
  end
end
