// Shared helpers for voice call UI

export const normalizeStatus = status => {
  const map = {
    queued: 'ringing',
    initiated: 'ringing',
    ringing: 'ringing',
    'in-progress': 'in_progress',
    active: 'in_progress',
    completed: 'ended',
    ended: 'ended',
    missed: 'missed',
    busy: 'no_answer',
    failed: 'no_answer',
    'no-answer': 'no_answer',
    canceled: 'no_answer',
  };
  return map[status] || status;
};

export const isInbound = (direction, fallbackMessageType) => {
  if (direction) return direction === 'inbound';
  // messageType 0 is incoming in older structures
  return fallbackMessageType === 0;
};

