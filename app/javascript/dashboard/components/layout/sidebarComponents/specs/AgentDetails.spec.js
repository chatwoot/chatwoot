import AgentDetails from '../AgentDetails.vue';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import VueI18n from 'vue-i18n';
import VTooltip from 'v-tooltip';

import i18n from 'dashboard/i18n';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import WootButton from 'dashboard/components/ui/WootButton.vue';
const localVue = createLocalVue();
localVue.use(Vuex);
localVue.use(VueI18n);
localVue.component('thumbnail', Thumbnail);
localVue.component('woot-button', WootButton);
localVue.component('woot-button', WootButton);
localVue.use(VTooltip, {
  defaultHtml: false,
});

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

describe('agentDetails', () => {
  const currentUser = {
    name: 'Neymar Junior',
    avatar_url: '',
    availability_status: 'online',
  };
  const currentRole = 'agent';
  let store = null;
  let actions = null;
  let modules = null;
  let agentDetails = null;

  beforeEach(() => {
    actions = {};

    modules = {
      auth: {
        getters: {
          getCurrentUser: () => currentUser,
          getCurrentRole: () => currentRole,
          getCurrentUserAvailability: () => currentUser.availability_status,
        },
      },
    };

    store = new Vuex.Store({
      actions,
      modules,
    });

    agentDetails = shallowMount(AgentDetails, {
      store,
      localVue,
      i18n: i18nConfig,
    });
  });

  it(' the agent status', () => {
    expect(agentDetails.find('thumbnail-stub').vm.status).toBe('online');
  });

  it('agent thumbnail exists', () => {
    const thumbnailComponent = agentDetails.findComponent(Thumbnail);
    expect(thumbnailComponent.exists()).toBe(true);
  });
});
