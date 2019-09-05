/* eslint no-console: 0 */
import VueRouter from 'vue-router';

import auth from '../api/auth';
import login from './login/login.routes';
import dashboard from './dashboard/dashboard.routes';
import authRoute from './auth/auth.routes';
import { frontendURL } from '../helper/URLHelper';

const routes = [
  ...login.routes,
  ...dashboard.routes,
  ...authRoute.routes,
  {
    path: '/',
    redirect: frontendURL('dashboard'),
  },
];

window.roleWiseRoutes = {
  agent: [],
  administrator: [],
};

// generateRoleWiseRoute - updates window object with agent/admin route
const generateRoleWiseRoute = route => {
  route.forEach(element => {
    if (element.children) {
      generateRoleWiseRoute(element.children);
    }
    if (element.roles) {
      element.roles.forEach(roleEl => {
        window.roleWiseRoutes[roleEl].push(element.name);
      });
    }
  });
};
// Create a object of routes
// accessible by each role.
// returns an object with roles as keys and routeArr as values
generateRoleWiseRoute(routes);

const router = new VueRouter({
  mode: 'history',
  routes, // short for routes: routes
});

const unProtectedRoutes = ['login', 'auth_signup', 'auth_reset_password'];

const authIgnoreRoutes = [
  'auth_confirmation',
  'pushBack',
  'auth_password_edit',
];

const validateAuthenticateRoutePermission = (to, from, next) => {
  const isLoggedIn = auth.isLoggedIn();
  const currentUser = auth.getCurrentUser();

  const isAnUnprotectedRoute = unProtectedRoutes.includes(to.name);
  if (isAnUnprotectedRoute && isLoggedIn) {
    return next(frontendURL('dashboard'));
  }

  const isAProtectedRoute = !unProtectedRoutes.includes(to.name);
  if (isAProtectedRoute && !isLoggedIn) {
    return next(frontendURL('login'));
  }

  if (isAProtectedRoute && isLoggedIn) {
    // Check if next route is accessible by given role
    const isAccessible = window.roleWiseRoutes[currentUser.role].includes(
      to.name
    );
    if (!isAccessible) {
      return next(frontendURL('dashboard'));
    }
  }

  return next();
};

const validateRouteAccess = (to, from, next) => {
  if (authIgnoreRoutes.includes(to.name)) {
    return next();
  }
  return validateAuthenticateRoutePermission(to, from, next);
};

// protecting routes
router.beforeEach((to, from, next) => {
  if (!to.name) {
    return next(frontendURL('dashboard'));
  }

  return validateRouteAccess(to, from, next);
});

export default router;
