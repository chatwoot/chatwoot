import { ref } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { useTrack } from 'dashboard/composables';

import CopilotEmptyState from '../CopilotEmptyState.vue';

const currentRole = ref('agent');
const currentChat = ref({ id: 1 });

vi.mock('dashboard/composables', () => ({
  useTrack: vi.fn(),
}));

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: name =>
    name === 'getSelectedChat' ? currentChat : currentRole,
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('vue-router', () => ({
  useRoute: () => ({ path: '/app/accounts/1/conversations/1' }),
}));

const mountComponent = (props = {}) =>
  shallowMount(CopilotEmptyState, {
    props: { hasAssistants: true, ...props },
    global: {
      mocks: { $t: key => key },
      stubs: { RouterLink: true },
    },
  });

describe('CopilotEmptyState', () => {
  it('marks only the reply suggestion prompt with its request type', async () => {
    const wrapper = mountComponent();
    const prompts = wrapper.findAll('button');

    await prompts[1].trigger('click');

    expect(wrapper.emitted('useSuggestion')[0][0]).toEqual({
      message: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.CONTENT',
      requestType: 'reply_suggestion',
    });
  });

  it('keeps other Copilot prompts unchanged', async () => {
    const wrapper = mountComponent();
    const prompts = wrapper.findAll('button');

    await prompts[0].trigger('click');

    expect(wrapper.emitted('useSuggestion')[0][0]).toBe(
      'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.CONTENT'
    );
  });

  it('hides the reply suggestion when the latest message is not incoming', () => {
    const wrapper = mountComponent({ canSuggestReply: false });

    expect(wrapper.findAll('button')).toHaveLength(2);
    expect(wrapper.text()).not.toContain(
      'CAPTAIN.COPILOT.PROMPTS.SUGGEST.LABEL'
    );
  });

  describe('with workflows', () => {
    beforeEach(() => {
      useTrack.mockClear();
      currentChat.value = { id: 1 };
    });

    const promptLabels = wrapper =>
      wrapper.findAll('button').map(button => button.text());
    const labelsFor = keys =>
      keys.map(key => `CAPTAIN.COPILOT.PROMPTS.${key}.LABEL`);

    it.each([
      ['agent', ['WAITING_ON_ME', 'RECENT_CONVERSATIONS']],
      ['administrator', ['WAITING_ON_ME', 'TEAM_WORKLOAD', 'TOP_QUESTIONS']],
    ])('offers the %s prompts when no conversation is open', (role, keys) => {
      currentRole.value = role;
      currentChat.value = {};
      const wrapper = mountComponent({ isWorkflowsEnabled: true });

      expect(promptLabels(wrapper)).toEqual(labelsFor(keys));
    });

    it.each([
      ['agent', ['SUMMARIZE', 'WAITING_ON_ME', 'RECENT_CONVERSATIONS']],
      ['administrator', ['SUMMARIZE', 'TEAM_WORKLOAD', 'TOP_QUESTIONS']],
    ])(
      'offers the %s a summary first when a conversation is open',
      (role, keys) => {
        currentRole.value = role;
        const wrapper = mountComponent({ isWorkflowsEnabled: true });

        expect(promptLabels(wrapper)).toEqual(labelsFor(keys));
      }
    );

    it('records which prompt was clicked and the role of the person', async () => {
      currentRole.value = 'administrator';
      currentChat.value = {};
      const wrapper = mountComponent({ isWorkflowsEnabled: true });

      await wrapper.findAll('button')[1].trigger('click');

      expect(useTrack).toHaveBeenCalledWith('Copilot: Send suggested message', {
        prompt: 'TEAM_WORKLOAD',
        role: 'administrator',
      });
      expect(wrapper.emitted('useSuggestion')[0][0]).toBe(
        'CAPTAIN.COPILOT.PROMPTS.TEAM_WORKLOAD.CONTENT'
      );
    });
  });
});
