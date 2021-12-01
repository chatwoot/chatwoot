import { frontendURL } from '../../helper/URLHelper';

const contacts = accountId => ({
  routes: [
    'contacts_dashboard',
    'contact_profile_dashboard',
    'contacts_labels_dashboard',
  ],
  menuItems: {
    back: {
      icon: 'chevron-left',
      label: 'HOME',
      hasSubMenu: false,
      toStateName: 'home',
      toState: frontendURL(`accounts/${accountId}/dashboard`),
    },
    contacts: {
      icon: 'contact-card-group',
      label: 'ALL_CONTACTS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/contacts`),
      toStateName: 'contacts_dashboard',
    },
  },
});

export default contacts;
