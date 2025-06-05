import { FEATURE_FLAGS } from '../../../featureFlags';
import { getPortalRoute } from './helpers/routeHelper';

import HelpCenterPageRouteView from './pages/HelpCenterPageRouteView.vue';

import PortalsIndex from './pages/PortalsIndexPage.vue';
import PortalsNew from './pages/PortalsNewPage.vue';

const PortalsArticlesIndexPage = () =>
  import('./pages/PortalsArticlesIndexPage.vue');
const PortalsArticlesNewPage = () =>
  import('./pages/PortalsArticlesNewPage.vue');
const PortalsArticlesEditPage = () =>
  import('./pages/PortalsArticlesEditPage.vue');

const PortalsCategoriesIndexPage = () =>
  import('./pages/PortalsCategoriesIndexPage.vue');

const PortalsLocalesIndexPage = () =>
  import('./pages/PortalsLocalesIndexPage.vue');

const PortalsSettingsIndexPage = () =>
  import('./pages/PortalsSettingsIndexPage.vue');

const meta = {
  featureFlag: FEATURE_FLAGS.HELP_CENTER,
  permissions: ['administrator', 'agent', 'knowledge_base_manage'],
};
const portalRoutes = [
  {
    path: getPortalRoute(':portalSlug/:locale/:categorySlug?/articles/:tab?'),
    name: 'portals_articles_index',
    meta,
    component: PortalsArticlesIndexPage,
  },
  {
    path: getPortalRoute(':portalSlug/:locale/:categorySlug?/articles/new'),
    name: 'portals_articles_new',
    meta,
    component: PortalsArticlesNewPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/:categorySlug?/articles/:tab?/edit/:articleSlug'
    ),
    name: 'portals_articles_edit',
    meta,
    component: PortalsArticlesEditPage,
  },

  {
    path: getPortalRoute(':portalSlug/:locale/categories'),
    name: 'portals_categories_index',
    meta,
    component: PortalsCategoriesIndexPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/categories/:categorySlug/articles'
    ),
    name: 'portals_categories_articles_index',
    meta,
    component: PortalsArticlesIndexPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/categories/:categorySlug/articles/:articleSlug'
    ),
    name: 'portals_categories_articles_edit',
    meta,
    component: PortalsArticlesEditPage,
  },
  {
    path: getPortalRoute(':portalSlug/locales'),
    name: 'portals_locales_index',
    meta,
    component: PortalsLocalesIndexPage,
  },
  {
    path: getPortalRoute(':portalSlug/settings'),
    name: 'portals_settings_index',
    meta,
    component: PortalsSettingsIndexPage,
  },
  {
    path: getPortalRoute('new'),
    name: 'portals_new',
    meta: {
      featureFlag: FEATURE_FLAGS.HELP_CENTER,
      permissions: ['administrator', 'knowledge_base_manage'],
    },
    component: PortalsNew,
  },
  {
    path: getPortalRoute(':navigationPath'),
    name: 'portals_index',
    meta: {
      featureFlag: FEATURE_FLAGS.HELP_CENTER,
      permissions: ['administrator', 'knowledge_base_manage'],
    },
    component: PortalsIndex,
  },
];

export default {
  routes: [
    {
      path: getPortalRoute(),
      component: HelpCenterPageRouteView,
      redirect: to => {
        return {
          name: 'portals_index',
          params: {
            navigationPath: 'portals_articles_index',
            ...to.params,
          },
        };
      },
      children: [...portalRoutes],
    },
  ],
};
