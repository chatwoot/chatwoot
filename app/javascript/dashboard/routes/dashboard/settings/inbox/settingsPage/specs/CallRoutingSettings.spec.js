import { mount, flushPromises } from '@vue/test-utils';
import CallRoutingSettings from '../CallRoutingSettings.vue';
import InboxesAPI from 'dashboard/api/inboxes';

const { dispatch, alert } = vi.hoisted(() => ({
  dispatch: vi.fn(),
  alert: vi.fn(),
}));

vi.mock('vuex', async importOriginal => ({
  ...(await importOriginal()),
  useStore: () => ({ dispatch }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: alert }));
vi.mock('dashboard/api/inboxes', () => ({
  default: { setCallRouting: vi.fn() },
}));

const inbox = {
  id: 387,
  ring_strategy: 'simultaneous',
  ring_step_seconds: 20,
  prefer_free_agents: false,
  call_cooldown_seconds: 0,
};

const mountComponent = () =>
  mount(CallRoutingSettings, {
    props: { inbox },
    global: { stubs: { Icon: true, Spinner: true } },
  });

describe('CallRoutingSettings', () => {
  beforeEach(() => vi.clearAllMocks());

  it('explains the ring interval for the chosen ringing order', async () => {
    const wrapper = mountComponent();
    expect(wrapper.text()).toContain('STEP.HELP_SIMULTANEOUS');

    await wrapper.find('select').setValue('sequential');

    expect(wrapper.text()).toContain('STEP.HELP_SEQUENTIAL');
  });

  it('saves every setting together as numbers and refreshes the inbox', async () => {
    InboxesAPI.setCallRouting.mockResolvedValue({});
    const wrapper = mountComponent();
    const save = () => wrapper.findAll('button').at(-1);
    expect(save().attributes('disabled')).toBeDefined();

    await wrapper.find('select').setValue('sequential');
    await wrapper.find('#call-routing-step-387').setValue('15');
    await wrapper.find('input[type="checkbox"]').setValue(true);
    await wrapper.find('#call-routing-cooldown-387').setValue('30');
    await save().trigger('click');
    await flushPromises();

    expect(InboxesAPI.setCallRouting).toHaveBeenCalledWith(387, {
      ringStrategy: 'sequential',
      ringStepSeconds: 15,
      preferFreeAgents: true,
      callCooldownSeconds: 30,
    });
    expect(dispatch).toHaveBeenCalledWith('inboxes/get', 387);
  });

  it("shows the server's error when the settings are refused", async () => {
    InboxesAPI.setCallRouting.mockRejectedValue({
      response: { data: { message: 'Choose a step of 5 to 60 seconds' } },
    });
    const wrapper = mountComponent();

    await wrapper.find('#call-routing-cooldown-387').setValue('5');
    await wrapper.findAll('button').at(-1).trigger('click');
    await flushPromises();

    expect(alert).toHaveBeenCalledWith('Choose a step of 5 to 60 seconds');
    expect(dispatch).not.toHaveBeenCalled();
  });
});
