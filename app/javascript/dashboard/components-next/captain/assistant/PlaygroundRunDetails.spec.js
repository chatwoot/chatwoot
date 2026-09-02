import { shallowMount } from '@vue/test-utils';
import PlaygroundRunDetails from './PlaygroundRunDetails.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, value) => `${key}:${JSON.stringify(value || {})}`,
  }),
}));

describe('PlaygroundRunDetails', () => {
  it('renders the handler, safe tool details, and the immutable setup summary', () => {
    const wrapper = shallowMount(PlaygroundRunDetails, {
      props: {
        runDetails: {
          handler: { title: 'Refund scenario', temporary: true },
          events: [
            {
              type: 'tool',
              name: 'update_priority',
              status: 'completed',
              arguments: { priority: 'high' },
              result_preview: 'Priority updated',
            },
          ],
          temporary_knowledge_attached: true,
          duration_ms: 42,
        },
        setupSummary: {
          scenarioCount: 1,
          guidelineCount: 1,
          guardrailCount: 1,
        },
      },
    });

    expect(wrapper.text()).toContain('Refund scenario');
    expect(wrapper.text()).toContain('update_priority');
    expect(wrapper.text()).toContain('Priority updated');
    expect(wrapper.text()).toContain('"priority": "high"');
  });
});
