import HelpCenterLayout from './components/HelpCenterLayout.vue';
import { getPortalRoute } from './helpers/routeHelper';

const ListArticlesPage = () => import('./pages/articles/ListArticlesPage.vue');
const ListCategoriesPage = () =>
  import('./pages/categories/ListCategoriesPage.vue');
const ListLocalesPage = () => import('./pages/locales/ListLocalesPage.vue');
const EditArticlePage = () => import('./pages/articles/EditArticlePage.vue');
const NewArticlePage = () => import('./pages/articles/NewArticlePage.vue');
const PortalSettingsPage = () =>
  import('./pages/portals/PortalSettingsPage.vue');
const DefaultPortalArticles = () =>
  import('./pages/articles/DefaultPortalArticles.vue');

const portalRoutes = [
  {
    path: getPortalRoute(''),
    name: 'default_portal_articles',
    meta: {
      permissions: ['administrator', 'knowledge_base_manage'],
    },
    component: DefaultPortalArticles,
  },

  {
    path: getPortalRoute(
      ':portalSlug/:locale/:categorySlug?/new-articles/:tab?'
    ),
    name: 'list_articles',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: ListArticlesPage,
  },
  {
    path: getPortalRoute(':portalSlug/:locale/new-articles/new'),
    name: 'new_articles',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: NewArticlePage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/:categorySlug?/new-articles/:tab?/edit/:articleSlug'
    ),
    name: 'edit_articles',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: EditArticlePage,
  },

  {
    path: getPortalRoute(':portalSlug/:locale/new-categories'),
    name: 'list_categories',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: ListCategoriesPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/new-categories/:categorySlug/articles'
    ),
    name: 'list_category_articles',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: ListArticlesPage,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/new-categories/:categorySlug/articles/:articleSlug'
    ),
    name: 'edit_category_article',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: EditArticlePage,
  },
  {
    path: getPortalRoute(':portalSlug/locales'),
    name: 'list_locales',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: ListLocalesPage,
  },
  {
    path: getPortalRoute(':portalSlug/settings'),
    name: 'portal_settings',
    meta: {
      permissions: ['administrator', 'agent', 'knowledge_base_manage'],
    },
    component: PortalSettingsPage,
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
