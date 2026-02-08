import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import wootConstants from 'dashboard/constants/globals';

import {
  CMD_BULK_ACTION_SNOOZE_CONVERSATION,
  CMD_BULK_ACTION_REOPEN_CONVERSATION,
  CMD_BULK_ACTION_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';
import {
  ICON_SNOOZE_CONVERSATION,
  ICON_REOPEN_CONVERSATION,
  ICON_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/icons';
import { emitter } from 'shared/helpers/mitt';

import { createSnoozeHandlers } from 'dashboard/helper/commandbar/actions';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;

const createEmitHandler = event => () => emitter.emit(event);

const SNOOZE_CONVERSATION_BULK_ACTIONS = [
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

const RESOLVED_CONVERSATION_BULK_ACTIONS = [
  {
    id: 'bulk_action_reopen_conversation',
    title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    icon: ICON_REOPEN_CONVERSATION,
    handler: createEmitHandler(CMD_BULK_ACTION_REOPEN_CONVERSATION),
  },
];

const OPEN_CONVERSATION_BULK_ACTIONS = [
  {
    id: 'bulk_action_resolve_conversation',
    title: 'COMMAND_BAR.COMMANDS.RESOLVE_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
    icon: ICON_RESOLVE_CONVERSATION,
    handler: createEmitHandler(CMD_BULK_ACTION_RESOLVE_CONVERSATION),
  },
];

export function useBulkActionsHotKeys() {
  const { t } = useI18n();

  const selectedConversations = useMapGetter(
    'bulkActions/getSelectedConversationIds'
  );

  const prepareActions = actions => {
    return actions.map(action => ({
      ...action,
      title: t(action.title),
      section: t(action.section),
    }));
  };

  const bulkActionsHotKeys = computed(() => {
    let actions = [];
    if (selectedConversations.value.length > 0) {
      actions = [
        ...SNOOZE_CONVERSATION_BULK_ACTIONS,
        ...RESOLVED_CONVERSATION_BULK_ACTIONS,
        ...OPEN_CONVERSATION_BULK_ACTIONS,
      ];
    }
    return prepareActions(actions);
  });

  return {
    bulkActionsHotKeys,
  };
}
