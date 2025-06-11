import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import wootConstants from 'dashboard/constants/globals';

import { CMD_SNOOZE_NOTIFICATION } from 'dashboard/helper/commandbar/events';
import { ICON_SNOOZE_NOTIFICATION } from 'dashboard/helper/commandbar/icons';
import { emitter } from 'shared/helpers/mitt';

import { isAInboxViewRoute } from 'dashboard/helper/routeHelpers';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;

const createSnoozeHandler = option => () =>
  emitter.emit(CMD_SNOOZE_NOTIFICATION, option);

const INBOX_SNOOZE_EVENTS = [
  {
    id: 'snooze_notification',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_NOTIFICATION',
    icon: ICON_SNOOZE_NOTIFICATION,
    children: Object.values(SNOOZE_OPTIONS),
  },
  {
    id: SNOOZE_OPTIONS.AN_HOUR_FROM_NOW,
    title: 'COMMAND_BAR.COMMANDS.AN_HOUR_FROM_NOW',
    parent: 'snooze_notification',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
    icon: ICON_SNOOZE_NOTIFICATION,
    handler: createSnoozeHandler(SNOOZE_OPTIONS.AN_HOUR_FROM_NOW),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_TOMORROW,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_TOMORROW',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
    parent: 'snooze_notification',
    icon: ICON_SNOOZE_NOTIFICATION,
    handler: createSnoozeHandler(SNOOZE_OPTIONS.UNTIL_TOMORROW),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_NEXT_WEEK,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_WEEK',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
    parent: 'snooze_notification',
    icon: ICON_SNOOZE_NOTIFICATION,
    handler: createSnoozeHandler(SNOOZE_OPTIONS.UNTIL_NEXT_WEEK),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_NEXT_MONTH,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_MONTH',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
    parent: 'snooze_notification',
    icon: ICON_SNOOZE_NOTIFICATION,
    handler: createSnoozeHandler(SNOOZE_OPTIONS.UNTIL_NEXT_MONTH),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_CUSTOM_TIME',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
    parent: 'snooze_notification',
    icon: ICON_SNOOZE_NOTIFICATION,
    handler: createSnoozeHandler(SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME),
  },
];

export function useInboxHotKeys() {
  const { t } = useI18n();
  const route = useRoute();

  const prepareActions = actions => {
    return actions.map(action => ({
      ...action,
      title: t(action.title),
      section: action.section ? t(action.section) : undefined,
    }));
  };

  const inboxHotKeys = computed(() => {
    if (isAInboxViewRoute(route.name)) {
      return prepareActions(INBOX_SNOOZE_EVENTS);
    }
    return [];
  });

  return {
    inboxHotKeys,
  };
}
