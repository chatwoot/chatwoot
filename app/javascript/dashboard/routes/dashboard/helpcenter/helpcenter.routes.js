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

const portalRoutes = [
  {
    path: getPortalRoute(':portalSlug/:locale/:categorySlug?/articles/:tab?'),
    name: 'portals_articles_index',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalsArticlesIndexPage,
  },
  {
    path: getPortalRoute(':portalSlug/:locale/:categorySlug?/articles/new'),
    name: 'portals_articles_new',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalsArticlesNewPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/:categorySlug?/articles/:tab?/edit/:articleSlug'
    ),
    name: 'portals_articles_edit',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalsArticlesEditPage,
  },

  {
    path: getPortalRoute(':portalSlug/:locale/categories'),
    name: 'portals_categories_index',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalsCategoriesIndexPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/categories/:categorySlug/articles'
    ),
    name: 'portals_categories_articles_index',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalsArticlesIndexPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/categories/:categorySlug/articles/:articleSlug'
    ),
    name: 'portals_categories_articles_edit',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalsArticlesEditPage,
  },
  {
    path: getPortalRoute(':portalSlug/locales'),
    name: 'portals_locales_index',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalsLocalesIndexPage,
  },
  {
    path: getPortalRoute(':portalSlug/settings'),
    name: 'portals_settings_index',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalsSettingsIndexPage,
  },
  {
    path: getPortalRoute('new'),
    name: 'portals_new',
    meta: {
      permissions: ['administrator', 'knowledge_base_manage'],
    },
    component: PortalsNew,
  },
  {
    path: getPortalRoute(':navigationPath'),
    name: 'portals_index',
    meta: {
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
      children: [...portalRoutes],
    },
  ],
};
