export const formatTime = unixSeconds =>
  new Intl.DateTimeFormat(undefined, {
    hour: 'numeric',
    minute: 'numeric',
  }).format(new Date(unixSeconds * 1000));

export const formatRelativeDay = (unixSeconds, { today, yesterday }) => {
  const date = new Date(unixSeconds * 1000);
  const now = new Date();
  const startOfDay = d => new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const dayDiff = Math.round(
    (startOfDay(now) - startOfDay(date)) / (24 * 60 * 60 * 1000)
  );
  if (dayDiff === 0) return today;
  if (dayDiff === 1) return yesterday;
  return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
  }).format(date);
};
