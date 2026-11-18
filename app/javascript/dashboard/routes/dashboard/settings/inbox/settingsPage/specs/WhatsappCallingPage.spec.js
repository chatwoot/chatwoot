import { mount, flushPromises } from '@vue/test-utils';
import WhatsappCallingPage from '../WhatsappCallingPage.vue';
import CallBusinessHours from '../calls/CallBusinessHours.vue';
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
    enableWhatsappCalling: vi.fn(),
    disableWhatsappCalling: vi.fn(),
    syncWhatsappCallHours: vi.fn(),
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
  timezone: 'America/Los_Angeles',
  working_hours: [
    {
      day_of_week: 1,
      closed_all_day: false,
      open_all_day: false,
      open_hour: 9,
      open_minutes: 0,
      close_hour: 17,
      close_minutes: 0,
    },
  ],
  call_hours_sync_status: null,
  call_hours_sync_error: null,
  call_cooldown_seconds: 0,
  recording_enabled: true,
  transcription_enabled: true,
  provider_config: { calling_enabled: true, call_permission_request_body: '' },
};

const mountPage = (overrides = {}) =>
  mount(WhatsappCallingPage, {
    props: { inbox: { ...inbox, ...overrides } },
    global: { stubs: { Icon: true, Spinner: true } },
  });

const saveButton = wrapper => wrapper.findAll('button').at(-1);
const businessHoursSwitch = wrapper => wrapper.find('button[role="switch"]');
const outOfHoursKey = key => `INBOX_MGMT.CALL_SETTINGS.OUT_OF_HOURS.${key}`;

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

  it('applies business hours with the toggle Twilio uses, without an out-of-hours message', () => {
    const wrapper = mountPage({ business_hours_calls_enabled: true });

    expect(businessHoursSwitch(wrapper).attributes('aria-checked')).toBe(
      'true'
    );
    expect(wrapper.text()).toContain(outOfHoursKey('WHATSAPP_APPLY_HELP'));
    expect(wrapper.text()).toContain('09:00–17:00 · America/Los_Angeles');
    expect(wrapper.find('#call-out-of-hours-message-52').exists()).toBe(false);
  });

  it('opens the Business hours tab from the hours summary', async () => {
    const wrapper = mountPage({ business_hours_calls_enabled: true });
    // The hours summary's only button is Edit hours, after the switch
    const editHours = wrapper
      .findComponent(CallBusinessHours)
      .findAll('button')
      .at(-1);

    await editHours.trigger('click');

    expect(wrapper.emitted('openBusinessHours')).toHaveLength(1);
  });

  it('saves who rings and business hours through the same endpoint as Twilio', async () => {
    const wrapper = mountPage();
    expect(saveButton(wrapper).attributes('disabled')).toBeDefined();

    await wrapper.find('#call-routing-sequential-52').setValue(true);
    await businessHoursSwitch(wrapper).trigger('click');
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
    expect(dispatch).toHaveBeenCalledWith('inboxes/getItem', 52);
  });

  it('saves the permission message', async () => {
    const wrapper = mountPage();
    await wrapper
      .find('#call-permission-request-52')
      .setValue(' Can we call? ');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

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

  describe('call hours on WhatsApp', () => {
    const applied = { business_hours_calls_enabled: true };

    it('says when WhatsApp is using the hours', () => {
      const wrapper = mountPage({
        ...applied,
        call_hours_sync_status: 'synced',
      });

      expect(wrapper.text()).toContain(outOfHoursKey('WHATSAPP_SYNC_DONE'));
    });

    it('says nothing once the hours are no longer applied', () => {
      const wrapper = mountPage({ call_hours_sync_status: 'synced' });

      expect(wrapper.text()).not.toContain(outOfHoursKey('WHATSAPP_SYNC_DONE'));
    });

    it('shows a failed sync and retries it', async () => {
      const wrapper = mountPage({
        ...applied,
        call_hours_sync_status: 'failed',
        call_hours_sync_error: 'Invalid timezone_id',
      });
      expect(wrapper.text()).toContain(outOfHoursKey('WHATSAPP_SYNC_FAILED'));

      const retry = wrapper.find('.bg-n-ruby-2 button');
      await retry.trigger('click');
      await flushPromises();

      expect(InboxesAPI.syncWhatsappCallHours).toHaveBeenCalledWith(52);
      expect(dispatch).toHaveBeenCalledWith('inboxes/getItem', 52);
    });

    describe('while a sync is in progress', () => {
      beforeEach(() => vi.useFakeTimers());
      afterEach(() => vi.useRealTimers());

      it('rechecks the inbox a limited number of times', async () => {
        const wrapper = mountPage({
          ...applied,
          call_hours_sync_status: 'pending',
        });
        expect(wrapper.text()).toContain(
          outOfHoursKey('WHATSAPP_SYNC_PENDING')
        );

        // Each refetch hands the page a new inbox that is still pending
        for (let poll = 0; poll < 12; poll += 1) {
          vi.advanceTimersByTime(3000);
          // eslint-disable-next-line no-await-in-loop
          await wrapper.setProps({
            inbox: { ...wrapper.props('inbox'), ...applied },
          });
        }

        const refetches = dispatch.mock.calls.filter(
          ([action]) => action === 'inboxes/getItem'
        );
        expect(refetches).toHaveLength(10);
      });

      it('stops rechecking when the page closes', () => {
        const wrapper = mountPage({
          ...applied,
          call_hours_sync_status: 'pending',
        });

        wrapper.unmount();
        vi.advanceTimersByTime(3000);

        expect(dispatch).not.toHaveBeenCalled();
      });
    });
  });
});
