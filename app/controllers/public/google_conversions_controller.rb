require 'csv'

# rubocop:disable Rails/ApplicationController
class Public::GoogleConversionsController < ActionController::Base
  HEADERS = ['Google Click ID', 'Conversion Name', 'Conversion Time', 'Conversion Value', 'Conversion Currency'].freeze

  def show
    account = Account.find_by("custom_attributes ->> 'google_feed_token' = ?", params[:token].to_s)
    return head :not_found if account.blank?

    response.headers['Cache-Control'] = 'no-store'
    send_data csv_for(account), type: 'text/csv; charset=utf-8', disposition: 'inline', filename: 'google-conversions.csv'
  end

  private

  def csv_for(account)
    CSV.generate do |csv|
      csv << ['Parameters:TimeZone=+00:00']
      csv << HEADERS
      feed_events(account).find_each do |event|
        csv << [event.gclid, event.conversion_name, formatted_time(event), formatted_value(event), formatted_currency(event)]
      end
    end
  end

  def feed_events(account)
    account.crm_google_conversion_events.ready
           .where(conversion_time: 90.days.ago..Time.current)
  end

  def formatted_time(event)
    event.conversion_time.utc.strftime('%Y-%m-%d %H:%M:%S%z')
  end

  def formatted_value(event)
    return unless event.value_cents.to_i.positive?

    format('%.2f', event.value_cents / 100.0)
  end

  def formatted_currency(event)
    event.currency if event.value_cents.to_i.positive?
  end
end
# rubocop:enable Rails/ApplicationController
