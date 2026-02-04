class FixPreChatFieldNames < ActiveRecord::Migration[7.1]
  def up
    Channel::WebWidget.find_each do |channel|
      next if channel.pre_chat_form_options.blank?

      fields = channel.pre_chat_form_options['pre_chat_fields']
      next if fields.blank?

      modified = false

      fields.each do |field|
        case field['name']
        when 'emailAddress'
          field['name'] = 'email'
          modified = true
        when 'fullName'
          field['name'] = 'name'
          modified = true
        end
      end

      channel.save! if modified
    end
  end
end
