import wootConstants from 'dashboard/constants/globals';
import { emitter } from 'shared/helpers/mitt';

import {
  CMD_MUTE_CONVERSATION,
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_SNOOZE_CONVERSATION,
  CMD_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

import {
  ICON_MUTE_CONVERSATION,
  ICON_REOPEN_CONVERSATION,
  ICON_RESOLVE_CONVERSATION,
  ICON_SEND_TRANSCRIPT,
  ICON_SNOOZE_CONVERSATION,
  ICON_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/icons';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;

export const OPEN_CONVERSATION_ACTIONS = [
  {
    id: 'resolve_conversation',
    title: 'COMMAND_BAR.COMMANDS.RESOLVE_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
    icon: ICON_RESOLVE_CONVERSATION,
    handler: () => emitter.emit(CMD_RESOLVE_CONVERSATION),
  },
];

export const createSnoozeHandlers = (busEventName, parentId, section) => {
  // Import the helper functions inline to avoid import issues
  const LAST_CUSTOM_SNOOZE_KEY = 'chatwoot_last_custom_snooze_time';

  const getLastCustomSnoozeTime = () => {
    try {
      const stored = localStorage.getItem(LAST_CUSTOM_SNOOZE_KEY);
      if (!stored) return null;

      const data = JSON.parse(stored);
      const now = Date.now();
      const nowUnix = Math.floor(now / 1000);
      const savedAt = data.savedAt;
      const sevenDaysInMs = 7 * 24 * 60 * 60 * 1000;

      // Check if the saved time has already passed OR if it was saved more than 7 days ago
      const timeHasPassed = data.timestamp <= nowUnix;
      const tooOld = now - savedAt > sevenDaysInMs;

      if (timeHasPassed || tooOld) {
        localStorage.removeItem(LAST_CUSTOM_SNOOZE_KEY);
        return null;
      }

      return data.timestamp;
    } catch (error) {
      localStorage.removeItem(LAST_CUSTOM_SNOOZE_KEY);
      return null;
    }
  };

  const formatLastCustomSnoozeTime = () => {
    const timestamp = getLastCustomSnoozeTime();
    if (!timestamp) return null;

    try {
      const date = new Date(timestamp * 1000);

      // Format as "Sat, 23 Aug, 8.16pm"
      const dayOfWeek = date.toLocaleDateString('en-US', { weekday: 'short' });
      const day = date.getDate();
      const month = date.toLocaleDateString('en-US', { month: 'short' });

      // Format time as 8.16pm (with dots instead of colons)
      let hours = date.getHours();
      const minutes = date.getMinutes().toString().padStart(2, '0');
      const ampm = hours >= 12 ? 'pm' : 'am';

      // Convert to 12-hour format
      hours %= 12;
      if (hours === 0) hours = 12; // 12am/12pm instead of 0am/0pm

      const timeString = `${hours}.${minutes}${ampm}`;

      return `${dayOfWeek}, ${day} ${month}, ${timeString}`;
    } catch (error) {
      return null;
    }
  };

  const hasLastCustomSnoozeTime = () => {
    return getLastCustomSnoozeTime() !== null;
  };

  const availableOptions = Object.values(SNOOZE_OPTIONS);
  const snoozeOptions = availableOptions.filter(option => {
    if (option === SNOOZE_OPTIONS.UNTIL_LAST_CUSTOM_TIME) {
      return hasLastCustomSnoozeTime();
    }
    return true;
  });

  return snoozeOptions.map(option => {
    let title = `COMMAND_BAR.COMMANDS.${option.toUpperCase()}`;

    // For the last custom time option, show the formatted time instead of using translation
    if (option === SNOOZE_OPTIONS.UNTIL_LAST_CUSTOM_TIME) {
      const formattedTime = formatLastCustomSnoozeTime();
      if (formattedTime) {
        title = `Last snoozed ${formattedTime}`;
      }
    }

    return {
      id: option,
      title: title,
      parent: parentId,
      section: section,
      icon: ICON_SNOOZE_CONVERSATION,
      handler: () => emitter.emit(busEventName, option),
    };
  });
};

export const SNOOZE_CONVERSATION_ACTIONS = [
  {
    id: 'snooze_conversation',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
    icon: ICON_SNOOZE_CONVERSATION,
    children: Object.values(SNOOZE_OPTIONS),
  },
  ...createSnoozeHandlers(
    CMD_SNOOZE_CONVERSATION,
    'snooze_conversation',
    'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION'
  ),
];

export const RESOLVED_CONVERSATION_ACTIONS = [
  {
    id: 'reopen_conversation',
    title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
    icon: ICON_REOPEN_CONVERSATION,
    handler: () => emitter.emit(CMD_REOPEN_CONVERSATION),
  },
];

export const SEND_TRANSCRIPT_ACTION = {
  id: 'send_transcript',
  title: 'COMMAND_BAR.COMMANDS.SEND_TRANSCRIPT',
  section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
  icon: ICON_SEND_TRANSCRIPT,
  handler: () => emitter.emit(CMD_SEND_TRANSCRIPT),
};

export const UNMUTE_ACTION = {
  id: 'unmute_conversation',
  title: 'COMMAND_BAR.COMMANDS.UNMUTE_CONVERSATION',
  section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
  icon: ICON_UNMUTE_CONVERSATION,
  handler: () => emitter.emit(CMD_UNMUTE_CONVERSATION),
};

export const MUTE_ACTION = {
  id: 'mute_conversation',
  title: 'COMMAND_BAR.COMMANDS.MUTE_CONVERSATION',
  section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
  icon: ICON_MUTE_CONVERSATION,
  handler: () => emitter.emit(CMD_MUTE_CONVERSATION),
};
