import contacts from './sidebarItems/contacts';
import reports from './sidebarItems/reports';
import campaigns from './sidebarItems/campaigns';
import notifications from './sidebarItems/notifications';
import primaryMenu from './sidebarItems/primaryMenu';

export const getSidebarItems = accountId => ({
  primaryMenu: primaryMenu(accountId),
  secondaryMenu: [
    contacts(accountId),
    reports(accountId),
    campaigns(accountId),
    notifications(accountId),
  ],
});
