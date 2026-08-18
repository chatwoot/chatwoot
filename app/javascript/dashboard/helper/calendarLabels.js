const EMAIL_LIKE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function connectionDisplayName(connection, t) {
  return (
    connection?.name ||
    connection?.connected_by?.name ||
    t('SIDEBAR.CALENDAR_PAGE.GOOGLE_ACCOUNT')
  );
}

export function calendarDisplayName(calendar, t) {
  const summary = (calendar?.summary || '').trim();
  if (!summary || EMAIL_LIKE.test(summary)) {
    return calendar?.primary
      ? t('SIDEBAR.CALENDAR_PAGE.PRIMARY_CALENDAR')
      : t('SIDEBAR.CALENDAR_PAGE.UNNAMED_CALENDAR');
  }
  return summary;
}

export function connectionSelectOptions(connections, t) {
  return connections.map(item => ({
    value: String(item.id),
    label: connectionDisplayName(item, t),
  }));
}

export function calendarSelectOptions(calendars, t) {
  return calendars.map(item => ({
    value: item.id,
    label: calendarDisplayName(item, t),
  }));
}
