import { useKbd } from 'dashboard/composables/utils/useKbd';
import wootConstants from 'dashboard/constants/globals';
import { emitter } from 'shared/helpers/mitt';

import {
  CMD_BULK_ACTION_SNOOZE_CONVERSATION,
  CMD_MUTE_CONVERSATION,
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_SNOOZE_CONVERSATION,
  CMD_SNOOZE_NOTIFICATION,
  CMD_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;
const SECTION_CONVERSATION = 'COMMAND_BAR.SECTIONS.CONVERSATION';

export const ICON_SNOOZE = 'i-lucide-alarm-clock';

const KEY_LABELS = { Slash: '/', ArrowUp: '↑', ArrowDown: '↓' };

export const shortcutKeys = binding =>
  useKbd(
    binding.split('+').map(key => KEY_LABELS[key] ?? key.replace(/^Key/, ''))
  ).value.split(' ');

const PATH_SCOPES = { reports: '/reports', settings: '/settings' };

export const pathScopes = path =>
  Object.keys(PATH_SCOPES).filter(scope => path?.includes(PATH_SCOPES[scope]));

export const localizeActions = (actions, t) =>
  actions.map(action => ({
    ...action,
    title: t(action.title),
    section: action.section && t(action.section),
    placeholder: action.placeholder && t(action.placeholder),
    shortcut: action.shortcut && shortcutKeys(action.shortcut),
  }));

// A notification is snoozed until a time, so it skips "until next reply".
export const SNOOZE_PAGES = {
  snooze_conversation: {
    event: CMD_SNOOZE_CONVERSATION,
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION',
  },
  snooze_notification: {
    event: CMD_SNOOZE_NOTIFICATION,
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
    options: Object.values(SNOOZE_OPTIONS).filter(
      option => option !== SNOOZE_OPTIONS.UNTIL_NEXT_REPLY
    ),
  },
  bulk_action_snooze_conversation: {
    event: CMD_BULK_ACTION_SNOOZE_CONVERSATION,
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
  },
};

export const createSnoozeOptions = pageId => {
  const {
    event,
    section,
    options = Object.values(SNOOZE_OPTIONS),
  } = SNOOZE_PAGES[pageId];

  return options.map(option => ({
    id: `${pageId}-${option}`,
    title: `COMMAND_BAR.COMMANDS.${option.toUpperCase()}`,
    parent: pageId,
    section,
    icon: ICON_SNOOZE,
    run: () => emitter.emit(event, option),
  }));
};

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
  ...createSnoozeOptions('snooze_conversation'),
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
