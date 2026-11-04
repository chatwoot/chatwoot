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
    expect(wrapper.text()).toContain(
      'CAPTAIN.PLAYGROUND.RUN_DETAILS.STATUS.COMPLETED'
    );
  });

  it('localizes every tool status returned by the playground runner', () => {
    const wrapper = shallowMount(PlaygroundRunDetails, {
      props: {
        runDetails: {
          handler: { title: 'Support assistant', temporary: false },
          events: ['running', 'completed', 'failed'].map(status => ({
            type: 'tool',
            name: `${status}_tool`,
            status,
            arguments: {},
          })),
          temporary_knowledge_attached: false,
          duration_ms: 42,
        },
        setupSummary: {
          scenarioCount: 0,
          guidelineCount: 0,
          guardrailCount: 0,
        },
      },
    });

    expect(wrapper.text()).toContain(
      'CAPTAIN.PLAYGROUND.RUN_DETAILS.STATUS.RUNNING'
    );
    expect(wrapper.text()).toContain(
      'CAPTAIN.PLAYGROUND.RUN_DETAILS.STATUS.COMPLETED'
    );
    expect(wrapper.text()).toContain(
      'CAPTAIN.PLAYGROUND.RUN_DETAILS.STATUS.FAILED'
    );
  });
});
