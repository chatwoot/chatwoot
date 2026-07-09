import {
  VOICE_CALL_STATUS,
  VOICE_CALL_DIRECTION,
} from 'dashboard/components-next/message/constants';

export const CALL_KIND = {
  ONGOING: 'ongoing',
  INCOMING: 'incoming',
  OUTGOING: 'outgoing',
  MISSED: 'missed',
  NO_REPLY: 'no_reply',
  FAILED: 'failed',
};

// The API returns display values: status (ringing/in-progress/completed/
// no-answer/failed) and direction (inbound/outbound). The list UI presents
// them as a single "kind" per row.
export const getCallKind = call => {
  if (
    [VOICE_CALL_STATUS.RINGING, VOICE_CALL_STATUS.IN_PROGRESS].includes(
      call.status
    )
  ) {
    return CALL_KIND.ONGOING;
  }
  if (
    [VOICE_CALL_STATUS.FAILED, VOICE_CALL_STATUS.REJECTED].includes(call.status)
  ) {
    return CALL_KIND.FAILED;
  }
  const isInbound = call.direction === VOICE_CALL_DIRECTION.INBOUND;
  if (call.status === VOICE_CALL_STATUS.NO_ANSWER) {
    return isInbound ? CALL_KIND.MISSED : CALL_KIND.NO_REPLY;
  }
  return isInbound ? CALL_KIND.INCOMING : CALL_KIND.OUTGOING;
};

// Filter chips map to the status/direction params supported by CallFinder.
export const CALL_ACTIVITY_PARAMS = {
  missed: {
    status: VOICE_CALL_STATUS.NO_ANSWER,
    direction: VOICE_CALL_DIRECTION.INBOUND,
  },
  no_reply: {
    status: VOICE_CALL_STATUS.NO_ANSWER,
    direction: VOICE_CALL_DIRECTION.OUTBOUND,
  },
  incoming: { direction: VOICE_CALL_DIRECTION.INBOUND },
  outgoing: { direction: VOICE_CALL_DIRECTION.OUTBOUND },
  in_progress: { status: VOICE_CALL_STATUS.IN_PROGRESS },
};
