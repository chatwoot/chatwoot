export function calculateThreshold(timeOffset, threshold) {
  // Calculate the time left for the SLA to breach or the time since the SLA has breached
  if (threshold === null) return null;
  const currentTime = Math.floor(Date.now() / 1000);
  return timeOffset + threshold - currentTime;
}

export const getMostUrgentBreach = breaches => {
  breaches.sort((a, b) => Math.abs(a.threshold) - Math.abs(b.threshold));
  return breaches[0];
};

export const formatSLATime = time => {
  if (time < 0) return '';

  const minutes = Math.floor(time / 60);
  const [hours, remainingMinutes] = [Math.floor(minutes / 60), minutes % 60];
  const [days, remainingHours] = [Math.floor(hours / 24), hours % 24];
  const [months, remainingDays] = [Math.floor(days / 30), days % 30];
  const [years, remainingMonths] = [Math.floor(months / 12), months % 12];

  // Determine the largest unit of time to display based on provided seconds
  if (years > 0) return `${years}y ${remainingMonths}mo`;
  if (months > 0) return `${months}mo ${remainingDays}d`;
  if (days > 0) return `${days}d ${remainingHours}h`;
  if (hours > 0) return `${hours}h ${remainingMinutes}m`;
  return remainingMinutes === 0 ? '1m' : `${remainingMinutes}m`;
};

export const createBreach = (type, timeOffset, threshold, condition) => ({
  type,
  threshold: calculateThreshold(timeOffset, threshold),
  condition,
});

export const processBreaches = breaches =>
  breaches
    .filter(breach => breach.condition)
    .map(breach => ({
      ...breach,
      icon: breach.threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: breach.threshold <= 0,
    }));

export const evaluateSLAStatus = (sla, chat) => {
  if (!sla || !chat)
    return { type: '', threshold: '', icon: '', isSlaMissed: false };

  const {
    first_response_time_threshold,
    next_response_time_threshold,
    resolution_time_threshold,
  } = sla || {};

  const {
    first_reply_created_at: firstReplyCreatedAt,
    waiting_since: waitingSince,
    created_at: createdAt,
    status,
  } = chat || {};

  let breaches = [
    //   Check FRT only if threshold is not null and first reply hasn't been made
    createBreach(
      'FRT',
      createdAt,
      first_response_time_threshold,
      first_response_time_threshold !== null &&
        (!firstReplyCreatedAt || firstReplyCreatedAt === 0)
    ),
    // Check NRT only if threshold is not null, first reply has been made and we are waiting since
    createBreach(
      'NRT',
      waitingSince,
      next_response_time_threshold,
      next_response_time_threshold !== null &&
        firstReplyCreatedAt &&
        waitingSince
    ),
    // Check RT only if the conversation is open and threshold is not null
    createBreach(
      'RT',
      createdAt,
      resolution_time_threshold,
      status === 'open' && resolution_time_threshold !== null
    ),
  ];

  breaches = processBreaches(breaches);

  if (breaches.length > 0) {
    const mostUrgent = getMostUrgentBreach(breaches);
    if (mostUrgent) {
      return {
        type: mostUrgent.type,
        threshold:
          mostUrgent.threshold <= 0
            ? formatSLATime(-mostUrgent.threshold)
            : formatSLATime(mostUrgent.threshold),
        icon: mostUrgent.icon,
        isSlaMissed: mostUrgent.isSlaMissed,
      };
    }
  }

  return { type: '', threshold: '', icon: '', isSlaMissed: false };
};
