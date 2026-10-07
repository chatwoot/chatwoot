import { shallowMount } from '@vue/test-utils';

import CopilotEmptyState from '../CopilotEmptyState.vue';

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
});
