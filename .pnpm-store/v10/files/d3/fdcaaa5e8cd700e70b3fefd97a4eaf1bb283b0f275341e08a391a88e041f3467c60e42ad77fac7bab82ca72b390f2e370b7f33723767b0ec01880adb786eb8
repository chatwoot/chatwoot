import { Conversation } from './types/conversation';
import { AppliedSla, SLAStatus } from './types/sla';

/**
 * Calculates the threshold for an SLA based on the current time and the provided threshold.
 * @param timeOffset - The time offset in seconds.
 * @param threshold - The threshold in seconds or null if not applicable.
 * @returns The calculated threshold in seconds or null if the threshold is null.
 */
const calculateThreshold = (
  timeOffset: number,
  threshold: number | null
): number | null => {
  // Calculate the time left for the SLA to breach or the time since the SLA has missed
  if (threshold === null) return null;
  const currentTime = Math.floor(Date.now() / 1000);
  return timeOffset + threshold - currentTime;
};

/**
 * Finds the most urgent SLA status based on the threshold.
 * @param SLAStatuses - An array of SLAStatus objects.
 * @returns The most urgent SLAStatus object.
 */
const findMostUrgentSLAStatus = (SLAStatuses: SLAStatus[]): SLAStatus => {
  // Sort the SLAs based on the threshold and return the most urgent SLA
  SLAStatuses.sort(
    (sla1, sla2) => Math.abs(sla1.threshold) - Math.abs(sla2.threshold)
  );
  return SLAStatuses[0];
};

/**
 * Formats the SLA time in a human-readable format.
 * @param seconds - The time in seconds.
 * @returns A formatted string representing the time.
 */
const formatSLATime = (seconds: number): string => {
  const units: { [key: string]: number } = {
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
  const parts: string[] = [];

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

/**
 * Creates an SLA object based on the type, applied SLA, and chat details.
 * @param type - The type of SLA (FRT, NRT, RT).
 * @param appliedSla - The applied SLA details.
 * @param chat - The chat details.
 * @returns An object containing the SLA status or null if conditions are not met.
 */
const createSLAObject = (
  type: string,
  appliedSla: AppliedSla,
  chat: Conversation
): { threshold: number | null; type: string; condition: boolean } | null => {
  const {
    sla_first_response_time_threshold: frtThreshold,
    sla_next_response_time_threshold: nrtThreshold,
    sla_resolution_time_threshold: rtThreshold,
    created_at: createdAt,
  } = appliedSla;

  const {
    first_reply_created_at: firstReplyCreatedAt,
    waiting_since: waitingSince,
    status,
  } = chat;

  const SLATypes: {
    [key: string]: { threshold: number | null; condition: boolean };
  } = {
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

/**
 * Evaluates SLA conditions and returns an array of SLAStatus objects.
 * @param appliedSla - The applied SLA details.
 * @param chat - The chat details.
 * @returns An array of SLAStatus objects.
 */
const evaluateSLAConditions = (
  appliedSla: AppliedSla,
  chat: Conversation
): {
  threshold: number;
  type: string;
  icon: string;
  isSlaMissed: boolean;
}[] => {
  // Filter out the SLA based on conditions and update the object with the breach status(icon, isSlaMissed)
  const SLATypes = ['FRT', 'NRT', 'RT'];
  return SLATypes.map(type => createSLAObject(type, appliedSla, chat))
    .filter(
      (
        SLAStatus
      ): SLAStatus is { threshold: number; type: string; condition: boolean } =>
        !!SLAStatus && SLAStatus.condition
    )
    .map(SLAStatus => ({
      ...SLAStatus,
      icon: SLAStatus.threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: SLAStatus.threshold <= 0,
    }));
};

/**
 * Evaluates the SLA status for a given chat and applied SLA.
 * @param {Object} params - The parameters object.
 * @param params.appliedSla - The applied SLA details.
 * @param params.chat - The chat details.
 * @returns An object containing the most urgent SLA status.
 */
export const evaluateSLAStatus = ({
  appliedSla,
  chat,
}: {
  appliedSla: AppliedSla;
  chat: Conversation;
}): { type: string; threshold: string; icon: string; isSlaMissed: boolean } => {
  if (!appliedSla || !chat)
    return { type: '', threshold: '', icon: '', isSlaMissed: false };

  // Filter out the SLA and create the object for each breach
  const SLAStatuses = evaluateSLAConditions(appliedSla, chat) as SLAStatus[];

  // Return the most urgent SLA which is latest to breach or has missed
  const mostUrgent = findMostUrgentSLAStatus(SLAStatuses);
  return mostUrgent
    ? {
        type: mostUrgent?.type,
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
