import { frontendURL } from 'dashboard/helper/URLHelper';

const Login = () => import('./login/Index.vue');
const Signup = () => import('./auth/signup/Index.vue');
const ResetPassword = () => import('./auth/reset/password/Index.vue');
const Confirmation = () => import('./auth/confirmation/Index.vue');
const PasswordEdit = () => import('./auth/password/Edit.vue');

export default [
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
      authError: route.query.error,
    }),
  },
  {
    path: frontendURL('auth/signup'),
    name: 'auth_signup',
    component: Signup,
    meta: { requireSignupEnabled: true },
  },
  {
    path: frontendURL('auth/confirmation'),
    name: 'auth_confirmation',
    component: Confirmation,
    meta: { ignoreSession: true },
    props: route => ({
      config: route.query.config,
      confirmationToken: route.query.confirmation_token,
      redirectUrl: route.query.route_url,
    }),
  },
  {
    path: frontendURL('auth/password/edit'),
    name: 'auth_password_edit',
    component: PasswordEdit,
    meta: { ignoreSession: true },
    props: route => ({
      config: route.query.config,
      resetPasswordToken: route.query.reset_password_token,
      redirectUrl: route.query.route_url,
    }),
  },
  {
    path: frontendURL('auth/reset/password'),
    name: 'auth_reset_password',
    component: ResetPassword,
  },
];
