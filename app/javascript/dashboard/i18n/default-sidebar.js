import common from './sidebarItems/common';
import contacts from './sidebarItems/contacts';
import reports from './sidebarItems/reports';
import campaigns from './sidebarItems/campaigns';
import settings from './sidebarItems/settings';

export const getSidebarItems = accountId => ({
  common: common(accountId),
  contacts: contacts(accountId),
  reports: reports(accountId),
  campaigns: campaigns(accountId),
  settings: settings(accountId),
});
