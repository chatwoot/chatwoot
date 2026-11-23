import { computed } from 'vue';
import { shallowMount } from '@vue/test-utils';
import AutomationActionWhatsAppTemplateInput from '../AutomationActionWhatsAppTemplateInput.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TemplateFields from 'dashboard/components-next/Campaigns/WhatsAppCampaign/TemplateFields.vue';

const template = {
  id: 'tpl-1',
  name: 'order_update',
  language: 'en',
  category: 'UTILITY',
  namespace: 'ns',
  components: [{ type: 'BODY', text: 'Hi {{1}}, your order shipped.' }],
};

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
const inboxTemplates = vi.hoisted(() => ({ value: [] }));

vi.mock('dashboard/composables/store', async () => {
  const { ref } = await import('vue');
  inboxTemplates.value = ref([]);
  return {
    useMapGetter: getter =>
      computed(() => {
        const loaded = inboxTemplates.value.value;
        return getter === 'inboxes/getWhatsAppInboxes'
          ? [{ id: 7, name: 'Support WhatsApp' }]
          : inboxId => (inboxId === 7 ? loaded : []);
      }),
  };
});

const savedValue = {
  inbox_id: 7,
  content: 'Hi {{1}}, your order shipped.',
  template_params: {
    name: 'order_update',
    namespace: 'ns',
    category: 'UTILITY',
    language: 'en',
    processed_params: { body: { 1: '{{contact.name}}' } },
  },
};

describe('AutomationActionWhatsAppTemplateInput', () => {
  beforeEach(() => {
    inboxTemplates.value.value = [template];
  });

  it('builds the action params from the picked inbox and template', async () => {
    const wrapper = shallowMount(AutomationActionWhatsAppTemplateInput, {
      props: { modelValue: null },
    });

    wrapper.findComponent(ComboBox).vm.$emit('update:modelValue', 7);
    await wrapper.vm.$nextTick();
    const fields = wrapper.findComponent(TemplateFields);
    expect(fields.props('templates')).toEqual([template]);

    fields.vm.$emit('update:templateId', 'tpl-1');
    fields.vm.$emit('update:processedParams', {
      body: { 1: '{{contact.name}}' },
    });
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('update:modelValue').at(-1)).toEqual([savedValue]);
  });

  it('restores a saved template once the inbox templates load', async () => {
    inboxTemplates.value.value = [];
    const wrapper = shallowMount(AutomationActionWhatsAppTemplateInput, {
      props: { modelValue: savedValue },
    });
    const fields = wrapper.findComponent(TemplateFields);
    expect(fields.props('templateId')).toBeNull();

    inboxTemplates.value.value = [template];
    await wrapper.vm.$nextTick();

    expect(wrapper.findComponent(ComboBox).props('modelValue')).toBe(7);
    expect(fields.props('templateId')).toBe('tpl-1');
    expect(fields.props('processedParams')).toEqual({
      body: { 1: '{{contact.name}}' },
    });
  });
});
