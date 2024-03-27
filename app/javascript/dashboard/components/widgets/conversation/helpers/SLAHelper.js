import { format } from 'date-fns';

const calculateThreshold = (timeOffset, threshold) => {
  // Calculate the time left for the SLA to breach or the time since the SLA has breached
  if (threshold === null) return null;
  const currentTime = Math.floor(Date.now() / 1000);
  return timeOffset + threshold - currentTime;
};

const calculateMissedSLATime = threshold => {
  // Since the threshold is negative (indicating the SLA has been breached),
  // convert it to positive to get the time since the breach in milliseconds.
  const breachTimeInMs = Date.now() + threshold * 1000;
  // breachTimeInMs represents the correct past time of the breach.
  return format(new Date(breachTimeInMs), 'PP'); // Format the date in the format of 'Month DD, YYYY'
};

const findMostUrgentSLAStatus = SLAStatuses => {
  // Sort the SLAs based on the threshold and return the most urgent SLA
  SLAStatuses.sort((a, b) => Math.abs(a.threshold) - Math.abs(b.threshold));
  return SLAStatuses[0];
};

const convertToMinutes = time => Math.floor(time / 60);
const convertToHoursAndMinutes = minutes => [
  Math.floor(minutes / 60),
  minutes % 60,
];
const convertToDaysAndHours = hours => [Math.floor(hours / 24), hours % 24];
const convertToMonthsAndDays = days => [Math.floor(days / 30), days % 30];
const convertToYearsAndMonths = months => [
  Math.floor(months / 12),
  months % 12,
];

const formatTime = (value, label, nextValue, nextLabel) => {
  if (value > 0) return `${value}${label} ${nextValue}${nextLabel}`;
  return null;
};

const formatDuration = (years, months, days, hours, minutes) => {
  return (
    formatTime(years, 'y', months, 'mo') ||
    formatTime(months, 'mo', days, 'd') ||
    formatTime(days, 'd', hours, 'h') ||
    formatTime(hours, 'h', minutes, 'm') ||
    `${minutes > 0 ? minutes : 1}m`
  );
};

// Format the SLA time in the format of years, months, days, hours and minutes, eg. 1y 2mo 3d 4h 5m
export const formatSLATime = time => {
  if (time < 0) return '';

  const minutes = convertToMinutes(time);
  const [hours, remainingMinutes] = convertToHoursAndMinutes(minutes);
  const [days, remainingHours] = convertToDaysAndHours(hours);
  const [months, remainingDays] = convertToMonthsAndDays(days);
  const [years, remainingMonths] = convertToYearsAndMonths(months);

  return formatDuration(
    years,
    remainingMonths,
    remainingDays,
    remainingHours,
    remainingMinutes
  );
};

const createSLAObject = (
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
  const SLATypes = {
    FRT: {
      threshold: calculateThreshold(createdAt, first_response_time_threshold),
      //   Check FRT only if threshold is not null and first reply hasn't been made
      condition:
        first_response_time_threshold !== null &&
        (!firstReplyCreatedAt || firstReplyCreatedAt === 0),
    },
    NRT: {
      threshold: calculateThreshold(
        waitingSince || createdAt,
        next_response_time_threshold
      ),
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

  const SLAStatus = SLATypes[type];
  if (SLAStatus && SLAStatus.threshold <= 0) {
    return {
      ...SLAStatus,
      type,
      missedSLATime: calculateMissedSLATime(SLAStatus.threshold),
    };
  }
  return SLAStatus ? { ...SLAStatus, type } : null;
};

const evaluateSLAConditions = (sla, chat) => {
  // Filter out the SLA based on conditions and update the object with the breach status(icon, isSlaMissed)
  const SLATypes = ['FRT', 'NRT', 'RT'];
  return SLATypes.map(type => createSLAObject(type, sla, chat))
    .filter(SLAStatus => SLAStatus && SLAStatus.condition)
    .map(SLAStatus => ({
      ...SLAStatus,
      icon: SLAStatus.threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: SLAStatus.threshold <= 0,
    }));
};

export const evaluateSLAStatus = (sla, chat) => {
  if (!sla || !chat)
    return { type: '', threshold: '', icon: '', isSlaMissed: false };

  // Filter out the SLA and create the object for each breach
  const SLAStatuses = evaluateSLAConditions(sla, chat);

  // Return the most urgent SLA which is latest to breach or has breached
  const mostUrgent = findMostUrgentSLAStatus(SLAStatuses);
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

export const allMissedSLAs = (sla, chat) => {
  if (!sla || !chat) return false;

  const SLAThresholdMap = {
    FRT: 'first_response_time_threshold',
    NRT: 'next_response_time_threshold',
    RT: 'resolution_time_threshold',
  };

  // Filter out SLA types that do not exist in the 'sla' parameter
  const validSLATypes = Object.keys(SLAThresholdMap).filter(
    type => sla[SLAThresholdMap[type]] !== null
  );

  // Filter out the SLA and create the object for each breach and return only the breached SLAs
  return validSLATypes
    .map(type => createSLAObject(type, sla, chat))
    .filter(SLAStatus => SLAStatus && SLAStatus.threshold <= 0);
};
