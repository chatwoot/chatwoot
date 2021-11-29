class Whatsapp::SendOnWhatsappService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Whatsapp
  end

  def perform_reply
    # can reply checks if 24 hour limit has passed.
    if message.conversation.can_reply?
      send_on_whatsapp
    else
      send_template_message
    end
  end


  private
  
  def send_template_message
    name, namespace, lang_code, parameters = nil
    # see if we can match the message content to a template
    # An example template may look like "Your package has been shipped. It will be delivered in {{1}} business days.
    # We want to iterate over these templates with our message body and see if we can fit it to any of the templates 
    # Then we use regex to parse the template varibles and convert them into the proper payload
    channel.message_templates.each do |template|
      next unless template["status"] == "approved"
      
      # we only care about text body object in template. if not present we discard the template
      # we don't support other forms of templates
      body_object = template["components"].find { |obj| obj["type"] == 'BODY' && obj.keys.include?("text") }
      next unless body_object.present?

      text = body_object["text"]
      # Converts the whatsapp template to a comparable regex string to check against the message content
      match_string = "^#{text.gsub(/{{\d}}/,'(.*)')}$"
      match_regex = Regexp.new match_string

      match_obj = message.content.match(match_regex)
      next unless match_obj.present?

      # we have a match, now we need to parse the template variables and convert them into the wa recommended format
      parameters = match_obj.captures.map {|x| {type: "text", text: x    }  }

      lang_code = template["language"]
      name = template["name"]
      namespace = template["namespace"]
    end
    
    # namespace present means we have a match
    message_id = channel.send_template(message.conversation.contact_inbox.source_id, name, namespace,lang_code, parameters) if namespace.present?
    message.update!(source_id: message_id) if message_id.present?
  end

  def send_on_whatsapp
    message_id = channel.send_message(message.conversation.contact_inbox.source_id, message)
    message.update!(source_id: message_id) if message_id.present?
  end
end
