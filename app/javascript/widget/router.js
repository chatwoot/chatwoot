import { createRouter, createWebHashHistory } from 'vue-router';
import ViewWithHeader from './components/layouts/ViewWithHeader.vue';
import store from './store';

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: '/unread-messages',
      name: 'unread-messages',
      component: () => import('./views/UnreadMessages.vue'),
    },
    {
      path: '/campaigns',
      name: 'campaigns',
      component: () => import('./views/Campaigns.vue'),
    },
    {
      path: '/',
      component: ViewWithHeader,
      children: [
        {
          path: '',
          name: 'home',
          component: () => import('./views/Home.vue'),
        },
        {
          path: '/prechat-form',
          name: 'prechat-form',
          component: () => import('./views/PreChatForm.vue'),
        },
        {
          path: '/messages',
          name: 'messages',
          component: () => import('./views/Messages.vue'),
        },
        {
          path: '/sms-form',
          name: 'sms-form',
          component: () => import('./views/SmsForm.vue'),
        },
        {
          path: '/terms-and-conditions',
          name: 'terms-and-conditions',
          component: () => import('./views/TermsAndConditions.vue'),
        },
        {
          path: '/article',
          name: 'article-viewer',
          component: () => import('./views/ArticleViewer.vue'),
        },
      ],
    },
  ],
});

/**
 * Navigation Guards to Handle Route Transitions
 *
 * Purpose:
 * Prevents duplicate form submissions and API calls during route transitions,
 * especially important in high-latency scenarios.
 *
 * Flow:
 * 1. beforeEach: Sets isUpdatingRoute to true at start of navigation
 * 2. Component buttons/actions check this flag to prevent duplicate actions
 * 3. afterEach: Resets the flag once navigation is complete
 *
 * Implementation note:
 * Handling it globally, so that we can use it across all components
 * to ensure consistent UI behavior during all route transitions.
 *
 * @see https://github.com/chatwoot/chatwoot/issues/10736
 */

router.beforeEach(async (to, from, next) => {
  // Prevent any user interactions during route transition
  await store.dispatch('appConfig/setRouteTransitionState', true);

  // If opening for SMS, redirect home/messages to SMS form immediately
  if (window.$chatwoot?.openingForSms) {
    if (to.name === 'home' || to.name === 'messages') {
      next({ name: 'sms-form' });
      return;
    }
    if (to.name === 'sms-form') {
      next();
      return;
    }
  }

  // Skip home page and redirect directly to messages page
  // But only if not opening for SMS
  if (to.name === 'home' && !window.$chatwoot?.openingForSms) {
    next({ name: 'messages' });
    return;
  }

  next();
});

router.afterEach(() => {
  // Re-enable user interactions after navigation is complete
  store.dispatch('appConfig/setRouteTransitionState', false);
});

export default router;
