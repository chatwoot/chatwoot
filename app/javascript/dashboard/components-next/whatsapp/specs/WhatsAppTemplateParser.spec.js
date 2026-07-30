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
  it('sends the original template body instead of the rendered preview', async () => {
    const wrapper = shallowMount(WhatsAppTemplateParser, {
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

    expect(wrapper.vm.renderedTemplate).toBe('{{2}} / Bob');

    wrapper.vm.sendMessage();

    expect(wrapper.emitted('sendMessage')[0][0]).toMatchObject({
      message: '{{1}} / {{2}}',
      templateParams: {
        processed_params: {
          body: {
            1: '{{2}}',
            2: 'Bob',
          },
        },
      },
    });
  });
});
