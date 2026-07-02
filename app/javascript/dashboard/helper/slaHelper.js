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
  const slaStatuses = [];

  const dueAtByType = {
    FRT: sla.slaFrtDueAt,
    RT: sla.slaRtDueAt,
  };
  const slaTypes = ['FRT', 'NRT', 'RT'];

  events.forEach(event => {
    const type = event.eventType?.toUpperCase();
    if (!slaTypes.includes(type)) return;

    const missedAt =
      type === 'NRT' ? event.createdAt : dueAtByType[type] || event.createdAt;
    if (!missedAt) return;

    slaStatuses.push({
      type,
      threshold: missedAt - currentTime,
      icon: 'flame',
      isSlaMissed: true,
    });
  });

  const firstReplyCreatedAt = toUnixTimestamp(conversation.firstReplyCreatedAt);
  const shouldCheckFirstResponse =
    !firstReplyCreatedAt || firstReplyCreatedAt > sla.slaFrtDueAt;

  // Check FRT - until first reply is made on time
  if (sla.slaFrtDueAt && shouldCheckFirstResponse) {
    const threshold = sla.slaFrtDueAt - currentTime;
    slaStatuses.push({
      type: 'FRT',
      threshold,
      icon: threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: threshold <= 0,
    });
  }

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
  if (sla.slaRtDueAt && conversation.status !== 'resolved') {
    const threshold = sla.slaRtDueAt - currentTime;
    slaStatuses.push({
      type: 'RT',
      threshold,
      icon: threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: threshold <= 0,
    });
  }

  if (slaStatuses.length === 0) {
    return emptyStatus;
  }

  // Show existing breaches before upcoming deadlines, then pick the closest timer.
  slaStatuses.sort((a, b) => {
    if (a.isSlaMissed !== b.isSlaMissed) {
      return a.isSlaMissed ? -1 : 1;
    }

    return Math.abs(a.threshold) - Math.abs(b.threshold);
  });
  const mostUrgent = slaStatuses[0];

  return {
    type: mostUrgent.type,
    threshold: formatSLATime(mostUrgent.threshold),
    icon: mostUrgent.icon,
    isSlaMissed: mostUrgent.isSlaMissed,
  };
};
