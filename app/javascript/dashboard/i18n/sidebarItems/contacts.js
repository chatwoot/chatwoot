import { frontendURL } from '../../helper/URLHelper';

const contacts = accountId => ({
  routes: [
    'contacts_dashboard',
    'contacts_dashboard_manage',
    'contacts_labels_dashboard',
  ],
  menuItems: {
    back: {
      icon: 'ion-ios-arrow-back',
      label: 'HOME',
      hasSubMenu: false,
      toStateName: 'home',
      toState: frontendURL(`accounts/${accountId}/dashboard`),
    },
    contacts: {
      icon: 'ion-person',
      label: 'ALL_CONTACTS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/contacts`),
      toStateName: 'contacts_dashboard',
    },
  },
});

export default contacts;
