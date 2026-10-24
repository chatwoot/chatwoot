import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';

import { CMD_SNOOZE_NOTIFICATION } from 'dashboard/helper/commandbar/events';
import {
  createSnoozeOptions,
  localizeActions,
} from 'dashboard/helper/commandbar/actions';
import { isAInboxViewRoute } from 'dashboard/helper/routeHelpers';

const SECTION = 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION';

const SNOOZE_NOTIFICATION_ACTIONS = [
  {
    id: 'snooze_notification',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_NOTIFICATION',
    section: SECTION,
    icon: 'i-lucide-bell-off',
    scopes: ['inbox_view'],
    page: true,
    placeholder: 'COMMAND_BAR.SNOOZE_PLACEHOLDER',
  },
  ...createSnoozeOptions(
    CMD_SNOOZE_NOTIFICATION,
    'snooze_notification',
    SECTION
  ),
];

export function useInboxCommands() {
  const { t } = useI18n();
  const route = useRoute();

  const inboxCommands = computed(() =>
    isAInboxViewRoute(route.name)
      ? localizeActions(SNOOZE_NOTIFICATION_ACTIONS, t)
      : []
  );

  return { inboxCommands };
}
