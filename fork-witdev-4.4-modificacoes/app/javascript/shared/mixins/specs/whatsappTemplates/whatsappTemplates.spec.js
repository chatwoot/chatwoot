import { shallowMount } from '@vue/test-utils';
import TemplateParser from '../../../../dashboard/components/widgets/conversation/WhatsappTemplates/TemplateParser.vue';
import { templates } from './fixtures';
import { nextTick } from 'vue';

const config = {
  global: {
    stubs: {
      NextButton: { template: '<button />' },
      WootInput: { template: '<input />' },
    },
  },
};

describe('#WhatsAppTemplates', () => {
  it('returns all variables from a template string', async () => {
    const wrapper = shallowMount(TemplateParser, {
      ...config,
      props: { template: templates[0] },
    });
    await nextTick();
    expect(wrapper.vm.variables).toEqual(['{{1}}', '{{2}}', '{{3}}']);
  });

  it('returns no variables from a template string if it does not contain variables', async () => {
    const wrapper = shallowMount(TemplateParser, {
      ...config,
      props: { template: templates[12] },
    });
    await nextTick();
    expect(wrapper.vm.variables).toBeNull();
  });

  it('returns the body of a template', async () => {
    const wrapper = shallowMount(TemplateParser, {
      ...config,
      props: { template: templates[1] },
    });
    await nextTick();
    const expectedOutput =
      templates[1].components.find(i => i.type === 'BODY')?.text || '';
    expect(wrapper.vm.templateString).toEqual(expectedOutput);
  });

  it('generates the templates from variable input', async () => {
    const wrapper = shallowMount(TemplateParser, {
      ...config,
      props: { template: templates[0] },
    });
    await nextTick();

    // Instead of using `setData`, directly modify the `processedParams` using the component's logic
    await wrapper.vm.$nextTick();
    wrapper.vm.processedParams = { 1: 'abc', 2: 'xyz', 3: 'qwerty' };
    await wrapper.vm.$nextTick();

    const expectedOutput =
      'Esta é a sua confirmação de voo para abc-xyz em qwerty.';
    expect(wrapper.vm.processedString).toEqual(expectedOutput);
  });
});
