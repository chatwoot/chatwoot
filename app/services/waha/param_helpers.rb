module Waha::ParamHelpers
  def message_params?
    params.dig(:message, :text).present? ||
      params[:body].present? ||
      params[:caption].present?
  end

  def message_content
    params.dig(:message, :text) || params[:body] || params[:caption]
  end

  def phone_number
    return nil if params[:from].blank?

    first_item = params[:from].split.first
    first_item.split(':').first.split('@').first
  end

  def formatted_phone_number
    return nil if phone_number.blank?

    phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
  end

  def sender_full_name
    params[:pushname] || phone_number
  end

  def sender_id
    params[:sessionID]
  end

  def message_id
    params.dig(:message, :id) || sender_id
  end
end


# param contekan
# service_params = {
#       receiver: params[:phone_number],
#       token: params[:token],
#       sender: Channel::WhatsappUnofficial.extract_phone_number(params[:from]),
#       sender_name: params[:pushname],
#       message: extract_message_content(params),
#       message_id: params.dig(:message, :id) || params[:id]
#     }
#
#
# <ActionController::Parameters {"event"=>"receipt", "receipt"=>{"message_ids"=>["AC232A8442B2CA634C72FFDB050DBCD8", "AC670F7C729CEAF61AC6714AC2E10A75"], "sender"=>"62895704294498@s.whatsapp.net", "timestamp"=>"2025-09-25T08:16:08Z", "type"=>"read"}, "sessionID"=>"bi8ewbm0Fl4KEiaaEO0E18Y1WwJ3aIwJEa5OQ2t0slsQsBGj8a", "controller"=>"waha/callback", "action"=>"receive", "phone_number"=>"62895704294498", "token"=>"bi8ewbm0Fl4KEiaaEO0E18Y1WwJ3aIwJEa5OQ2t0slsQsBGj8a", "callback"=>{"event"=>"receipt", "receipt"=>{"message_ids"=>["AC232A8442B2CA634C72FFDB050DBCD8", "AC670F7C729CEAF61AC6714AC2E10A75"], "sender"=>"62895704294498@s.whatsapp.net", "timestamp"=>"2025-09-25T08:16:08Z", "type"=>"read"}, "sessionID"=>"bi8ewbm0Fl4KEiaaEO0E18Y1WwJ3aIwJEa5OQ2t0slsQsBGj8a"}} permitted: false>
#
# WAHA webhook received: #<ActionController::Parameters {"from"=>"6281295118674@s.whatsapp.net", "isFromMe"=>false, "isGroup"=>false, "message"=>{"id"=>"ACA6413E150B930ACEBA988C065AD819", "text"=>"Hallooo"}, "pushname"=>"Iwan La Udin", "sessionID"=>"bi8ewbm0Fl4KEiaaEO0E18Y1WwJ3aIwJEa5OQ2t0slsQsBGj8a", "timestamp"=>"2025-09-25T08:25:36Z", "controller"=>"waha/callback", "action"=>"receive", "phone_number"=>"62895704294498", "token"=>"bi8ewbm0Fl4KEiaaEO0E18Y1WwJ3aIwJEa5OQ2t0slsQsBGj8a", "callback"=>{"from"=>"6281295118674@s.whatsapp.net", "isFromMe"=>false, "isGroup"=>false, "message"=>{"id"=>"ACA6413E150B930ACEBA988C065AD819", "text"=>"Hallooo"}, "pushname"=>"Iwan La Udin", "sessionID"=>"bi8ewbm0Fl4KEiaaEO0E18Y1WwJ3aIwJEa5OQ2t0slsQsBGj8a", "timestamp"=>"2025-09-25T08:25:36Z"}} permitted: false>

