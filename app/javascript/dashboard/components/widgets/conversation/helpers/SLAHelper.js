const calculateThreshold = (timeOffset, threshold) => {
  // Calculate the time left for the SLA to breach or the time since the SLA has breached
  if (threshold === null) return null;
  const currentTime = Math.floor(Date.now() / 1000);
  return timeOffset + threshold - currentTime;
};

const getMostUrgentBreach = breaches => {
  breaches.sort((a, b) => Math.abs(a.threshold) - Math.abs(b.threshold));
  return breaches[0];
};

const calculateMinutes = time => Math.floor(time / 60);
const calculateHours = minutes => [Math.floor(minutes / 60), minutes % 60];
const calculateDays = hours => [Math.floor(hours / 24), hours % 24];
const calculateMonths = days => [Math.floor(days / 30), days % 30];
const calculateYears = months => [Math.floor(months / 12), months % 12];

// Function to format time based on the largest non-zero time component
const formatTimeComponents = (years, months, days, hours, minutes) => {
  if (years > 0) return `${years}y ${months}mo`;
  if (months > 0) return `${months}mo ${days}d`;
  if (days > 0) return `${days}d ${hours}h`;
  if (hours > 0) return `${hours}h ${minutes}m`;
  return `${minutes > 0 ? minutes : 1}m`;
};

// Format the SLA time in the format of years, months, days, hours and minutes, eg. 1y 2mo 3d 4h 5m
export const formatSLATime = time => {
  if (time < 0) return '';

  const minutes = calculateMinutes(time);
  const [hours, remainingMinutes] = calculateHours(minutes);
  const [days, remainingHours] = calculateDays(hours);
  const [months, remainingDays] = calculateMonths(days);
  const [years, remainingMonths] = calculateYears(months);

  return formatTimeComponents(
    years,
    remainingMonths,
    remainingDays,
    remainingHours,
    remainingMinutes
  );
};

const createBreach = (
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
