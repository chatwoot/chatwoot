import { frontendURL } from '../../../../helper/URLHelper';

const contacts = accountId => ({
  parentNav: 'contacts',
  routes: [
    'contacts_dashboard',
    'contact_profile_dashboard',
    'contacts_segments_dashboard',
    'contacts_labels_dashboard',
  ],
  menuItems: [
    {
      icon: 'contact-card-group',
      label: 'ALL_CONTACTS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/contacts`),
      toStateName: 'contacts_dashboard',
    },
  ],
});

export default contacts;
