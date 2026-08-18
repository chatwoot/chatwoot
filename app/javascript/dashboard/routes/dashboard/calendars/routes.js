import { frontendURL } from '../../../helper/URLHelper';
import CalendarView from './CalendarView.vue';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from '../../../constants/permissions.js';
import { FEATURE_FLAGS } from '../../../featureFlags';

const calendarPermissions = {
  permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
  featureFlag: FEATURE_FLAGS.CALENDAR,
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/calendars'),
    name: 'calendars_dashboard_index',
    component: CalendarView,
    meta: calendarPermissions,
  },
];
