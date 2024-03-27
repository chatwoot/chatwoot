module ErrorTrackable
  extend ActiveSupport::Concern

  class_methods do
    def setup_error_threshold(threshold, trigger_method, reset_on)
      class_attribute :error_threshold, :error_trigger_method

      self.error_threshold = threshold
      self.error_trigger_method = trigger_method

      return if reset_on.blank?

      after_commit :reset_error_count, on: reset_on
    end
  end

  def track_error
    ::Redis::Alfred.incr(error_count_key)
    send(error_trigger_method) if error_count >= error_threshold
    Rails.logger.info "[ErrorTrackable] Tracking error ##{error_count} for #{self.class.table_name.singularize} with id: #{id}"
  end

  def error_count
    ::Redis::Alfred.get(error_count_key).to_i
  end

  private

  def error_count_key
    format(::Redis::Alfred::ERROR_TRACKABLE_COUNT, obj_type: self.class.table_name.singularize, obj_id: id)
  end

  def reset_error_count
    Rails.logger.info "[ErrorTrackable] Reseting error count for #{self.class.table_name.singularize} with id: #{id}"
    ::Redis::Alfred.delete(error_count_key)
  end
end
