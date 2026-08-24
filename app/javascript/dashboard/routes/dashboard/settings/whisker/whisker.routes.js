import { frontendURL } from '../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/ai-providers'),
      name: 'ai_providers',
      component: () =>
        import('./ai_providers/AiProviders.vue'),
      meta: {
        permissions: ['administrator'],
      },
    },
    {
      path: frontendURL('accounts/:accountId/settings/knowledge-base'),
      name: 'knowledge_base',
      component: () =>
        import('./knowledge_base/KnowledgeBase.vue'),
      meta: {
        permissions: ['administrator'],
      },
    },
    {
      path: frontendURL('accounts/:accountId/settings/flow-builder'),
      name: 'flow_builder',
      component: () =>
        import('./flow_builder/FlowBuilder.vue'),
      meta: {
        permissions: ['administrator'],
      },
    },
    {
      path: frontendURL('accounts/:accountId/settings/theme-marketplace'),
      name: 'theme_marketplace',
      component: () =>
        import('./theme_marketplace/ThemeMarketplace.vue'),
      meta: {
        permissions: ['administrator'],
      },
    },
    {
      path: frontendURL('accounts/:accountId/settings/error-reports'),
      name: 'error_reports',
      component: () =>
        import('./error_reports/ErrorReports.vue'),
      meta: {
        permissions: ['administrator'],
      },
    },
  ],
};
