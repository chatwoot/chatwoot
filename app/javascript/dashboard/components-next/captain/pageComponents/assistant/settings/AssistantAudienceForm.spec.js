import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import Button from 'dashboard/components-next/button/Button.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import AssistantAudienceForm from './AssistantAudienceForm.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('./audience/useAudienceFilterTypes.js', () => ({
  useAudienceFilterTypes: () => ({ filterTypes: [] }),
}));

const mountComponent = () =>
  shallowMount(AssistantAudienceForm, {
    props: { assistant: { config: {} } },
    global: { stubs: { RadioCard: false } },
  });

describe('AssistantAudienceForm', () => {
  it('does not submit a specific audience without conditions', async () => {
    const wrapper = mountComponent();

    wrapper.findAllComponents(RadioCard)[1].vm.$emit('select', 'specific');
    await nextTick();
    wrapper.findComponent(Button).vm.$emit('click');
    await nextTick();

    expect(wrapper.emitted('submit')).toBeUndefined();
    expect(wrapper.text()).toContain(
      'CAPTAIN.ASSISTANTS.FORM.AUDIENCE.EMPTY_ERROR'
    );
  });
});
