import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import WhatsAppTemplateParser from '../WhatsAppTemplateParser.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const template = {
  name: 'token_values',
  category: 'UTILITY',
  language: 'en',
  parameter_format: 'POSITIONAL',
  components: [
    {
      type: 'BODY',
      text: '{{1}} / {{2}}',
      example: {
        body_text: [['First', 'Second']],
      },
    },
  ],
};

describe('WhatsAppTemplateParser', () => {
  let wrapper;

  beforeEach(async () => {
    wrapper = shallowMount(WhatsAppTemplateParser, {
      props: { template },
      global: {
        mocks: {
          $t: key => key,
        },
      },
    });

    wrapper.vm.processedParams.body['1'] = '{{2}}';
    wrapper.vm.processedParams.body['2'] = 'Bob';
    await nextTick();
  });

  it('sends the original template body instead of the rendered preview', () => {
    expect(wrapper.vm.renderedTemplate).toBe('{{2}} / Bob');

    wrapper.vm.sendMessage();

    expect(wrapper.emitted('sendMessage')[0][0]).toMatchObject({
      message: '{{1}} / {{2}}',
      pendingMessageContent: '{{2}} / Bob',
      templateParams: {
        content_mode: 'raw_template',
        processed_params: {
          body: {
            1: '{{2}}',
            2: 'Bob',
          },
        },
      },
    });
  });

  it('sends rendered content when requested for an API inbox template', async () => {
    await wrapper.setProps({ sendRenderedContent: true });

    wrapper.vm.sendMessage();

    expect(wrapper.emitted('sendMessage')[0][0]).toMatchObject({
      message: '{{2}} / Bob',
      pendingMessageContent: '{{2}} / Bob',
      templateParams: {
        content_mode: 'rendered',
      },
    });
  });

  it('sends the exact synchronized identity with empty parameters when none are required', () => {
    wrapper = shallowMount(WhatsAppTemplateParser, {
      props: {
        template: {
          name: 'status_update',
          category: 'UTILITY',
          language: 'en_US',
          components: [{ type: 'BODY', text: 'Hello World' }],
        },
      },
      global: { mocks: { $t: key => key } },
    });

    wrapper.vm.sendMessage();

    expect(wrapper.emitted('sendMessage')[0][0]).toMatchObject({
      templateParams: {
        name: 'status_update',
        language: 'en_US',
        processed_params: {},
      },
    });
  });

  it('keeps a supported parameter form unavailable until every value is complete', async () => {
    wrapper = shallowMount(WhatsAppTemplateParser, {
      props: {
        template: {
          name: 'delivery_update',
          category: 'UTILITY',
          language: 'en_US',
          components: [
            { type: 'HEADER', format: 'IMAGE' },
            { type: 'BODY', text: 'Order {{1}} is ready.' },
            {
              type: 'BUTTONS',
              buttons: [
                {
                  type: 'URL',
                  text: 'Track',
                  url: 'https://example.com/{{1}}',
                },
              ],
            },
          ],
        },
      },
      global: { mocks: { $t: key => key } },
    });

    expect(wrapper.vm.isFormInvalid).toBe(true);

    wrapper.vm.processedParams.header.media_url = 'https://example.com/a.png';
    wrapper.vm.processedParams.body['1'] = 'A-123';
    await nextTick();
    expect(wrapper.vm.isFormInvalid).toBe(true);

    wrapper.vm.processedParams.buttons[0].parameter = 'A-123';
    await nextTick();
    expect(wrapper.vm.isFormInvalid).toBe(false);
  });

  it.each([
    ['dynamic URL', { type: 'URL', url: 'https://example.com/{{1}}' }],
    ['copy code', { type: 'COPY_CODE' }],
  ])(
    'renders and requires the parameter for a button-only %s template',
    async (_, button) => {
      wrapper = shallowMount(WhatsAppTemplateParser, {
        props: {
          template: {
            name: 'button_action',
            category: 'UTILITY',
            language: 'en_US',
            components: [
              { type: 'BODY', text: 'Use the action below.' },
              { type: 'BUTTONS', buttons: [{ ...button, text: 'Action' }] },
            ],
          },
        },
        global: { mocks: { $t: key => key } },
      });
      await nextTick();

      expect(wrapper.vm.hasButtonParameters).toBe(true);
      expect(wrapper.text()).toContain(
        'WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETERS'
      );
      expect(wrapper.vm.isFormInvalid).toBe(true);

      wrapper.vm.sendMessage();
      expect(wrapper.emitted('sendMessage')).toBeUndefined();

      wrapper.vm.processedParams.buttons[0].parameter = 'required-value';
      await nextTick();

      expect(wrapper.vm.isFormInvalid).toBe(false);
      wrapper.vm.sendMessage();
      expect(wrapper.emitted('sendMessage')).toHaveLength(1);
    }
  );
});
