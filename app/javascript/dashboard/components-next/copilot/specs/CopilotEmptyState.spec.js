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
    const AGENT_PROMPTS = [
      'CAN_CLOSE',
      'FOLLOW_UPS',
      'UPSET_CUSTOMERS',
      'WAITING_ON_ME',
      'RECENT_CONVERSATIONS',
    ];
    const ADMIN_PROMPTS = [
      'COMPARE_PERIODS',
      'SLOWEST_REPLIES',
      'LOW_RATINGS',
      'TEAM_WORKLOAD',
      'MONTHLY_VOLUME',
      'COMPARE_INBOXES',
      'LOW_RATINGS_BY_AGENT',
      'LABEL_RESOLVED',
      'CAPTAIN_HANDOFFS',
    ];
    const ROLE_PROMPTS = { agent: AGENT_PROMPTS, administrator: ADMIN_PROMPTS };

    beforeEach(() => {
      useTrack.mockClear();
      currentChat.value = { id: 1 };
    });

    const promptKeys = wrapper =>
      wrapper
        .findAll('button')
        .map(button =>
          button.text().replace(/^CAPTAIN\.COPILOT\.PROMPTS\.|\.LABEL$/g, '')
        );

    it.each(['agent', 'administrator'])(
      'offers the %s three prompts from their role when no conversation is open',
      role => {
        currentRole.value = role;
        currentChat.value = {};
        const keys = promptKeys(mountComponent({ isWorkflowsEnabled: true }));

        expect(keys).toHaveLength(3);
        expect(new Set(keys).size).toBe(3);
        keys.forEach(key => expect(ROLE_PROMPTS[role]).toContain(key));
      }
    );

    it.each(['agent', 'administrator'])(
      'offers the %s a summary and a reply first when a conversation is open',
      role => {
        currentRole.value = role;
        const keys = promptKeys(mountComponent({ isWorkflowsEnabled: true }));

        expect(keys).toHaveLength(4);
        expect(keys.slice(0, 2)).toEqual(['SUMMARIZE', 'SUGGEST']);
        keys
          .slice(2)
          .forEach(key =>
            expect(['CUSTOMER_HISTORY', ...ROLE_PROMPTS[role]]).toContain(key)
          );
      }
    );

    it('leaves out the reply when the customer did not speak last', () => {
      currentRole.value = 'agent';
      const keys = promptKeys(
        mountComponent({ isWorkflowsEnabled: true, canSuggestReply: false })
      );

      expect(keys).toHaveLength(4);
      expect(keys[0]).toBe('SUMMARIZE');
      expect(keys).not.toContain('SUGGEST');
    });

    it('keeps the same prompts for the whole page load', () => {
      currentRole.value = 'administrator';
      currentChat.value = {};
      const first = promptKeys(mountComponent({ isWorkflowsEnabled: true }));
      const second = promptKeys(mountComponent({ isWorkflowsEnabled: true }));

      expect(second).toEqual(first);
    });

    it('sends the reply suggestion through the Assistant', async () => {
      currentRole.value = 'agent';
      const wrapper = mountComponent({ isWorkflowsEnabled: true });

      await wrapper.findAll('button')[1].trigger('click');

      expect(wrapper.emitted('useSuggestion')[0][0]).toEqual({
        message: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.CONTENT',
        requestType: 'reply_suggestion',
      });
    });

    it('records which prompt was clicked and the role of the person', async () => {
      currentRole.value = 'administrator';
      currentChat.value = {};
      const wrapper = mountComponent({ isWorkflowsEnabled: true });
      const [key] = promptKeys(wrapper);

      await wrapper.findAll('button')[0].trigger('click');

      expect(useTrack).toHaveBeenCalledWith('Copilot: Send suggested message', {
        prompt: key,
        role: 'administrator',
      });
      expect(wrapper.emitted('useSuggestion')[0][0]).toBe(
        `CAPTAIN.COPILOT.PROMPTS.${key}.CONTENT`
      );
    });
  });
});
