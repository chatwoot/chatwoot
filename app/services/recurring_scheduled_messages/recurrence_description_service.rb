class RecurringScheduledMessages::RecurrenceDescriptionService
  def initialize(recurrence_rule, locale: :en)
    @rule = recurrence_rule&.with_indifferent_access || {}
    @locale = locale
  end

  def generate
    return '' if @rule.blank? || @rule[:frequency].blank?

    I18n.with_locale(@locale) do
      parts = [frequency_description]
      parts << end_description if @rule[:end_type] && @rule[:end_type] != 'never'
      parts.compact.join(' · ')
    end
  end

  private

  def frequency_description
    case @rule[:frequency]
    when 'daily' then daily_description
    when 'weekly' then weekly_description
    when 'monthly' then monthly_description
    when 'yearly' then yearly_description
    end
  end

  def daily_description
    interval = @rule[:interval] || 1
    I18n.t('recurring_scheduled_messages.description.daily', count: interval)
  end

  def weekly_description
    interval = @rule[:interval] || 1
    days = (@rule[:week_days] || []).sort.map { |d| I18n.t('date.abbr_day_names')[d] }
    prefix = I18n.t('recurring_scheduled_messages.description.weekly', count: interval)
    days.any? ? I18n.t('recurring_scheduled_messages.description.weekly_on', prefix: prefix, days: days.join(', ')) : prefix
  end

  def monthly_description
    interval = @rule[:interval] || 1
    prefix = I18n.t('recurring_scheduled_messages.description.monthly', count: interval)

    if @rule[:monthly_type] == 'day_of_week'
      ordinal = I18n.t("recurring_scheduled_messages.description.ordinals.#{ordinal_key(@rule[:monthly_week])}")
      weekday = I18n.t('date.day_names')[@rule[:monthly_weekday]] || ''
      I18n.t('recurring_scheduled_messages.description.monthly_on_weekday', prefix: prefix, ordinal: ordinal, weekday: weekday)
    else
      prefix
    end
  end

  def yearly_description
    interval = @rule[:interval] || 1
    I18n.t('recurring_scheduled_messages.description.yearly', count: interval)
  end

  def end_description
    case @rule[:end_type]
    when 'on_date'
      I18n.t('recurring_scheduled_messages.description.until_date', date: @rule[:end_date])
    when 'after_count'
      count = @rule[:end_count]
      I18n.t('recurring_scheduled_messages.description.after_count', count: count)
    end
  end

  def ordinal_key(week_number)
    { 1 => 'first', 2 => 'second', 3 => 'third', 4 => 'fourth', 5 => 'fifth', -1 => 'last' }[week_number] || 'first'
  end
end
