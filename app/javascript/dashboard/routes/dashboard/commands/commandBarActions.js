import wootConstants from 'dashboard/constants/globals';

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
    handler: () => bus.$emit(CMD_RESOLVE_CONVERSATION),
  },
];

export const SNOOZE_CONVERSATION_ACTIONS = [
  {
    id: 'snooze_conversation',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
    icon: ICON_SNOOZE_CONVERSATION,
    children: Object.values(SNOOZE_OPTIONS),
  },

  {
    id: SNOOZE_OPTIONS.UNTIL_NEXT_REPLY,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_REPLY',
    parent: 'snooze_conversation',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(CMD_SNOOZE_CONVERSATION, SNOOZE_OPTIONS.UNTIL_NEXT_REPLY),
  },
  {
    id: SNOOZE_OPTIONS.AN_HOUR_FROM_NOW,
    title: 'COMMAND_BAR.COMMANDS.AN_HOUR_FROM_NOW',
    parent: 'snooze_conversation',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(CMD_SNOOZE_CONVERSATION, SNOOZE_OPTIONS.AN_HOUR_FROM_NOW),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_TOMORROW,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_TOMORROW',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION',
    parent: 'snooze_conversation',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(CMD_SNOOZE_CONVERSATION, SNOOZE_OPTIONS.UNTIL_TOMORROW),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_NEXT_WEEK,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_WEEK',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION',
    parent: 'snooze_conversation',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(CMD_SNOOZE_CONVERSATION, SNOOZE_OPTIONS.UNTIL_NEXT_WEEK),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_NEXT_MONTH,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_MONTH',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION',
    parent: 'snooze_conversation',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(CMD_SNOOZE_CONVERSATION, SNOOZE_OPTIONS.UNTIL_NEXT_MONTH),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME,
    title: 'COMMAND_BAR.COMMANDS.CUSTOM',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION',
    parent: 'snooze_conversation',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(CMD_SNOOZE_CONVERSATION, SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME),
  },
];

export const RESOLVED_CONVERSATION_ACTIONS = [
  {
    id: 'reopen_conversation',
    title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
    icon: ICON_REOPEN_CONVERSATION,
    handler: () => bus.$emit(CMD_REOPEN_CONVERSATION),
  },
];

export const SEND_TRANSCRIPT_ACTION = {
  id: 'send_transcript',
  title: 'COMMAND_BAR.COMMANDS.SEND_TRANSCRIPT',
  section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
  icon: ICON_SEND_TRANSCRIPT,
  handler: () => bus.$emit(CMD_SEND_TRANSCRIPT),
};

export const UNMUTE_ACTION = {
  id: 'unmute_conversation',
  title: 'COMMAND_BAR.COMMANDS.UNMUTE_CONVERSATION',
  section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
  icon: ICON_UNMUTE_CONVERSATION,
  handler: () => bus.$emit(CMD_UNMUTE_CONVERSATION),
};

export const MUTE_ACTION = {
  id: 'mute_conversation',
  title: 'COMMAND_BAR.COMMANDS.MUTE_CONVERSATION',
  section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
  icon: ICON_MUTE_CONVERSATION,
  handler: () => bus.$emit(CMD_MUTE_CONVERSATION),
};
