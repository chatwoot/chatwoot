import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { emitter } from 'shared/helpers/mitt';

import {
  CMD_BULK_ACTION_SNOOZE_CONVERSATION,
  CMD_BULK_ACTION_REOPEN_CONVERSATION,
  CMD_BULK_ACTION_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';
import {
  ICON_SNOOZE,
  createSnoozeOptions,
  localizeActions,
} from 'dashboard/helper/commandbar/actions';

const SECTION = 'COMMAND_BAR.SECTIONS.BULK_ACTIONS';
const SCOPES = ['bulk'];

const BULK_ACTIONS = [
  {
    id: 'bulk_action_snooze_conversation',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
    section: SECTION,
    icon: ICON_SNOOZE,
    scopes: SCOPES,
    page: true,
    placeholder: 'COMMAND_BAR.SNOOZE_PLACEHOLDER',
  },
  ...createSnoozeOptions(
    CMD_BULK_ACTION_SNOOZE_CONVERSATION,
    'bulk_action_snooze_conversation',
    SECTION
  ),
  {
    id: 'bulk_action_reopen_conversation',
    title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
    section: SECTION,
    icon: 'i-lucide-rotate-ccw',
    scopes: SCOPES,
    run: () => emitter.emit(CMD_BULK_ACTION_REOPEN_CONVERSATION),
  },
  {
    id: 'bulk_action_resolve_conversation',
    title: 'COMMAND_BAR.COMMANDS.RESOLVE_CONVERSATION',
    section: SECTION,
    icon: 'i-lucide-circle-check',
    scopes: SCOPES,
    run: () => emitter.emit(CMD_BULK_ACTION_RESOLVE_CONVERSATION),
  },
];

export function useBulkActionCommands() {
  const { t } = useI18n();
  const selectedConversations = useMapGetter(
    'bulkActions/getSelectedConversationIds'
  );

  const bulkActionCommands = computed(() =>
    selectedConversations.value.length ? localizeActions(BULK_ACTIONS, t) : []
  );

  return { bulkActionCommands };
}
