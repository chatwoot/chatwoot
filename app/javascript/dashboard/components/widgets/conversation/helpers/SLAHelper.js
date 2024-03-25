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

  let formattedTime;

  if (years > 0) {
    formattedTime = `${years}y ${remainingMonths}mo`;
  } else if (months > 0) {
    formattedTime = `${months}mo ${remainingDays}d`;
  } else if (days > 0) {
    formattedTime = `${days}d ${remainingHours}h`;
  } else if (hours > 0) {
    formattedTime = `${hours}h ${remainingMinutes}m`;
  } else {
    formattedTime = remainingMinutes === 0 ? '1m' : `${remainingMinutes}m`;
  }
  return formattedTime;
};

export const createBreach = (
  type,
  {
    first_response_time_threshold,
    next_response_time_threshold,
    resolution_time_threshold,
  } = {},
  {
    first_reply_created_at: firstReplyCreatedAt,
    waiting_since: waitingSince,
    created_at: createdAt,
    status,
  } = {}
) => {
  // Mapping of breach types to their logic
  const breachTypes = {
    FRT: {
      threshold: calculateThreshold(createdAt, first_response_time_threshold),
      //   Check FRT only if threshold is not null and first reply hasn't been made
      condition:
        first_response_time_threshold !== null &&
        (!firstReplyCreatedAt || firstReplyCreatedAt === 0),
    },
    NRT: {
      threshold: calculateThreshold(waitingSince, next_response_time_threshold),
      // Check NRT only if threshold is not null, first reply has been made and we are waiting since
      condition:
        next_response_time_threshold !== null &&
        !!firstReplyCreatedAt &&
        !!waitingSince,
    },
    RT: {
      threshold: calculateThreshold(createdAt, resolution_time_threshold),
      // Check RT only if the conversation is open and threshold is not null
      condition: status === 'open' && resolution_time_threshold !== null,
    },
  };

  const breach = breachTypes[type];
  return breach ? { ...breach, type } : null;
};

export const evaluateSLAStatus = (sla, chat) => {
  if (!sla || !chat)
    return { type: '', threshold: '', icon: '', isSlaMissed: false };

  const breachTypes = ['FRT', 'NRT', 'RT'];
  // Filter out the breaches and create the object
  const breaches = breachTypes
    .map(type => createBreach(type, sla, chat))
    .filter(breach => breach && breach.condition)
    .map(breach => ({
      ...breach,
      icon: breach.threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: breach.threshold <= 0,
    }));

  // Return the most urgent breach or the nearest to breach
  const mostUrgent = getMostUrgentBreach(breaches);
  return mostUrgent
    ? {
        type: mostUrgent.type,
        threshold: formatSLATime(
          mostUrgent.threshold <= 0
            ? -mostUrgent.threshold
            : mostUrgent.threshold
        ),
        icon: mostUrgent.icon,
        isSlaMissed: mostUrgent.isSlaMissed,
      }
    : { type: '', threshold: '', icon: '', isSlaMissed: false };
};
