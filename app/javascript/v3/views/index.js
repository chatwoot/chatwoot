import VueRouter from 'vue-router';

import routes from './routes';
import AnalyticsHelper from 'dashboard/helper/AnalyticsHelper';
import { validateRouteAccess } from '../helpers/RouteHelper';

export const router = new VueRouter({ mode: 'history', routes });

export const initalizeRouter = () => {
  router.beforeEach((to, _, next) => {
    AnalyticsHelper.page(to.name || '', {
      path: to.path,
      name: to.name,
    });

    return validateRouteAccess(to, next, window.chatwootConfig);
  });
};

export default router;
