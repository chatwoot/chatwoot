import AgentDetails from '../AgentDetails';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import VueI18n from 'vue-i18n';

import i18n from 'dashboard/i18n';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
const localVue = createLocalVue();
localVue.use(Vuex);
localVue.use(VueI18n);
localVue.component('thumbnail', Thumbnail);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

describe('agentDetails', () => {
  const currentUser = { name: 'Neymar Junior', avatar_url: '' };
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

  it('shows the agent name', () => {
    const agentTitle = agentDetails.find('.current-user--name');
    expect(agentTitle.text()).toBe('Neymar Junior');
  });

  it('shows the agent role', () => {
    const agentTitle = agentDetails.find('.current-user--role');
    expect(agentTitle.text()).toBe('Agent');
  });

  it('agent thumbnail exists', () => {
    const thumbnailComponent = agentDetails.findComponent(Thumbnail);
    expect(thumbnailComponent.exists()).toBe(true);
  });
});
