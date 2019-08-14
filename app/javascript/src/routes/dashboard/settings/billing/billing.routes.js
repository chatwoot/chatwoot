import Index from './Index';
import SettingsContent from '../Wrapper';
import AccountLocked from './AccountLocked';

export default {
  routes: [
    {
      path: '/u/settings/billing',
      component: SettingsContent,
      props: {
        headerTitle: 'BILLING.HEADER',
        icon: 'ion-card',
      },
      children: [
        {
          path: '',
          name: 'billing',
          component: Index,
          roles: ['administrator'],
          props: route => ({ state: route.query.state }),
        },
      ],
    },
    {
      path: '/deactivated',
      name: 'billing_deactivated',
      component: AccountLocked,
      roles: ['agent'],
    },
  ],
};
