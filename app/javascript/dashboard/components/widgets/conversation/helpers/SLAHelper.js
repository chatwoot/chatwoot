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
    {
      type: 'FRT',
      threshold: calculateThreshold(createdAt, first_response_time_threshold),
      //   Check FRT only if threshold is not null and first reply hasn't been made
      condition:
        first_response_time_threshold !== null &&
        (!firstReplyCreatedAt || firstReplyCreatedAt === 0),
    },
    {
      type: 'NRT',
      threshold: calculateThreshold(waitingSince, next_response_time_threshold),
      // Check NRT only if threshold is not null, first reply has been made and we are waiting since
      condition:
        next_response_time_threshold !== null &&
        firstReplyCreatedAt &&
        waitingSince,
    },
    {
      type: 'RT',
      threshold: calculateThreshold(createdAt, resolution_time_threshold),
      // Check RT only if the conversation is open and threshold is not null
      condition: status === 'open' && resolution_time_threshold !== null,
    },
  ];

  // Filter out the breaches that are not applicable
  // and map the breaches to add icon and isSlaMissed properties
  breaches = breaches
    .filter(breach => breach.condition)
    .map(breach => ({
      ...breach,
      icon: breach.threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: breach.threshold <= 0,
    }));

  // Return the most urgent breach or the nearest to breach
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

  // If all SLA metrics are met or not applicable
  return { type: '', threshold: '', icon: '', isSlaMissed: false };
};
