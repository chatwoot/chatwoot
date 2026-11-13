import { mount, flushPromises } from '@vue/test-utils';
import WhatsappCallingPage from '../WhatsappCallingPage.vue';
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
  default: {
    setInboundCalls: vi.fn(),
    setCallRouting: vi.fn(),
    setCallRecording: vi.fn(),
    setCallbackPermission: vi.fn(),
    enableWhatsappCalling: vi.fn(),
    disableWhatsappCalling: vi.fn(),
  },
}));

const inbox = {
  id: 52,
  inbound_calls_enabled: true,
  ring_strategy: 'simultaneous',
  ring_step_seconds: 20,
  assignee_rings_first: true,
  business_hours_calls_enabled: false,
  working_hours_enabled: true,
  call_cooldown_seconds: 0,
  recording_enabled: true,
  transcription_enabled: true,
  callback_permission_enabled: false,
  provider_config: { calling_enabled: true, call_permission_request_body: '' },
};

const mountPage = (overrides = {}) =>
  mount(WhatsappCallingPage, {
    props: { inbox: { ...inbox, ...overrides } },
    global: { stubs: { Icon: true, Spinner: true } },
  });

const saveButton = wrapper => wrapper.findAll('button').at(-1);
const radio = (wrapper, value) =>
  wrapper.find(`input[type="radio"][value="${value}"]`);

describe('WhatsappCallingPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    Object.values(InboxesAPI).forEach(fn => fn.mockResolvedValue({}));
    dispatch.mockResolvedValue({});
  });

  it('shows no greeting or missed-call message, which WhatsApp calls cannot play', () => {
    const wrapper = mountPage();

    expect(wrapper.find('#call-greeting-52').exists()).toBe(false);
    expect(wrapper.find('#call-missed-message-52').exists()).toBe(false);
  });

  it('offers only declining or ringing as usual outside business hours', () => {
    const outOfHours = mountPage().findAll(
      'input[name="call-out-of-hours-52"]'
    );

    expect(outOfHours).toHaveLength(2);
  });

  it('saves who rings and business hours through the same endpoint as Twilio', async () => {
    const wrapper = mountPage();
    expect(saveButton(wrapper).attributes('disabled')).toBeDefined();

    await wrapper.find('#call-routing-sequential-52').setValue(true);
    await radio(wrapper, 'true').setValue(true);
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(InboxesAPI.setCallRouting).toHaveBeenCalledWith(
      52,
      expect.objectContaining({
        ringStrategy: 'sequential',
        ringStepSeconds: 20,
        businessHoursCallsEnabled: true,
      })
    );
    expect(InboxesAPI.setCallbackPermission).not.toHaveBeenCalled();
    expect(dispatch).toHaveBeenCalledWith('inboxes/get', 52);
  });

  it('saves the callback setting and the permission message', async () => {
    const wrapper = mountPage();
    const checkboxes = wrapper.findAll('input[type="checkbox"]');

    await checkboxes.at(-1).setValue(true);
    await wrapper
      .find('#call-permission-request-52')
      .setValue(' Can we call? ');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(InboxesAPI.setCallbackPermission).toHaveBeenCalledWith(52, true);
    expect(dispatch).toHaveBeenCalledWith('inboxes/updateInbox', {
      id: 52,
      formData: false,
      channel: {
        provider_config: {
          ...inbox.provider_config,
          call_permission_request_body: 'Can we call?',
        },
      },
    });
    expect(InboxesAPI.setCallRouting).not.toHaveBeenCalled();
  });

  it('turns WhatsApp calling off straight away', async () => {
    const wrapper = mountPage();
    // The first button turns calling off; the last saves the form
    await wrapper.findAll('button').at(0).trigger('click');
    await flushPromises();

    expect(InboxesAPI.disableWhatsappCalling).toHaveBeenCalledWith(52);
  });

  it('only offers to turn calling on while it is off', () => {
    const wrapper = mountPage({ provider_config: { calling_enabled: false } });

    expect(wrapper.findAll('input[type="checkbox"]')).toHaveLength(1);
    expect(wrapper.findAll('button')).toHaveLength(0);
  });
});
