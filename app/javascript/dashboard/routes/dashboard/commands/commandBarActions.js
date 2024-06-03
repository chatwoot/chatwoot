import wootConstants from 'dashboard/constants/globals';
import { emitter } from 'shared/helpers/mitt';

import {
  CMD_MUTE_CONVERSATION,
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_SNOOZE_CONVERSATION,
  CMD_UNMUTE_CONVERSATION,
} from './commandBarBusEvents';

import {
  ICON_MUTE_CONVERSATION,
  ICON_REOPEN_CONVERSATION,
  ICON_RESOLVE_CONVERSATION,
  ICON_SEND_TRANSCRIPT,
  ICON_SNOOZE_CONVERSATION,
  ICON_UNMUTE_CONVERSATION,
} from './CommandBarIcons';

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
  return Object.values(SNOOZE_OPTIONS).map(option => ({
    id: option,
    title: `COMMAND_BAR.COMMANDS.${option.toUpperCase()}`,
    parent: parentId,
    section: section,
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () => emitter.emit(busEventName, option),
  }));
};

export const SNOOZE_CONVERSATION_ACTIONS = [
  {
    id: 'snooze_conversation',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
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
