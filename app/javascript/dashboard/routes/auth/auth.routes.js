import Auth from './Auth.vue';
import Confirmation from './Confirmation.vue';
import Signup from './Signup.vue';
import PasswordEdit from './PasswordEdit.vue';
import ResetPassword from './ResetPassword.vue';
import { frontendURL } from '../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('auth'),
      name: 'auth',
      component: Auth,
      children: [
        {
          path: 'confirmation',
          name: 'auth_confirmation',
          component: Confirmation,
          props: route => ({
            config: route.query.config,
            confirmationToken: route.query.confirmation_token,
            redirectUrl: route.query.route_url,
          }),
        },
        {
          path: 'password/edit',
          name: 'auth_password_edit',
          component: PasswordEdit,
          props: route => ({
            config: route.query.config,
            resetPasswordToken: route.query.reset_password_token,
            redirectUrl: route.query.route_url,
          }),
        },
        {
          path: 'signup',
          name: 'auth_signup',
          component: Signup,
          meta: { requireSignupEnabled: true },
        },
        {
          path: 'reset/password',
          name: 'auth_reset_password',
          component: ResetPassword,
        },
      ],
    },
  ],
};
