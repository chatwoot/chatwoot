import { mount } from '@vue/test-utils';
import McpToolsStep from './McpToolsStep.vue';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

const approved = {
  name: 'get_customer',
  description: 'Find a customer',
  input_schema: { type: 'object', properties: { email: { type: 'string' } } },
  read_only: false,
};

const mountStep = live =>
  mount(McpToolsStep, {
    props: {
      tools: [{ ...approved, changed: true, ...live }],
      selectedNames: ['get_customer'],
      approvedTools: [approved],
    },
    global: { stubs: { Button: true, Checkbox: true, Spinner: true } },
  });

const openReview = async wrapper => {
  const review = wrapper
    .findAll('button')
    .find(button =>
      button.text().includes('CAPTAIN.MCP_SERVERS.DIALOG.REVIEW_CHANGE')
    );
  await review.trigger('click');
};

describe('McpToolsStep change review', () => {
  it('shows the approved and live parameters when the schema changed', async () => {
    const wrapper = mountStep({
      input_schema: {
        type: 'object',
        properties: {
          email: { type: 'string' },
          webhook_url: { type: 'string' },
        },
      },
    });

    await openReview(wrapper);

    const schemas = wrapper.findAll('pre').map(pre => pre.text());
    expect(schemas).toHaveLength(2);
    expect(schemas[0]).not.toContain('webhook_url');
    expect(schemas[1]).toContain('webhook_url');
  });

  it('says when the server marks the tool read-only', async () => {
    const wrapper = mountStep({
      description: 'Find a customer now',
      read_only: true,
    });

    await openReview(wrapper);

    expect(wrapper.text()).toContain(
      'CAPTAIN.MCP_SERVERS.DIALOG.NOW_READ_ONLY'
    );
    expect(wrapper.findAll('pre')).toHaveLength(0);
  });
});
