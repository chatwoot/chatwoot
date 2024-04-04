const calculateThreshold = (timeOffset, threshold) => {
  // Calculate the time left for the SLA to breach or the time since the SLA has missed
  if (threshold === null) return null;
  const currentTime = Math.floor(Date.now() / 1000);
  return timeOffset + threshold - currentTime;
};

const findMostUrgentSLAStatus = SLAStatuses => {
  // Sort the SLAs based on the threshold and return the most urgent SLA
  SLAStatuses.sort(
    (sla1, sla2) => Math.abs(sla1.threshold) - Math.abs(sla2.threshold)
  );
  return SLAStatuses[0];
};

const formatSLATime = seconds => {
  const units = {
    y: 31536000, // 60 * 60 * 24 * 365
    mo: 2592000, // 60 * 60 * 24 * 30
    d: 86400, // 60 * 60 * 24
    h: 3600, // 60 * 60
    m: 60,
  };

  if (seconds < 60) {
    return '1m';
  }

  // we will only show two parts, two max granularity's, h-m, y-d, d-h, m, but no seconds
  const parts = [];

  Object.keys(units).forEach(unit => {
    const value = Math.floor(seconds / units[unit]);
    if (seconds < 60 && parts.length > 0) return;
    if (parts.length === 2) return;
    if (value > 0) {
      parts.push(value + unit);
      seconds -= value * units[unit];
    }
  });
  return parts.join(' ');
};

const createSLAObject = (
  type,
  {
    sla_first_response_time_threshold: frtThreshold,
    sla_next_response_time_threshold: nrtThreshold,
    sla_resolution_time_threshold: rtThreshold,
    created_at: createdAt,
  } = {},
  {
    first_reply_created_at: firstReplyCreatedAt,
    waiting_since: waitingSince,
    status,
  } = {}
) => {
  // Mapping of breach types to their logic
  const SLATypes = {
    FRT: {
      threshold: calculateThreshold(createdAt, frtThreshold),
      //   Check FRT only if threshold is not null and first reply hasn't been made
      condition:
        frtThreshold !== null &&
        (!firstReplyCreatedAt || firstReplyCreatedAt === 0),
    },
    NRT: {
      threshold: calculateThreshold(waitingSince, nrtThreshold),
      // Check NRT only if threshold is not null, first reply has been made and we are waiting since
      condition:
        nrtThreshold !== null && !!firstReplyCreatedAt && !!waitingSince,
    },
    RT: {
      threshold: calculateThreshold(createdAt, rtThreshold),
      // Check RT only if the conversation is open and threshold is not null
      condition: status === 'open' && rtThreshold !== null,
    },
  };

  const SLAStatus = SLATypes[type];
  return SLAStatus ? { ...SLAStatus, type } : null;
};

const evaluateSLAConditions = (appliedSla, chat) => {
  // Filter out the SLA based on conditions and update the object with the breach status(icon, isSlaMissed)
  const SLATypes = ['FRT', 'NRT', 'RT'];
  return SLATypes.map(type => createSLAObject(type, appliedSla, chat))
    .filter(SLAStatus => SLAStatus && SLAStatus.condition)
    .map(SLAStatus => ({
      ...SLAStatus,
      icon: SLAStatus.threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: SLAStatus.threshold <= 0,
    }));
};

export const evaluateSLAStatus = (appliedSla, chat) => {
  if (!appliedSla || !chat)
    return { type: '', threshold: '', icon: '', isSlaMissed: false };

  // Filter out the SLA and create the object for each breach
  const SLAStatuses = evaluateSLAConditions(appliedSla, chat);

  // Return the most urgent SLA which is latest to breach or has missed
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
