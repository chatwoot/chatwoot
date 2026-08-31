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
  useAccount: () => ({
    accountScopedRoute: (name, params, query) => ({ name, params, query }),
    isCloudFeatureEnabled: () => true,
  }),
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

const mountComponent = (assistantProp = assistant) =>
  shallowMount(AssistantSystemSettingsForm, {
    props: { assistant: assistantProp },
    global: {
      stubs: {
        Banner: false,
        RouterLink: {
          name: 'RouterLink',
          props: ['to'],
          template: '<a><slot /></a>',
        },
        SettingsToggleSection: false,
      },
    },
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

  it('warns while the Captain timer can run before a pending follow up', async () => {
    const wrapper = mountComponent({
      ...assistant,
      pending_follow_up_automations: [
        { id: 1, execution_delay: 60 },
        { id: 2, execution_delay: 120 },
      ],
    });

    expect(wrapper.text()).toContain(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.TIMER_CONFLICT_WARNING'
    );

    wrapper.findComponent(DurationSelect).vm.$emit('update:modelValue', 120);
    await nextTick();

    expect(wrapper.text()).toContain(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.TIMER_CONFLICT_WARNING'
    );

    wrapper.findComponent(DurationSelect).vm.$emit('update:modelValue', 125);
    await nextTick();

    expect(wrapper.text()).not.toContain(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.TIMER_CONFLICT_WARNING'
    );
  });

  it('links a single conflict to that automation', () => {
    const wrapper = mountComponent({
      ...assistant,
      pending_follow_up_automations: [{ id: 7, execution_delay: 240 }],
    });

    const link = wrapper.findComponent({ name: 'RouterLink' });
    expect(link.text()).toBe(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.TIMER_CONFLICT_LINK'
    );
    expect(link.props('to')).toEqual({
      name: 'automation_list',
      params: {},
      query: { automationId: 7 },
    });
  });
});
