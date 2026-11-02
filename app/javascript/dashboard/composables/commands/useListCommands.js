import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { emitter } from 'shared/helpers/mitt';
import wootConstants from 'dashboard/constants/globals';
import { ASSIGNEE_TYPE_TAB_PERMISSIONS } from 'dashboard/constants/permissions';
import { ICON_SNOOZE, commandPage } from 'dashboard/helper/commandbar/actions';
import {
  CMD_SWITCH_SORT,
  CMD_SWITCH_STATUS,
  CMD_SWITCH_TAB,
} from 'dashboard/helper/commandbar/events';
import { isAConversationRoute } from 'dashboard/helper/routeHelpers';

const SCOPES = ['list'];
const FOLDER_ROUTES = ['folder_conversations', 'conversations_through_folders'];
const ICON_TAB = 'i-lucide-layout-list';
const ICON_SORT = 'i-lucide-arrow-up-down';
const STATUS_ICONS = {
  open: 'i-lucide-circle',
  pending: 'i-lucide-clock',
  snoozed: ICON_SNOOZE,
  resolved: 'i-lucide-circle-check',
  all: 'i-lucide-list',
};

export function useListCommands() {
  const { t } = useI18n();
  const route = useRoute();
  const { checkPermissions } = usePolicy();

  const listFilters = useMapGetter('getChatListFilters');
  const status = useMapGetter('getChatStatusFilter');
  const sortBy = useMapGetter('getChatSortFilter');
  const appliedFilters = useMapGetter('getAppliedConversationFilters');

  // The list hides its tabs and status filter while advanced filters or a folder drive it.
  const hasFilters = computed(
    () => appliedFilters.value.length > 0 || FOLDER_ROUTES.includes(route.name)
  );

  const section = () => t('COMMAND_BAR.SECTIONS.LIST');
  const option = (id, title, icon, event, value) => ({
    id,
    title,
    icon,
    section: section(),
    run: () => emitter.emit(event, value),
  });

  const tabCommands = computed(() =>
    commandPage({
      id: 'switch_tab',
      title: t('COMMAND_BAR.COMMANDS.SWITCH_TAB'),
      section: section(),
      icon: ICON_TAB,
      children: Object.entries(ASSIGNEE_TYPE_TAB_PERMISSIONS)
        .filter(
          ([key, { permissions }]) =>
            key !== listFilters.value.assigneeType &&
            checkPermissions(permissions)
        )
        .map(([key]) =>
          option(
            `tab-${key}`,
            t(`CHAT_LIST.ASSIGNEE_TYPE_TABS.${key}`),
            ICON_TAB,
            CMD_SWITCH_TAB,
            key
          )
        ),
    })
  );

  const statusCommands = computed(() =>
    commandPage({
      id: 'filter_status',
      title: t('COMMAND_BAR.COMMANDS.FILTER_BY_STATUS'),
      section: section(),
      icon: 'i-lucide-filter',
      children: Object.values(wootConstants.STATUS_TYPE)
        .filter(key => key !== status.value)
        .map(key =>
          option(
            `status-${key}`,
            t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${key}.TEXT`),
            STATUS_ICONS[key],
            CMD_SWITCH_STATUS,
            key
          )
        ),
    })
  );

  const sortCommands = computed(() =>
    commandPage({
      id: 'sort_by',
      title: t('COMMAND_BAR.COMMANDS.SORT_BY'),
      section: section(),
      icon: ICON_SORT,
      children: Object.values(wootConstants.SORT_BY_TYPE)
        .filter(key => key !== sortBy.value)
        .map(key =>
          option(
            `sort-${key}`,
            t(`CHAT_LIST.SORT_ORDER_ITEMS.${key}.TEXT`),
            ICON_SORT,
            CMD_SWITCH_SORT,
            key
          )
        ),
    })
  );

  const listCommands = computed(() => {
    if (!isAConversationRoute(route.name, true)) return [];
    const commands = hasFilters.value
      ? sortCommands.value
      : [...tabCommands.value, ...statusCommands.value, ...sortCommands.value];
    return commands.map(command => ({ ...command, scopes: SCOPES }));
  });

  return { listCommands };
}
