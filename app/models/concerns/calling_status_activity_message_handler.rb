module CallingStatusActivityMessageHandler
  extend ActiveSupport::Concern

  private

  def calling_status_change_activity_content(user_name, status)
    case status
    when 'Scheduled'
      "Call was scheduled by #{user_name}"
    when 'Not Picked'
      "Call was marked as not picked by #{user_name}"
    when 'Follow-up'
      "Call was marked as follow-up by #{user_name}"
    when 'Converted'
      "Call was marked as converted by #{user_name}"
    when 'Dropped'
      "Call was marked as dropped by #{user_name}"
    end
  end
end
