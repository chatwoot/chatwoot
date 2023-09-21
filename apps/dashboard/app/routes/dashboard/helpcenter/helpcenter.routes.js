import HelpCenterLayout from './components/HelpCenterLayout.vue';
import { getPortalRoute } from './helpers/routeHelper';

const ListAllPortals = () => import('./pages/portals/ListAllPortals.vue');
const NewPortal = () => import('./pages/portals/NewPortal.vue');

const EditPortal = () => import('./pages/portals/EditPortal.vue');
const EditPortalBasic = () => import('./pages/portals/EditPortalBasic.vue');
const EditPortalCustomization = () =>
  import('./pages/portals/EditPortalCustomization.vue');
const EditPortalLocales = () => import('./pages/portals/EditPortalLocales.vue');
const ShowPortal = () => import('./pages/portals/ShowPortal.vue');
const PortalDetails = () => import('./pages/portals/PortalDetails.vue');
const PortalCustomization = () => import('./pages/portals/PortalCustomization.vue');
const PortalSettingsFinish = () =>
  import('./pages/portals/PortalSettingsFinish.vue');

const ListAllCategories = () => import('./pages/categories/ListAllCategories.vue');
const NewCategory = () => import('./pages/categories/NewCategory.vue');
const EditCategory = () => import('./pages/categories/EditCategory.vue');
const ListCategoryArticles = () =>
  import('./pages/articles/ListCategoryArticles.vue');
const ListAllArticles = () => import('./pages/articles/ListAllArticles.vue');
const DefaultPortalArticles = () =>
  import('./pages/articles/DefaultPortalArticles.vue');
const NewArticle = () => import('./pages/articles/NewArticle.vue');
const EditArticle = () => import('./pages/articles/EditArticle.vue');

const portalRoutes = [
  {
    path: getPortalRoute(''),
    name: 'default_portal_articles',
    roles: ['administrator', 'agent'],
    component: DefaultPortalArticles,
  },
  {
    path: getPortalRoute('all'),
    name: 'list_all_portals',
    roles: ['administrator', 'agent'],
    component: ListAllPortals,
  },
  {
    path: getPortalRoute('new'),
    component: NewPortal,
    children: [
      {
        path: '',
        name: 'new_portal_information',
        component: PortalDetails,
        roles: ['administrator'],
      },
      {
        path: ':portalSlug/customization',
        name: 'portal_customization',
        component: PortalCustomization,
        roles: ['administrator'],
      },
      {
        path: ':portalSlug/finish',
        name: 'portal_finish',
        component: PortalSettingsFinish,
        roles: ['administrator'],
      },
    ],
  },
  {
    path: getPortalRoute(':portalSlug'),
    name: 'portalSlug',
    roles: ['administrator', 'agent'],
    component: ShowPortal,
  },
  {
    path: getPortalRoute(':portalSlug/edit'),
    roles: ['administrator', 'agent'],
    component: EditPortal,
    children: [
      {
        path: '',
        name: 'edit_portal_information',
        component: EditPortalBasic,
        roles: ['administrator'],
      },
      {
        path: 'customizations',
        name: 'edit_portal_customization',
        component: EditPortalCustomization,
        roles: ['administrator'],
      },
      {
        path: 'locales',
        name: 'edit_portal_locales',
        component: EditPortalLocales,
        roles: ['administrator'],
      },
      {
        path: 'categories',
        name: 'list_all_locale_categories',
        roles: ['administrator', 'agent'],
        component: ListAllCategories,
      },
    ],
  },
];

const articleRoutes = [
  {
    path: getPortalRoute(':portalSlug/:locale/articles'),
    name: 'list_all_locale_articles',
    roles: ['administrator', 'agent'],
    component: ListAllArticles,
  },
  {
    path: getPortalRoute(':portalSlug/:locale/articles/new'),
    name: 'new_article',
    roles: ['administrator', 'agent'],
    component: NewArticle,
  },
  {
    path: getPortalRoute(':portalSlug/:locale/articles/mine'),
    name: 'list_mine_articles',
    roles: ['administrator', 'agent'],
    component: ListAllArticles,
  },
  {
    path: getPortalRoute(':portalSlug/:locale/articles/archived'),
    name: 'list_archived_articles',
    roles: ['administrator', 'agent'],
    component: ListAllArticles,
  },

  {
    path: getPortalRoute(':portalSlug/:locale/articles/draft'),
    name: 'list_draft_articles',
    roles: ['administrator', 'agent'],
    component: ListAllArticles,
  },

  {
    path: getPortalRoute(':portalSlug/:locale/articles/:articleSlug'),
    name: 'edit_article',
    roles: ['administrator', 'agent'],
    component: EditArticle,
  },
];

const categoryRoutes = [
  {
    path: getPortalRoute(':portalSlug/:locale/categories'),
    name: 'all_locale_categories',
    roles: ['administrator', 'agent'],
    component: ListAllCategories,
  },
  {
    path: getPortalRoute(':portalSlug/:locale/categories/new'),
    name: 'new_category_in_locale',
    roles: ['administrator', 'agent'],
    component: NewCategory,
  },
  {
    path: getPortalRoute(':portalSlug/:locale/categories/:categorySlug'),
    name: 'show_category',
    roles: ['administrator', 'agent'],
    component: ListAllArticles,
  },
  {
    path: getPortalRoute(
      ':portalSlug/:locale/categories/:categorySlug/articles'
    ),
    name: 'show_category_articles',
    roles: ['administrator', 'agent'],
    component: ListCategoryArticles,
  },
  {
    path: getPortalRoute(':portalSlug/:locale/categories/:categorySlug'),
    name: 'edit_category',
    roles: ['administrator', 'agent'],
    component: EditCategory,
  },
];

export default {
  routes: [
    {
      path: getPortalRoute(),
      component: HelpCenterLayout,
      children: [...portalRoutes, ...articleRoutes, ...categoryRoutes],
    },
  ],
};
