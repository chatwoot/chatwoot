import { shallowMount, flushPromises } from '@vue/test-utils';
import { createStore } from 'vuex';
import FormInput from 'v3/components/Form/Input.vue';
import TeamForm from '../TeamForm.vue';

const state = vi.hoisted(() => ({ voiceEnabled: false }));

const mountForm = (props = {}) =>
  shallowMount(TeamForm, {
    props: { submitButtonText: 'Save', ...props },
    global: {
      plugins: [
        createStore({
          getters: {
            getCurrentAccountId: () => 1,
            'accounts/isFeatureEnabledonAccount': () => (accountId, feature) =>
              accountId === 1 &&
              feature === 'channel_voice' &&
              state.voiceEnabled,
          },
        }),
      ],
      mocks: { $t: key => key },
      renderStubDefaultSlot: true,
      stubs: { WithLabel: false, Select: false, 'fluent-icon': true },
    },
  });

const submit = async wrapper => {
  await wrapper.find('form').trigger('submit');
  await flushPromises();
};

describe('TeamForm call widening', () => {
  let onSubmit;
  beforeEach(() => {
    state.voiceEnabled = false;
    onSubmit = vi.fn();
  });

  it('hides the setting and leaves it out of the payload when voice is off', async () => {
    const wrapper = mountForm({ onSubmit, formData: { name: 'Support' } });

    expect(wrapper.find('select').exists()).toBe(false);
    expect(wrapper.text()).not.toContain('TEAMS_SETTINGS.FORM.WIDEN_CALLS');
    await submit(wrapper);
    expect(onSubmit).toHaveBeenCalledTimes(1);
    expect(onSubmit.mock.calls[0][0]).not.toHaveProperty('widen_calls');
  });

  it('shows the setting with its three options when voice is on', () => {
    state.voiceEnabled = true;
    const wrapper = mountForm({ onSubmit });

    expect(wrapper.text()).toContain('TEAMS_SETTINGS.FORM.WIDEN_CALLS.LABEL');
    expect(wrapper.text()).toContain('TEAMS_SETTINGS.FORM.WIDEN_CALLS.HELP');
    const options = wrapper.findAll('select option');
    expect(options.map(option => option.element.value)).toEqual([
      'inbox_agents',
      'team_members',
      'assignee_only',
    ]);
    expect(options.map(option => option.text())).toEqual([
      'TEAMS_SETTINGS.FORM.WIDEN_CALLS.OPTIONS.INBOX_AGENTS',
      'TEAMS_SETTINGS.FORM.WIDEN_CALLS.OPTIONS.TEAM_MEMBERS',
      'TEAMS_SETTINGS.FORM.WIDEN_CALLS.OPTIONS.ASSIGNEE_ONLY',
    ]);
  });

  it('defaults a new team to ringing everyone in the inbox', async () => {
    state.voiceEnabled = true;
    const wrapper = mountForm({ onSubmit });
    const [title] = wrapper.findAllComponents(FormInput);
    title.vm.$emit('update:modelValue', 'Sales');
    await wrapper.vm.$nextTick();

    expect(wrapper.find('select').element.value).toBe('inbox_agents');
    await submit(wrapper);
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'Sales', widen_calls: 'inbox_agents' })
    );
  });

  it('prefills the saved value when editing a team', async () => {
    state.voiceEnabled = true;
    const wrapper = mountForm({
      onSubmit,
      formData: { name: 'Support', widen_calls: 'assignee_only' },
    });

    expect(wrapper.find('select').element.value).toBe('assignee_only');
    await submit(wrapper);
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({ widen_calls: 'assignee_only' })
    );
  });

  it('submits the chosen value', async () => {
    state.voiceEnabled = true;
    const wrapper = mountForm({
      onSubmit,
      formData: { name: 'Support', widen_calls: 'inbox_agents' },
    });
    await wrapper.find('select').setValue('team_members');

    await submit(wrapper);
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'Support', widen_calls: 'team_members' })
    );
  });
});
