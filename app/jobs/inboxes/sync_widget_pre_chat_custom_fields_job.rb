class Inboxes::SyncWidgetPreChatCustomFieldsJob < ApplicationJob
  queue_as :default

  def perform(account, field_name)
    [account.web_widgets, account.mobile_app_channels].each do |channels|
      channels.find_each do |web_widget|
        pre_chat_fields = web_widget.pre_chat_form_options['pre_chat_fields']
        web_widget.pre_chat_form_options['pre_chat_fields'] = pre_chat_fields.reject { |field| field['name'] == field_name }
        web_widget.save!
      end
    end
  end
end
