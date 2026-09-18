##############################################
# Helpers to implement date range filtering to APIs
# Include in your controller or service class where params is available
##############################################

module DateRangeHelper
  def range
    return if params[:since].blank? && params[:until].blank?

    # A single bound must not disable filtering: this used to return nil when
    # either param was missing, and every caller treats a nil range as "no
    # filter" - so an API consumer sending only `since` silently received the
    # account's full history. The missing bound defaults instead: the epoch
    # for `since`, now for `until`. Concrete bounds rather than beginless or
    # endless ranges, because report builders call range.first / range.last,
    # which raise on those.
    since = params[:since].present? ? parse_date_time(params[:since]) : DateTime.strptime('0', '%s')
    till = params[:until].present? ? parse_date_time(params[:until]) : DateTime.current

    since...till
  end

  def parse_date_time(datetime)
    return datetime if datetime.is_a?(DateTime)
    return datetime.to_datetime if datetime.is_a?(Time) || datetime.is_a?(Date)

    DateTime.strptime(datetime, '%s')
  end
end
