import wootConstants from 'dashboard/constants/globals';

import { CMD_SNOOZE_NOTIFICATION } from './commandBarBusEvents';
import { ICON_SNOOZE_NOTIFICATION } from './CommandBarIcons';
import { emitter } from 'shared/helpers/mitt';

import { isAInboxViewRoute } from 'dashboard/helper/routeHelpers';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;

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
    handler: () =>
      emitter.emit(CMD_SNOOZE_NOTIFICATION, SNOOZE_OPTIONS.AN_HOUR_FROM_NOW),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_TOMORROW,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_TOMORROW',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
    parent: 'snooze_notification',
    icon: ICON_SNOOZE_NOTIFICATION,
    handler: () =>
      emitter.emit(CMD_SNOOZE_NOTIFICATION, SNOOZE_OPTIONS.UNTIL_TOMORROW),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_NEXT_WEEK,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_WEEK',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
    parent: 'snooze_notification',
    icon: ICON_SNOOZE_NOTIFICATION,
    handler: () =>
      emitter.emit(CMD_SNOOZE_NOTIFICATION, SNOOZE_OPTIONS.UNTIL_NEXT_WEEK),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_NEXT_MONTH,
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_MONTH',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
    parent: 'snooze_notification',
    icon: ICON_SNOOZE_NOTIFICATION,
    handler: () =>
      emitter.emit(CMD_SNOOZE_NOTIFICATION, SNOOZE_OPTIONS.UNTIL_NEXT_MONTH),
  },
  {
    id: SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME,
    title: 'COMMAND_BAR.COMMANDS.CUSTOM',
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
    parent: 'snooze_notification',
    icon: ICON_SNOOZE_NOTIFICATION,
    handler: () =>
      emitter.emit(CMD_SNOOZE_NOTIFICATION, SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME),
  },
];
export default {
  computed: {
    inboxHotKeys() {
      if (isAInboxViewRoute(this.$route.name)) {
        return this.prepareActions(INBOX_SNOOZE_EVENTS);
      }
      return [];
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
