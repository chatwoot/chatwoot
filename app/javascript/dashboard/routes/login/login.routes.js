import Login from './Login';
import OAuthCallback from './OAuthCallback';
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
        ssoAccountId: route.query.sso_account_id,
        ssoConversationId: route.query.sso_conversation_id,
      }),
    },
    {
      path: frontendURL('oauth-callback/:provider'),
      name: 'oauth-callback',
      component: OAuthCallback,
    },
  ],
};
