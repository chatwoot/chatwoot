import TemplateParser from '../../../../dashboard/components/widgets/conversation/WhatsappTemplates/TemplateParser.vue';
import { mount, createLocalVue } from '@vue/test-utils';
import { templates } from './fixtures';
const localVue = createLocalVue();
import VueI18n from 'vue-i18n';
import Vue from 'vue';

import Vuelidate from 'vuelidate';
Vue.use(Vuelidate);

import i18n from 'dashboard/i18n';

localVue.use(VueI18n);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

describe('#WhatsAppTemplates', () => {
  it('returns all variables from a template string', () => {
    const wrapper = mount(TemplateParser, {
      localVue,
      propsData: {
        template: templates[0],
      },
      i18n: i18nConfig,
    });
    expect(wrapper.vm.variables).toEqual(['{{1}}', '{{2}}', '{{3}}']);
  });

  it('returns no variables from a template string if it does not contain variables', () => {
    const wrapper = mount(TemplateParser, {
      localVue,
      propsData: {
        template: templates[12],
      },
      i18n: i18nConfig,
    });
    expect(wrapper.vm.variables).toBeNull();
  });

  it('returns the body of a template', () => {
    const wrapper = mount(TemplateParser, {
      localVue,
      propsData: {
        template: templates[1],
      },
      i18n: i18nConfig,
    });
    const expectedOutput = templates[1].components.find(i => i.type === 'BODY')
      .text;
    expect(wrapper.vm.templateString).toEqual(expectedOutput);
  });

  it('generates the templates from variable input', async () => {
    const wrapper = mount(TemplateParser, {
      localVue,
      propsData: {
        template: templates[0],
      },
      data: () => {
        return {
          processedParams: {},
        };
      },
      i18n: i18nConfig,
    });
    await wrapper.setData({
      processedParams: { '1': 'abc', '2': 'xyz', '3': 'qwerty' },
    });
    await wrapper.vm.$nextTick();
    const expectedOutput =
      'Esta é a sua confirmação de voo para abc-xyz em qwerty.';
    expect(wrapper.vm.processedString).toEqual(expectedOutput);
  });
});
