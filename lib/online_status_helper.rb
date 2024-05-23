module OnlineStatusHelper
  private

  def calculate_time_for_status(user_logs, status_value)
    last_status = nil
    last_time = nil
    total_time = 0

    user_logs.each do |log|
      changes = extract_availability_changes(log)
      next unless changes

      current_status = changes[1]

      # the time calculated here is between when desired status is the current status and when it changes to another status
      total_time += calculate_time_difference(last_status, status_value, last_time, log.created_at)

      last_status, last_time = update_last_status_and_time(current_status, status_value, log.created_at, last_status)
    end

    # calculate the remaining time when last status is the desired status
    total_time += calculate_remaining_time(last_status, status_value, last_time)
    total_time
  end

  def extract_availability_changes(log)
    log.audited_changes['availability']
  end

  def calculate_time_difference(last_status, status_value, last_time, current_time)
    last_status == status_value && last_time ? current_time - last_time : 0
  end

  def update_last_status_and_time(current_status, status_value, current_time, _last_status)
    if current_status == status_value
      [current_status, current_time]
    else
      [current_status, nil]
    end
  end

  def calculate_remaining_time(last_status, status_value, last_time)
    last_status == status_value && last_time ? Time.current - last_time : 0
  end
end
