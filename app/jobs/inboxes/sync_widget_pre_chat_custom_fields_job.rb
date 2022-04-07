class Inboxes::SyncWidgetPreChatCustomFieldsJob < ApplicationJob
  queue_as :default

  def perform(field_name)
    Channel::WebWidget.all.find_each do |web_widget|
      pre_chat_fields = web_widget.pre_chat_form_options['pre_chat_fields']
      web_widget.pre_chat_form_options['pre_chat_fields'] = pre_chat_fields.reject { |field| field['name'] == field_name }
      web_widget.save!
    end
  end
end
