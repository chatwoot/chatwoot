import Login from './Login';
import { frontendURL } from '../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('login'),
      name: 'login',
      component: Login,
    },
  ],
};
