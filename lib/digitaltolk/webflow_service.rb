class Digitaltolk::WebflowService
  attr_accessor :params, :errors

  def initialize(params)
    @params = params
    @errors = []
  end

  def perform
    if valid?
      process_webflow_submission
    else
      Rails.logger.error @errors.join(',')
    end
  rescue StandardError => e
    @errors << ['webflow_error', e.message.to_s, e.backtrace.first.to_s].join(',')
    Rails.logger.error @errors.join(',')
  end

  private

  def valid?
    @errors << "Error: webflow trigger type not supported '#{trigger_event}'" unless form_submission?

    @errors << 'blank from email' if from_email.blank?

    @errors.blank?
  end

  def valid_email?(email)
    regex = /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/
    email.match?(regex)
  end

  def process_webflow_submission
    emails.each_with_index do |recipient_email, index|
      next if recipient_email.blank?
      next unless valid_email?(recipient_email)

      second_interval = (5 * (index + 1))
      Rails.logger.warn "Sent webform email for #{from_email}"
      Rails.logger.warn email_params(recipient_email)
      DigitaltolkEmailWorker.perform_in(second_interval.seconds, email_params(recipient_email).to_json)
    end
  end

  def emails
    form_data['recipient'].to_s.split(',').map(&:strip)
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
    form_data['Email-kom'] || form_data['Email']
  end

  def subject
    'You have a new form submission on your Webflow site!'
  end

  def trigger_event
    webflow_params[:triggerType]
  end

  def form_submission?
    trigger_event.to_s.casecmp('form_submission').zero?
  end
end
