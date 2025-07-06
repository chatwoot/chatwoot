class ContactMailer < ApplicationMailer
  def liquid_droppables
    super.merge({
      meta: @meta
    })
  end

  def liquid_locals
    super.merge({ meta: @meta })
  end

  def otp_email(contact:, subject:, otp:, account:) # rubocop:disable Metrics/MethodLength
      @contact = contact
      @account = account

      @meta = {
        'otp' => otp
      }

      send_mail_with_liquid(to: contact.email, subject: subject) and return
  end

  def formatted_from_email
    "<#{from_email_address}>"
  end

  def from_email_address
    @account.support_email
  end

  def reply_to_email
    @account.support_email
  end

  def generate_message_id
    "<otp/contact/#{@contact.id}@otp.onehash.ai>"
  end
end