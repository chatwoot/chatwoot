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

  it('shows and sends dynamic URL button parameters without body or header variables', async () => {
    const dynamicUrlTemplate = {
      name: 'report_ready',
      category: 'UTILITY',
      language: 'en',
      parameter_format: 'POSITIONAL',
      components: [
        {
          type: 'BODY',
          text: 'Your report is ready',
        },
        {
          type: 'BUTTONS',
          buttons: [
            {
              type: 'URL',
              text: 'View report',
              url: 'https://example.com/reports/{{1}}',
            },
          ],
        },
      ],
    };
    const buttonWrapper = shallowMount(WhatsAppTemplateParser, {
      props: { template: dynamicUrlTemplate },
      global: {
        mocks: {
          $t: key => key,
        },
      },
    });
    await nextTick();

    expect(buttonWrapper.vm.hasVariables).toBe(false);
    expect(buttonWrapper.vm.hasButtonVariables).toBe(true);
    expect(buttonWrapper.text()).toContain(
      'WHATSAPP_TEMPLATES.PARSER.BUTTON_PARAMETERS'
    );
    expect(buttonWrapper.vm.processedParams.buttons).toEqual([
      {
        type: 'url',
        parameter: '',
        url: 'https://example.com/reports/{{1}}',
        variables: ['1'],
      },
    ]);
    expect(buttonWrapper.vm.isFormInvalid).toBe(true);
    buttonWrapper.vm.sendMessage();
    expect(buttonWrapper.emitted('sendMessage')).toBeUndefined();

    buttonWrapper.vm.processedParams.buttons[0].parameter = 'ABC123';
    await nextTick();

    expect(buttonWrapper.vm.isFormInvalid).toBe(false);
    buttonWrapper.vm.sendMessage();

    expect(buttonWrapper.emitted('sendMessage')[0][0]).toMatchObject({
      message: 'Your report is ready',
      templateParams: {
        processed_params: {
          buttons: [
            {
              type: 'url',
              parameter: 'ABC123',
              url: 'https://example.com/reports/{{1}}',
              variables: ['1'],
            },
          ],
        },
      },
    });

    buttonWrapper.unmount();
  });
});
