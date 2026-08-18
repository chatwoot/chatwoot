class Api::V1::Accounts::Conversations::CalendarEventsController < Api::V1::Accounts::Conversations::BaseController
  def index
    render json: { payload: Integrations::GoogleCalendar::EventService.conversation_payloads(@conversation) }
  end
end
