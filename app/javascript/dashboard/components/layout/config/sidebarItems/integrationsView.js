import { frontendURL } from '../../../../helper/URLHelper';

const integrationsView = accountId => ({
  parentNav: 'integrations_view',
  routes: [
    'integrations_view',
    'integrations_details_view',
    'integrations_corrupted_contacts',
  ],
  menuItems: [
    {
      icon: 'order',
      label: 'ALL_ORDERS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/integrations-view`),
      toStateName: 'integrations_view',
    },
    {
      icon: 'book-contacts',
      label: 'CORRUPTED_CONTACTS',
      hasSubMenu: false,
      toState: frontendURL(
        `accounts/${accountId}/integrations-view/corrupted/list`
      ),
      toStateName: 'integrations_corrupted_contacts',
    },
  ],
});

export default integrationsView;
