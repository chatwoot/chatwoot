import { frontendURL } from '../../../../helper/URLHelper';

const tickets = accountId => ({
  parentNav: 'tickets',
  routes: ['tickets_dashboard'],
  menuItems: [
    {
      icon: 'arrow-swap',
      label: 'TICKETS',
      key: 'allTickets',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/tickets`),
      toStateName: 'tickets_dashboard',
    },
  ],
});

export default tickets;
