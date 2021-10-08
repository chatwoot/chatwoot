import common from './sidebarItems/common';
import contacts from './sidebarItems/contacts';
import reports from './sidebarItems/reports';
import campaigns from './sidebarItems/campaigns';
import settings from './sidebarItems/settings';
import notifications from './sidebarItems/notifications';

// TODO - find hasSubMenu usage - July/2021

export const getSidebarItems = accountId => ({
  common: common(accountId),
  contacts: contacts(accountId),
  reports: reports(accountId),
  campaigns: campaigns(accountId),
  settings: settings(accountId),
  notifications: notifications(accountId),
});
