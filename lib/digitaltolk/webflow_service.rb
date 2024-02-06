class Digitaltolk::WebflowService
  attr_accessor :params
  
  INFO_EMAIL = 'info@digitaltolk.se'
  WEBFORM_EMAIL = 'webformular@digitaltolk.se'

  def initialize(params)
    @params = params
  end

  def perform
    # temporary disable
    return false

    unless form_submission?
      Rails.logger.error "Error: webflow trigger type not supported '#{trigger_event}'"
      return
    end

    process_webflow_submission
  rescue StandardError => e
    Rails.logger.error e
    Rails.logger.error e.backtrace.first
  end

  private

  def process_webflow_submission
    if from_email.blank?
      Rails.logger.error 'blank from email'
      return
    end

    emails.each_with_index do |recipient_email, index|
      next if recipient_email.blank?

      second_interval = (10 * (index + 1))
      Rails.logger.info "Sent webform email for #{from_email}"
      DigitaltolkEmailWorker.perform_in(second_interval.seconds, email_params(recipient_email).to_json)
    end
  end

  def emails
    [INFO_EMAIL, WEBFORM_EMAIL]
  end

  def webflow_params
    @params.dig(:params, :webflow)
  end

  def email_params(to)
    {
      'to': to,
      'from': from_email,
      'subject': subject,
      'data': form_data,
      'form_name': form_name
    }
  end

  def form_data
    webflow_params.dig(:payload, :data)
  end

  def form_name
    webflow_params.dig(:payload, :name)
  end

  def from_email
    form_data.dig('Email-kom')
  end

  def subject
    'You have a new form submission on your Webflow site!'
  end

  def trigger_event
    webflow_params.dig(:triggerType)
  end

  def form_submission?
    trigger_event.to_s.downcase == 'form_submission'
  end

  # def test_webhook_data
  #   data = {
  #     "params": {
  #       "triggerType": "form_submission",
  #       "payload": {
  #         "name": "Info kontakt", 
  #         "siteId": "6476e981f6a8eff9068d9af2", 
  #         "data": {
  #           "Name-kom": "Test JM", 
  #           "Email-kom": "jmanuel.derecho@gmail.com", 
  #           "phone-kom": "", 
  #           "Bok．nr．": "#3364311", 
  #           "Subject": "Mejl för tolk", 
  #           "Meddelande": "Hej! Har bokat tolk men ser inte tolkens mejladress någonstans. Behöver den för att skicka video länk."
  #         }, 
  #         "submittedAt": "2024-02-01T15:35:45.897Z", 
  #         "id": "65bbba510f02b427c7024707", 
  #         "formId": "64dd32123cda9a590ffbf718"
  #     }, 
  #     "controller": "webhooks/webflow", 
  #     "action": "process_payload", 
  #     "webflow": {
  #       "triggerType": "form_submission", 
  #       "payload": {
  #         "name": "Info kontakt", 
  #         "siteId": "6476e981f6a8eff9068d9af2",
  #         "data": {
  #           "Name-kom": "Test JM", 
  #           "Email-kom": "jmanuel.derecho@gmail.com", 
  #           "phone-kom": "", 
  #           "Bok．nr．": "#3364311", 
  #           "Subject": "Mejl för tolk", 
  #           "Meddelande": "Hej! Har bokat tolk men ser inte tolkens mejladress någonstans. Behöver den för att skicka video länk."
  #         }, 
  #         "submittedAt": "2024-02-01T15:35:45.897Z", 
  #         "id": "65bbba510f02b427c7024707", 
  #         "formId": "64dd32123cda9a590ffbf718"
  #        }
  #      }
  #    }
  #   }

  #   ActionController::Parameters.new(data)
  # end
end