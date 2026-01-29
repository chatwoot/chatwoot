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

/**
 * Evaluates SLA status using backend-computed due times
 * @param {Object} params - Parameters object
 * @param {Object} params.appliedSla - The applied SLA with due_at timestamps
 * @param {Object} params.chat - The conversation object
 * @returns {Object} SLA status with type, threshold, icon, and isSlaMissed
 */
export const evaluateSLAStatus = ({ appliedSla, chat }) => {
  const emptyStatus = { type: '', threshold: '', icon: '', isSlaMissed: false };

  if (!appliedSla || !chat) {
    return emptyStatus;
  }

  const currentTime = Math.floor(Date.now() / 1000);
  const slaStatuses = [];

  // Check FRT - only if first reply hasn't been made
  const frtDueAt = appliedSla.sla_frt_due_at || appliedSla.slaFrtDueAt;
  const firstReplyCreatedAt =
    chat.first_reply_created_at || chat.firstReplyCreatedAt;

  if (frtDueAt && !firstReplyCreatedAt) {
    const threshold = frtDueAt - currentTime;
    slaStatuses.push({
      type: 'FRT',
      threshold,
      icon: threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: threshold <= 0,
    });
  }

  // Check NRT - only if first reply made and waiting for response
  const nrtDueAt = appliedSla.sla_nrt_due_at || appliedSla.slaNrtDueAt;
  const waitingSince = chat.waiting_since || chat.waitingSince;

  if (nrtDueAt && firstReplyCreatedAt && waitingSince) {
    const threshold = nrtDueAt - currentTime;
    slaStatuses.push({
      type: 'NRT',
      threshold,
      icon: threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: threshold <= 0,
    });
  }

  // Check RT - only if conversation is open
  const rtDueAt = appliedSla.sla_rt_due_at || appliedSla.slaRtDueAt;
  const status = chat.status;

  if (rtDueAt && status === 'open') {
    const threshold = rtDueAt - currentTime;
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

  // Find most urgent (smallest absolute threshold)
  slaStatuses.sort((a, b) => Math.abs(a.threshold) - Math.abs(b.threshold));
  const mostUrgent = slaStatuses[0];

  return {
    type: mostUrgent.type,
    threshold: formatSLATime(mostUrgent.threshold),
    icon: mostUrgent.icon,
    isSlaMissed: mostUrgent.isSlaMissed,
  };
};
