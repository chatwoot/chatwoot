import { mapGetters } from 'vuex';
import wootConstants from 'dashboard/constants/globals';

import {
  CMD_BULK_ACTION_SNOOZE_CONVERSATION,
  CMD_BULK_ACTION_REOPEN_CONVERSATION,
  CMD_BULK_ACTION_RESOLVE_CONVERSATION,
} from './commandBarBusEvents';
import {
  ICON_SNOOZE_CONVERSATION,
  ICON_REOPEN_CONVERSATION,
  ICON_RESOLVE_CONVERSATION,
} from './CommandBarIcons';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;

export const SNOOZE_CONVERSATION_BULK_ACTIONS = [
  {
    id: 'bulk_action_snooze_conversation',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    icon: ICON_SNOOZE_CONVERSATION,
    children: Object.values(SNOOZE_OPTIONS),
  },

  {
    id: SNOOZE_OPTIONS.UNTIL_NEXT_REPLY,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_REPLY',
    parent: 'bulk_action_snooze_conversation',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(
        CMD_BULK_ACTION_SNOOZE_CONVERSATION,
        SNOOZE_OPTIONS.UNTIL_NEXT_REPLY
      ),
  },
  {
    id: SNOOZE_OPTIONS.AN_HOUR_FROM_NOW,
    title: 'COMMAND_BAR.COMMANDS.AN_HOUR_FROM_NOW',
    parent: 'bulk_action_snooze_conversation',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(
        CMD_BULK_ACTION_SNOOZE_CONVERSATION,
        SNOOZE_OPTIONS.AN_HOUR_FROM_NOW
      ),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_TOMORROW,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_TOMORROW',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    parent: 'bulk_action_snooze_conversation',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(
        CMD_BULK_ACTION_SNOOZE_CONVERSATION,
        SNOOZE_OPTIONS.UNTIL_TOMORROW
      ),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_NEXT_WEEK,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_WEEK',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    parent: 'bulk_action_snooze_conversation',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(
        CMD_BULK_ACTION_SNOOZE_CONVERSATION,
        SNOOZE_OPTIONS.UNTIL_NEXT_WEEK
      ),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_NEXT_MONTH,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_MONTH',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    parent: 'bulk_action_snooze_conversation',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(
        CMD_BULK_ACTION_SNOOZE_CONVERSATION,
        SNOOZE_OPTIONS.UNTIL_NEXT_MONTH
      ),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME,
    title: 'COMMAND_BAR.COMMANDS.CUSTOM',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    parent: 'bulk_action_snooze_conversation',
    icon: ICON_SNOOZE_CONVERSATION,
    handler: () =>
      bus.$emit(
        CMD_BULK_ACTION_SNOOZE_CONVERSATION,
        SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME
      ),
  },
];

export const RESOLVED_CONVERSATION_BULK_ACTIONS = [
  {
    id: 'bulk_action_reopen_conversation',
    title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    icon: ICON_REOPEN_CONVERSATION,
    handler: () => bus.$emit(CMD_BULK_ACTION_REOPEN_CONVERSATION),
  },
];

export const OPEN_CONVERSATION_BULK_ACTIONS = [
  {
    id: 'bulk_action_resolve_conversation',
    title: 'COMMAND_BAR.COMMANDS.RESOLVE_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    icon: ICON_RESOLVE_CONVERSATION,
    handler: () => bus.$emit(CMD_BULK_ACTION_RESOLVE_CONVERSATION),
  },
];

export default {
  computed: {
    ...mapGetters({
      selectedConversations: 'bulkActions/getSelectedConversationIds',
    }),
    bulkActionsHotKeys() {
      let actions = [];
      if (this.selectedConversations.length > 0) {
        actions = [
          ...SNOOZE_CONVERSATION_BULK_ACTIONS,
          ...RESOLVED_CONVERSATION_BULK_ACTIONS,
          ...OPEN_CONVERSATION_BULK_ACTIONS,
        ];
      }
      return this.prepareActions(actions);
    },
  },
  watch: {
    selectedConversations() {
      this.setCommandbarData();
    },
  },
  methods: {
    prepareActions(actions) {
      return actions.map(action => ({
        ...action,
        title: this.$t(action.title),
        section: this.$t(action.section),
      }));
    },
  },
};
