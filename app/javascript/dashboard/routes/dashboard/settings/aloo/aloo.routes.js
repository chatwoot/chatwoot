import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';

import SettingsContent from '../Wrapper.vue';
import SettingWrapper from '../SettingsWrapper.vue';

const Index = () => import('./Index.vue');
const AssistantWrapper = () => import('./AssistantWrapper.vue');
const Settings = () => import('./Settings.vue');
const StepBasicInfo = () => import('./components/wizard/StepBasicInfo.vue');
const StepPersonality = () => import('./components/wizard/StepPersonality.vue');
const StepKnowledgeBase = () =>
  import('./components/wizard/StepKnowledgeBase.vue');
const StepAssignInbox = () => import('./components/wizard/StepAssignInbox.vue');

const meta = {
  featureFlag: FEATURE_FLAGS.ALOO,
  permissions: ['administrator'],
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/aloo'),
      component: SettingWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'settings_aloo_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'settings_aloo_list',
          component: Index,
          meta,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/aloo'),
      component: SettingsContent,
      props: params => {
        const showBackButton = params.name !== 'settings_aloo_list';
        const fullWidth = params.name === 'settings_aloo_edit';
        return {
          headerTitle: 'ALOO.HEADER',
          icon: 'bot',
          showBackButton,
          fullWidth,
        };
      },
      children: [
        {
          path: 'new',
          component: AssistantWrapper,
          children: [
            {
              path: '',
              name: 'settings_aloo_new',
              component: StepBasicInfo,
              meta,
            },
            {
              path: 'personality',
              name: 'settings_aloo_new_personality',
              component: StepPersonality,
              meta,
            },
            {
              path: 'knowledge',
              name: 'settings_aloo_new_knowledge',
              component: StepKnowledgeBase,
              meta,
            },
            {
              path: 'assign',
              name: 'settings_aloo_new_assign',
              component: StepAssignInbox,
              meta,
            },
          ],
        },
        {
          path: ':assistantId/:tab?',
          name: 'settings_aloo_edit',
          component: Settings,
          meta,
        },
      ],
    },
  ],
};
