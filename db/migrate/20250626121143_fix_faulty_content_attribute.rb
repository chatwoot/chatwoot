class FixFaultyContentAttribute < ActiveRecord::Migration[7.0]
  def change
    # This migration fixes the faulty content attribute in the Message model.
    message = Message.find_by(id: 993254)

    if message.present?
      message.update(content_attributes: {
        email: {
          bcc: nil,
          cc: nil,
          content_type: "text/plain; charset=utf-8",
          date: "2025-06-25T12:50:28+00:00",
          from: ["christin.e.johansson@skane.se"],
          html_content: {},
          text_content: {},
          in_reply_to: "01100197a720da62-7acfab37-6570-4da5-ac1f-b43381da64f8-000000@eu-north-1.amazonses.com",
          message_id: "GV3P280MB0449FF4183F8B5EE4B0368F4A67BA@GV3P280MB0449.SWEP280.PROD.OUTLOOK.COM",
          multipart: false,
          number_of_attachments: 0,
          subject: "Sv: Borttag av personal.",
          to: ["info@digitaltolk.se"]
        },
        cc_email: nil,
        bcc_email: nil
      })
    end
  end
end