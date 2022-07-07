import Login from './Login';
import { frontendURL } from '../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('login'),
      name: 'login',
      component: Login,
      props: route => ({
        config: route.query.config,
        email: route.query.email,
        ssoAuthToken: route.query.sso_auth_token,
        redirectUrl: route.query.route_url,
        ssoAccountId: route.query.sso_account_id,
      }),
    },
  ],
};
