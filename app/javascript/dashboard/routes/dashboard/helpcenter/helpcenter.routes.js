import HelpCenterLayout from './components/HelpCenterLayout.vue';
import { getPortalRoute } from './helpers/routeHelper';

const PortalIndex = () => import('./pages/PortalIndexPage.vue');

const PortalArticlesIndexPage = () =>
  import('./pages/PortalArticlesIndexPage.vue');
const PortalArticlesNewPage = () => import('./pages/PortalArticlesNewPage.vue');
const PortalArticlesEditPage = () =>
  import('./pages/PortalArticlesEditPage.vue');

const PortalCategoriesIndexPage = () =>
  import('./pages/PortalCategoriesIndexPage.vue');

const PortalLocalesIndexPage = () =>
  import('./pages/PortalLocalesIndexPage.vue');

const PortalSettingsIndexPage = () =>
  import('./pages/PortalSettingsIndexPage.vue');

const portalRoutes = [
  {
    path: getPortalRoute(':navigationPath'),
    name: 'portal_index',
    meta: {
      permissions: ['administrator', 'knowledge_base_manage'],
    },
    component: PortalIndex,
  },

  {
    path: getPortalRoute(':portalSlug/:locale/:categorySlug?/articles/:tab?'),
    name: 'portal_articles_index',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalArticlesIndexPage,
  },
  {
    path: getPortalRoute(':portalSlug/:locale/articles/new'),
    name: 'portal_articles_new',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalArticlesNewPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/:categorySlug?/articles/:tab?/edit/:articleSlug'
    ),
    name: 'portal_articles_edit',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalArticlesEditPage,
  },

  {
    path: getPortalRoute(':portalSlug/:locale/categories'),
    name: 'portal_categories_index',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalCategoriesIndexPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/categories/:categorySlug/articles'
    ),
    name: 'portal_categories_articles_index',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalArticlesIndexPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/categories/:categorySlug/articles/:articleSlug'
    ),
    name: 'portal_categories_articles_edit',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalArticlesEditPage,
  },
  {
    path: getPortalRoute(':portalSlug/locales'),
    name: 'portal_locales_index',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalLocalesIndexPage,
  },
  {
    path: getPortalRoute(':portalSlug/settings'),
    name: 'portal_settings_index',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalSettingsIndexPage,
  },
];

export default {
  routes: [
    {
      path: getPortalRoute(),
      component: HelpCenterLayout,
      children: [...portalRoutes],
    },
  ],
};
