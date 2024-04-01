class Reports::TimeFormatPresenter
  include ActionView::Helpers::TextHelper

  attr_reader :seconds

  def initialize(seconds)
    @seconds = seconds.to_i
  end

  def format
    return '--' if seconds.nil? || seconds.zero?

    days, remainder = seconds.divmod(86_400)
    hours, remainder = remainder.divmod(3600)
    minutes, seconds = remainder.divmod(60)

    format_components(days: days, hours: hours, minutes: minutes, seconds: seconds)
  end

  private

  def format_components(components)
    formatted_components = components.filter_map do |unit, value|
      next if value.zero?

      I18n.t("time_units.#{unit}", count: value)
    end

    return I18n.t('time_units.seconds', count: 0) if formatted_components.empty?

    formatted_components.first(2).join(' ')
  end
end
