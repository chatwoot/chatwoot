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
import { emitter } from 'shared/helpers/mitt';

import { createSnoozeHandlers } from './commandBarActions';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;

export const SNOOZE_CONVERSATION_BULK_ACTIONS = [
  {
    id: 'bulk_action_snooze_conversation',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    icon: ICON_SNOOZE_CONVERSATION,
    children: Object.values(SNOOZE_OPTIONS),
  },
  ...createSnoozeHandlers(
    CMD_BULK_ACTION_SNOOZE_CONVERSATION,
    'bulk_action_snooze_conversation',
    'COMMAND_BAR.SECTIONS.BULK_ACTIONS'
  ),
];

export const RESOLVED_CONVERSATION_BULK_ACTIONS = [
  {
    id: 'bulk_action_reopen_conversation',
    title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    icon: ICON_REOPEN_CONVERSATION,
    handler: () => emitter.emit(CMD_BULK_ACTION_REOPEN_CONVERSATION),
  },
];

export const OPEN_CONVERSATION_BULK_ACTIONS = [
  {
    id: 'bulk_action_resolve_conversation',
    title: 'COMMAND_BAR.COMMANDS.RESOLVE_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    icon: ICON_RESOLVE_CONVERSATION,
    handler: () => emitter.emit(CMD_BULK_ACTION_RESOLVE_CONVERSATION),
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
