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
  assignee_rings_first: true,
  call_cooldown_seconds: 0,
};

const mountComponent = (overrides = {}) =>
  mount(CallRoutingSettings, {
    props: { inbox: { ...inbox, ...overrides } },
    global: { stubs: { Icon: true, Spinner: true } },
  });

const save = wrapper => wrapper.findAll('button').at(-1);

describe('CallRoutingSettings', () => {
  beforeEach(() => vi.clearAllMocks());

  it('shows the ring interval only when agents are added one at a time', async () => {
    const wrapper = mountComponent();
    expect(wrapper.findAll('select')).toHaveLength(1);

    await wrapper.find('#call-routing-sequential-387').setValue(true);

    expect(wrapper.findAll('select')).toHaveLength(2);
  });

  it('saves every setting together and refreshes the inbox', async () => {
    InboxesAPI.setCallRouting.mockResolvedValue({});
    const wrapper = mountComponent();
    expect(save(wrapper).attributes('disabled')).toBeDefined();

    await wrapper.find('#call-routing-sequential-387').setValue(true);
    const [step, wrapUp] = wrapper.findAll('select');
    await step.setValue('15');
    await wrapper.find('input[type="checkbox"]').setValue(false);
    await wrapUp.setValue('120');
    await save(wrapper).trigger('click');
    await flushPromises();

    expect(InboxesAPI.setCallRouting).toHaveBeenCalledWith(387, {
      ringStrategy: 'sequential',
      ringStepSeconds: 15,
      assigneeRingsFirst: false,
      callCooldownSeconds: 120,
    });
    expect(dispatch).toHaveBeenCalledWith('inboxes/get', 387);
  });

  it('keeps a saved wrap-up time that is not one of the choices', () => {
    const wrapper = mountComponent({ call_cooldown_seconds: 45 });
    const values = wrapper
      .find('select')
      .findAll('option')
      .map(option => option.element.value);

    expect(values).toEqual(['0', '30', '45', '60', '120', '300', '600']);
  });

  it("shows the server's error when the settings are refused", async () => {
    InboxesAPI.setCallRouting.mockRejectedValue({
      response: { data: { message: 'Choose a wrap-up time of 0 to 600' } },
    });
    const wrapper = mountComponent();

    await wrapper.find('select').setValue('30');
    await save(wrapper).trigger('click');
    await flushPromises();

    expect(alert).toHaveBeenCalledWith('Choose a wrap-up time of 0 to 600');
    expect(dispatch).not.toHaveBeenCalled();
  });
});
