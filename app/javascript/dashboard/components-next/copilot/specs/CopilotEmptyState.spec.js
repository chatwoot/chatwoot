import { shallowMount } from '@vue/test-utils';

import CopilotEmptyState from '../CopilotEmptyState.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params) => (params ? `${key}:${params.conversationId}` : key),
  }),
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

  it('includes the selected conversation ID only in V2 summary and rating prompts', async () => {
    const wrapper = mountComponent({ v2Enabled: true, conversationId: 42 });
    const prompts = wrapper.findAll('button');
    await prompts[0].trigger('click');
    await prompts[1].trigger('click');
    await prompts[2].trigger('click');
    expect(wrapper.emitted('useSuggestion').map(event => event[0])).toEqual([
      'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.V2_CONTENT:42',
      {
        message: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.CONTENT',
        requestType: 'reply_suggestion',
      },
      'CAPTAIN.COPILOT.PROMPTS.RATE.V2_CONTENT:42',
    ]);
    await wrapper.setProps({ conversationId: 99 });
    await prompts[0].trigger('click');
    expect(wrapper.emitted('useSuggestion').at(-1)[0]).toBe(
      'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.V2_CONTENT:99'
    );
  });

  it('keeps legacy prompts unchanged when a conversation ID is available', async () => {
    const wrapper = mountComponent({ conversationId: 42 });
    await wrapper.findAll('button')[2].trigger('click');
    expect(wrapper.emitted('useSuggestion')[0][0]).toBe(
      'CAPTAIN.COPILOT.PROMPTS.RATE.CONTENT'
    );
  });

  it('offers account prompts in V2 when no conversation is selected', () => {
    const wrapper = mountComponent({ v2Enabled: true });
    expect(wrapper.text()).toContain(
      'CAPTAIN.COPILOT.PROMPTS.HIGH_PRIORITY.LABEL'
    );
    expect(wrapper.text()).not.toContain(
      'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.LABEL'
    );
  });
});
