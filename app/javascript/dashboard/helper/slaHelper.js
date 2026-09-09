import { useCamelCase } from 'dashboard/composables/useTransformKeys';

/**
 * Formats seconds into a human-readable time string
 * @param {number} seconds - The time in seconds (can be negative for overdue)
 * @returns {string} Formatted time string like "2h 30m" or "1d 4h"
 */
const formatSLATime = seconds => {
  const absSeconds = Math.abs(seconds);

  const units = {
    y: 31536000,
    mo: 2592000,
    d: 86400,
    h: 3600,
    m: 60,
  };

  if (absSeconds < 60) {
    return '1m';
  }

  const parts = [];
  let remaining = absSeconds;

  Object.entries(units).forEach(([unit, value]) => {
    if (parts.length >= 2) return;
    const count = Math.floor(remaining / value);
    if (count > 0) {
      parts.push(`${count}${unit}`);
      remaining -= count * value;
    }
  });

  return parts.join(' ');
};

const toUnixTimestamp = value => {
  if (!value || typeof value === 'number') return value;

  const numericValue = Number(value);
  if (!Number.isNaN(numericValue)) return numericValue;

  const parsedTimestamp = Date.parse(value);
  return Number.isNaN(parsedTimestamp)
    ? value
    : Math.floor(parsedTimestamp / 1000);
};

const isTerminalSLAStatus = status => ['hit', 'missed'].includes(status);

const isSLACompleted = (sla, conversation) => {
  return (
    isTerminalSLAStatus(sla.slaStatus) || conversation.status === 'resolved'
  );
};

export const shouldRefreshSLAStatus = ({ appliedSla, chat }) => {
  if (!appliedSla || !chat) return false;

  return !isSLACompleted(useCamelCase(appliedSla), useCamelCase(chat));
};

/**
 * Evaluates SLA status using backend-computed due times
 * @param {Object} params - Parameters object
 * @param {Object} params.appliedSla - The applied SLA with due_at timestamps
 * @param {Object} params.chat - The conversation object
 * @param {Array} params.slaEvents - Recorded SLA miss events for this conversation
 * @returns {Object} SLA status with type, threshold, icon, and isSlaMissed
 */
export const evaluateSLAStatus = ({ appliedSla, chat, slaEvents = [] }) => {
  const emptyStatus = { type: '', threshold: '', icon: '', isSlaMissed: false };

  if (!appliedSla || !chat) {
    return emptyStatus;
  }

  const sla = useCamelCase(appliedSla);
  const conversation = useCamelCase(chat);
  const events = useCamelCase(slaEvents || []);
  const currentTime = Math.floor(Date.now() / 1000);
  const isCompleted = isSLACompleted(sla, conversation);
  const completionTime = isCompleted
    ? toUnixTimestamp(sla.slaCompletedAt)
    : null;
  const evaluationTime = completionTime || (isCompleted ? null : currentTime);
  const slaStatuses = [];

  const dueAtByType = {
    FRT: sla.slaFrtDueAt,
    RT: sla.slaRtDueAt,
  };
  const slaTypes = ['FRT', 'NRT', 'RT'];
  const firstReplyCreatedAt = toUnixTimestamp(conversation.firstReplyCreatedAt);
  const shouldCheckFirstResponse =
    !firstReplyCreatedAt || firstReplyCreatedAt > sla.slaFrtDueAt;

  events.forEach(event => {
    const type = event.eventType?.toUpperCase();
    if (!slaTypes.includes(type)) return;

    const missedAt =
      type === 'NRT' ? event.createdAt : dueAtByType[type] || event.createdAt;
    if (!missedAt) return;

    slaStatuses.push({
      type,
      threshold: evaluationTime ? missedAt - evaluationTime : null,
      icon: 'flame',
      isSlaMissed: true,
    });
  });

  const hasRecordedFirstResponseMiss = events.some(
    event => event.eventType?.toUpperCase() === 'FRT'
  );
  const completedFirstResponseEvaluationTime =
    completionTime &&
    !isTerminalSLAStatus(sla.slaStatus) &&
    !hasRecordedFirstResponseMiss &&
    sla.slaFrtDueAt <= completionTime
      ? completionTime
      : null;
  const firstResponseEvaluationTime = isCompleted
    ? completedFirstResponseEvaluationTime
    : currentTime;

  // Check FRT until the first reply is made on time. When resolution reaches
  // the client before SLA processing, use completion time to preserve the miss.
  if (
    sla.slaFrtDueAt &&
    shouldCheckFirstResponse &&
    firstResponseEvaluationTime
  ) {
    const threshold = sla.slaFrtDueAt - firstResponseEvaluationTime;
    slaStatuses.push({
      type: 'FRT',
      threshold,
      icon: threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: threshold <= 0,
    });
  }

  if (!isCompleted) {
    // Check NRT - only if first reply made and waiting for response
    if (sla.slaNrtDueAt && firstReplyCreatedAt && conversation.waitingSince) {
      const threshold = sla.slaNrtDueAt - currentTime;
      slaStatuses.push({
        type: 'NRT',
        threshold,
        icon: threshold <= 0 ? 'flame' : 'alarm',
        isSlaMissed: threshold <= 0,
      });
    }

    // Check RT - only if conversation is unresolved
    if (sla.slaRtDueAt) {
      const threshold = sla.slaRtDueAt - currentTime;
      slaStatuses.push({
        type: 'RT',
        threshold,
        icon: threshold <= 0 ? 'flame' : 'alarm',
        isSlaMissed: threshold <= 0,
      });
    }
  }

  if (slaStatuses.length === 0) {
    return emptyStatus;
  }

  // Show existing breaches before upcoming deadlines, then pick the closest timer.
  slaStatuses.sort((a, b) => {
    if (a.isSlaMissed !== b.isSlaMissed) {
      return a.isSlaMissed ? -1 : 1;
    }

    if (a.threshold === null || b.threshold === null) {
      if (a.threshold === b.threshold) return 0;
      return a.threshold === null ? -1 : 1;
    }

    return Math.abs(a.threshold) - Math.abs(b.threshold);
  });
  const mostUrgent = slaStatuses[0];

  return {
    type: mostUrgent.type,
    threshold:
      mostUrgent.threshold === null ? '' : formatSLATime(mostUrgent.threshold),
    icon: mostUrgent.icon,
    isSlaMissed: mostUrgent.isSlaMissed,
  };
};
