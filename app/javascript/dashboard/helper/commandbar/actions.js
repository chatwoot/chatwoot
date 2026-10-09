import wootConstants from 'dashboard/constants/globals';
import { emitter } from 'shared/helpers/mitt';
import { shortcutKeys } from 'dashboard/helper/commandbar/shortcuts';

import {
  CMD_MUTE_CONVERSATION,
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_SNOOZE_CONVERSATION,
  CMD_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;
const SECTION_CONVERSATION = 'COMMAND_BAR.SECTIONS.CONVERSATION';

export const ICON_SNOOZE = 'i-lucide-alarm-clock';

export const localizeActions = (actions, t) =>
  actions.map(action => ({
    ...action,
    title: t(action.title),
    section: action.section && t(action.section),
    placeholder: action.placeholder && t(action.placeholder),
    shortcut: action.shortcut && shortcutKeys(action.shortcut),
  }));

export const createSnoozeOptions = (busEventName, parentId, section) =>
  Object.values(SNOOZE_OPTIONS).map(option => ({
    id: `${parentId}-${option}`,
    title: `COMMAND_BAR.COMMANDS.${option.toUpperCase()}`,
    parent: parentId,
    section,
    icon: ICON_SNOOZE,
    run: () => emitter.emit(busEventName, option),
  }));

export const OPEN_CONVERSATION_ACTIONS = [
  {
    id: 'resolve_conversation',
    title: 'COMMAND_BAR.COMMANDS.RESOLVE_CONVERSATION',
    section: SECTION_CONVERSATION,
    icon: 'i-lucide-circle-check',
    shortcut: 'Alt+KeyE',
    run: () => emitter.emit(CMD_RESOLVE_CONVERSATION),
  },
];

export const SNOOZE_CONVERSATION_ACTIONS = [
  {
    id: 'snooze_conversation',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
    section: SECTION_CONVERSATION,
    icon: ICON_SNOOZE,
    shortcut: 'Alt+KeyM',
    page: true,
    placeholder: 'COMMAND_BAR.SNOOZE_PLACEHOLDER',
  },
  ...createSnoozeOptions(
    CMD_SNOOZE_CONVERSATION,
    'snooze_conversation',
    'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION'
  ),
];

export const RESOLVED_CONVERSATION_ACTIONS = [
  {
    id: 'reopen_conversation',
    title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
    section: SECTION_CONVERSATION,
    icon: 'i-lucide-rotate-ccw',
    run: () => emitter.emit(CMD_REOPEN_CONVERSATION),
  },
];

export const SEND_TRANSCRIPT_ACTION = {
  id: 'send_transcript',
  title: 'COMMAND_BAR.COMMANDS.SEND_TRANSCRIPT',
  section: SECTION_CONVERSATION,
  icon: 'i-lucide-mail-check',
  run: () => emitter.emit(CMD_SEND_TRANSCRIPT),
};

export const UNMUTE_ACTION = {
  id: 'unmute_conversation',
  title: 'COMMAND_BAR.COMMANDS.UNMUTE_CONVERSATION',
  section: SECTION_CONVERSATION,
  icon: 'i-lucide-volume-2',
  run: () => emitter.emit(CMD_UNMUTE_CONVERSATION),
};

export const MUTE_ACTION = {
  id: 'mute_conversation',
  title: 'COMMAND_BAR.COMMANDS.MUTE_CONVERSATION',
  section: SECTION_CONVERSATION,
  icon: 'i-lucide-volume-x',
  run: () => emitter.emit(CMD_MUTE_CONVERSATION),
};
