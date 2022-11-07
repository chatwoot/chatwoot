class Inboxes::UpdateWidgetPreChatCustomFieldsJob < ApplicationJob
  queue_as :default

  def perform(account, custom_attribute)
    attribute_key = custom_attribute['attribute_key']
    account.web_widgets.all.find_each do |web_widget|
      pre_chat_fields = web_widget.pre_chat_form_options['pre_chat_fields']
      pre_chat_fields.each_with_index do |pre_chat_field, index|
        next unless pre_chat_field['name'] == attribute_key

        web_widget.pre_chat_form_options['pre_chat_fields'][index] =
          pre_chat_field.deep_merge({
                                      'label' => custom_attribute['attribute_display_name'],
                                      'placeholder' => custom_attribute['attribute_display_name'],
                                      'values' => custom_attribute['attribute_values']
                                    })
      end
      web_widget.save!
    end
  end
end
