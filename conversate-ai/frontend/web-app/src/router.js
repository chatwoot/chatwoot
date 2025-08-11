import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from './store/auth';

// --- View Imports ---
import Login from './views/Login.vue';
import Register from './views/Register.vue';
// import Dashboard from './views/Dashboard.vue'; // To be created
// import AuthLayout from './layouts/AuthLayout.vue'; // To be created

import AuthLayout from './layouts/AuthLayout.vue';

const routes = [
  {
    path: '/login',
    name: 'login',
    component: Login,
    meta: { requiresAuth: false },
  },
  {
    path: '/register',
    name: 'register',
    component: Register,
    meta: { requiresAuth: false },
  },
  {
    path: '/',
    component: AuthLayout,
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'dashboard',
        // For now, a placeholder component
        component: { template: '<div><h1>Dashboard</h1><p>Welcome! This is the main dashboard content.</p></div>' },
      },
      {
        path: '/profile',
        name: 'profile',
        component: () => import('./views/Profile.vue'),
      },
      // Other authenticated routes go here
    ],
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

// --- Navigation Guard ---
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore();
  const requiresAuth = to.meta.requiresAuth;

  if (requiresAuth && !authStore.isAuthenticated) {
    // If route requires auth and user is not logged in, redirect to login
    next({ name: 'login' });
  } else if (!requiresAuth && authStore.isAuthenticated) {
    // If route is for guests (like login) and user is already logged in, redirect to dashboard
    next({ name: 'dashboard' });
  } else {
    // Otherwise, proceed as normal
    next();
  }
});

export default router;