# Parameters: {"edited_text"=>"Hallooox", "from"=>"6281295118674@s.whatsapp.net", "isFromMe"=>false, "isGroup"=>false, "message"=>{"id"=>"ACB57CC02B90446D6551E8EE38D61333"}, "pushname"=>"Iwan La Udin", "sessionID"=>"bi8ewbm0Fl4KEiaaEO0E18Y1WwJ3aIwJEa5OQ2t0slsQsBGj8a", "timestamp"=>"2025-09-25T10:34:51Z", "phone_number"=>"62895704294498", "waha"=>{"action"=>"process_payload", "edited_text"=>"Hallooox", "from"=>"6281295118674@s.whatsapp.net", "isFromMe"=>false, "isGroup"=>false, "message"=>{"id"=>"ACB57CC02B90446D6551E8EE38D61333"}, "pushname"=>"Iwan La Udin", "sessionID"=>"bi8ewbm0Fl4KEiaaEO0E18Y1WwJ3aIwJEa5OQ2t0slsQsBGj8a", "timestamp"=>"2025-09-25T10:34:51Z"}}
#
# Parameters: {"edited_text"=>"Hallooo woiiii xxxx", "from"=>"6281295118674@s.whatsapp.net", "isFromMe"=>false, "isGroup"=>false, "message"=>{"id"=>"AC1C2EF12BD052A585DEF86455BCCB1E"}, "pushname"=>"Iwan La Udin", "sessionID"=>"bi8ewbm0Fl4KEiaaEO0E18Y1WwJ3aIwJEa5OQ2t0slsQsBGj8a", "timestamp"=>"2025-09-25T10:59:49Z", "phone_number"=>"62895704294498", "waha"=>{"action"=>"process_payload", "edited_text"=>"Hallooo woiiii xxxx", "from"=>"6281295118674@s.whatsapp.net", "isFromMe"=>false, "isGroup"=>false, "message"=>{"id"=>"AC1C2EF12BD052A585DEF86455BCCB1E"}, "pushname"=>"Iwan La Udin", "sessionID"=>"bi8ewbm0Fl4KEiaaEO0E18Y1WwJ3aIwJEa5OQ2t0slsQsBGj8a", "timestamp"=>"2025-09-25T10:59:49Z"}}
#
# {"from"=>"6281212471316@s.whatsapp.net in 6282234557461-1555909785@g.us", "from_lid"=>"229080855261321@lid", "isFromMe"=>false, "isGroup"=>true, "message"=>{"id"=>"F8752ABA02E0849AD44702FC35D459C1"}, "pushname"=>"sutan stefan", "sessionID"=>"QDJxDf9aBuVq3eSd9jTU971uPr9dBx5BozMpD4w5FGLPqIDgef", "timestamp"=>"2025-09-25T11:35:12Z", "phone_number"=>"6282338532327", "token"=>"[FILTERED]", "callback"=>{"from"=>"6281212471316@s.whatsapp.net in 6282234557461-1555909785@g.us", "from_lid"=>"229080855261321@lid", "isFromMe"=>false, "isGroup"=>true, "message"=>{"id"=>"F8752ABA02E0849AD44702FC35D459C1"}, "pushname"=>"sutan stefan", "sessionID"=>"QDJxDf9aBuVq3eSd9jTU971uPr9dBx5BozMpD4w5FGLPqIDgef", "timestamp"=>"2025-09-25T11:35:12Z"}}
#
#
# Performing Webhooks::WahaEventsJob (Job ID: 431c027b-3919-458b-885e-81eeb14ebb9f) from Sidekiq(default) enqueued at 2025-09-25T12:55:38Z with arguments: {"from"=>"6281233403059:43@s.whatsapp.net in 6281233403059@s.whatsapp.net", "isFromMe"=>false, "isGroup"=>false, "message"=>{"id"=>"3EB0F5C31C9C236BD29E7B", "text"=>"halo bro"}, "pushname"=>"Fandi~", "sessionID"=>"HzylEGTGikGJ10ZhadfbzWOtD7WhSzMwERxkZ2r50oC7SJ5o8x", "timestamp"=>"2025-09-25T12:55:37Z", "controller"=>"webhooks/waha", "action"=>"process_payload", "phone_number"=>"6281295118674", "waha"=>{"from"=>"6281233403059:43@s.whatsapp.net in 6281233403059@s.whatsapp.net", "isFromMe"=>false, "isGroup"=>false, "message"=>{"id"=>"3EB0F5C31C9C236BD29E7B", "text"=>"halo bro"}, "pushname"=>"Fandi~", "sessionID"=>"HzylEGTGikGJ10ZhadfbzWOtD7WhSzMwERxkZ2r50oC7SJ5o8x", "timestamp"=>"2025-09-25T12:55:37Z"}}
# 
#{"from"=>"6281295118674@s.whatsapp.net", "isFromMe"=>true, "isGroup"=>false, "message"=>{"id"=>"ACFA1B58BB325771F4A0B7A1CB54A4A6"}, "sessionID"=>"YPNxAZpk1db8HeczLEbYpQSKitZF29awawYg6gAhLqiWGA5yw3", "timestamp"=>"2025-09-26T16:25:44Z", "phone_number"=>"6281295118674", "waha"=>{"from"=>"6281295118674@s.whatsapp.net", "isFromMe"=>true, "isGroup"=>false, "message"=>{"id"=>"ACFA1B58BB325771F4A0B7A1CB54A4A6"}, "sessionID"=>"YPNxAZpk1db8HeczLEbYpQSKitZF29awawYg6gAhLqiWGA5yw3", "timestamp"=>"2025-09-26T16:25:44Z"}}