import { shallowMount } from '@vue/test-utils';
import TemplateFields from '../TemplateFields.vue';
import Input from 'dashboard/components-next/input/Input.vue';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/components-next/combobox/ComboBox.vue', () => ({
  default: { template: '<div />' },
}));

describe('template button parameters', () => {
  it.each(['sparse', 'persisted'])(
    'renders %s buttons without changing provider indexes',
    shape => {
      const buttons = [];
      buttons[1] = { type: 'url', parameter: 'offer' };
      const params = {
        buttons:
          shape === 'persisted' ? JSON.parse(JSON.stringify(buttons)) : buttons,
      };
      const wrapper = shallowMount(TemplateFields, {
        props: { processedParams: params },
      });
      const inputs = wrapper.findAllComponents(Input);
      expect(inputs).toHaveLength(1);
      expect(inputs[0].props('modelValue')).toBe('offer');
      inputs[0].vm.$emit('update:modelValue', 'new-offer');
      expect(params.buttons[1].parameter).toBe('new-offer');
      expect(params.buttons[0] == null).toBe(true);
    }
  );
});
