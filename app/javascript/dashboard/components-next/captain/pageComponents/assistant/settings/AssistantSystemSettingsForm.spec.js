import { nextTick } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import { describe, expect, it, vi } from 'vitest';
import Button from 'dashboard/components-next/button/Button.vue';
import RadioCard from 'dashboard/components-next/radioCard/RadioCard.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import AssistantSystemSettingsForm from './AssistantSystemSettingsForm.vue';
import DurationSelect from './DurationSelect.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ isCloudFeatureEnabled: () => true }),
}));

const assistant = {
  config: {
    product_name: 'Chatwoot',
    handoff_message: 'I will connect you with the team.',
    resolution_message: 'I will close this conversation for now.',
    auto_resolve_mode: 'evaluated',
    auto_resolve_after: 75,
    send_inactivity_resolution_message: true,
  },
};

const mountComponent = () =>
  shallowMount(AssistantSystemSettingsForm, {
    props: { assistant },
    global: { stubs: { Banner: false, SettingsToggleSection: false } },
  });

const submitForm = async wrapper => {
  wrapper.findComponent(Button).vm.$emit('click');
  await flushPromises();
};

describe('AssistantSystemSettingsForm', () => {
  it('shows the evaluated policy controls from the saved config', () => {
    const wrapper = mountComponent();
    const modeCards = wrapper.findAllComponents(RadioCard);

    expect(modeCards).toHaveLength(3);
    expect(
      modeCards.every(card => card.props('name') === 'auto-resolve-mode')
    ).toBe(true);
    expect(modeCards[0].props('isActive')).toBe(true);
    expect(wrapper.findAllComponents(DurationSelect)).toHaveLength(1);
    expect(wrapper.findAllComponents(Switch)).toHaveLength(1);
    expect(wrapper.text()).toContain(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.REVIEW_AFTER'
    );
  });

  it('hides inactive actions and saves disabled mode without clearing settings', async () => {
    const wrapper = mountComponent();

    wrapper.findAllComponents(RadioCard)[2].vm.$emit('select');
    await nextTick();

    expect(wrapper.findAllComponents(DurationSelect)).toHaveLength(0);
    expect(wrapper.findAllComponents(Switch)).toHaveLength(0);
    expect(wrapper.text()).toContain(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.PENDING_INFO'
    );

    await submitForm(wrapper);

    expect(wrapper.emitted('submit')[0][0]).toEqual({
      config: {
        ...assistant.config,
        auto_resolve_mode: 'disabled',
      },
    });
  });

  it('saves the evaluated policy timer', async () => {
    const wrapper = mountComponent();

    const durationSelects = wrapper.findAllComponents(DurationSelect);
    expect(durationSelects).toHaveLength(1);

    durationSelects[0].vm.$emit('update:modelValue', 130);
    await nextTick();
    await submitForm(wrapper);

    expect(wrapper.emitted('submit')[0][0]).toEqual({
      config: {
        ...assistant.config,
        auto_resolve_after: 130,
      },
    });
  });

  it('shows the warning in always resolve mode', async () => {
    const wrapper = mountComponent();

    wrapper.findAllComponents(RadioCard)[1].vm.$emit('select');
    await nextTick();

    expect(wrapper.findAllComponents(DurationSelect)).toHaveLength(1);
    expect(wrapper.findAllComponents(Switch)).toHaveLength(1);
    expect(wrapper.text()).toContain(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.ALWAYS_WARNING'
    );
  });
});
