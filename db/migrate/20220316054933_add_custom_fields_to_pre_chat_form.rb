class AddCustomFieldsToPreChatForm < ActiveRecord::Migration[6.1]
  def change
    Channel::WebWidget.find_in_batches do |channels_batch|
      channels_batch.each do |channel|
        pre_chat_message = channel[:pre_chat_form_options]['pre_chat_message'] || 'Share your queries or comments here.'
        pre_chat_fields = pre_chat_fields?(channel)
        channel[:pre_chat_form_options] = {
          'pre_chat_message': pre_chat_message,
          'pre_chat_fields': pre_chat_fields
        }
        channel.save!
      end
    end
  end

  def pre_chat_fields?(channel)
    email_enabled = channel[:pre_chat_form_options]['require_email'] || false
    [
      {
        'field_type': 'standard', 'label': 'Email Id', 'name': 'emailAddress', 'type': 'email', 'required': true, 'enabled': email_enabled
      },
      {
        'field_type': 'standard', 'label': 'Full name', 'name': 'fullName', 'type': 'text', 'required': false, 'enabled': false
      }, {
        'field_type': 'standard', 'label': 'Phone number', 'name': 'phoneNumber', 'type': 'text', 'required': false, 'enabled': false
      }
    ]
  end
end
