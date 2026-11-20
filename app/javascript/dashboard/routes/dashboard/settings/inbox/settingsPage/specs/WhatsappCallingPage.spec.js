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
    getWhatsappCallHours: vi.fn(),
    applyWhatsappCallHours: vi.fn(),
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

  it('can save again when refreshing the inbox fails', async () => {
    dispatch.mockRejectedValue(new Error('offline'));
    const wrapper = mountPage();

    await wrapper.find('#call-routing-sequential-52').setValue(true);
    await saveButton(wrapper).trigger('click');
    await flushPromises();
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(InboxesAPI.setCallRouting).toHaveBeenCalledTimes(2);
  });

  it('keeps calling off once turned off, even if refreshing the inbox fails', async () => {
    dispatch.mockRejectedValue(new Error('offline'));
    const wrapper = mountPage();

    await wrapper.findAll('button').at(0).trigger('click');
    await flushPromises();

    expect(alert).toHaveBeenCalledWith('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE');
    expect(wrapper.find('#call-routing-sequential-52').exists()).toBe(false);
  });

  it('saves the permission message before business hours, so it cannot undo them', async () => {
    const order = [];
    dispatch.mockImplementation(action => {
      order.push(action);
      return Promise.resolve({});
    });
    InboxesAPI.setCallRouting.mockImplementation(() => {
      order.push('setCallRouting');
      return Promise.resolve({});
    });
    const wrapper = mountPage();

    await businessHoursSwitch(wrapper).trigger('click');
    await wrapper.find('#call-permission-request-52').setValue('Can we call?');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(order.slice(0, 2)).toEqual([
      'inboxes/updateInbox',
      'setCallRouting',
    ]);
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

  it('saves the permission message before the call settings, so its whole provider_config does not overwrite them', async () => {
    const wrapper = mountPage();
    await wrapper.find('#call-routing-sequential-52').setValue(true);
    await wrapper.find('#call-permission-request-52').setValue('Can we call?');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    const updateInboxOrder =
      dispatch.mock.invocationCallOrder[
        dispatch.mock.calls.findIndex(
          ([action]) => action === 'inboxes/updateInbox'
        )
      ];
    const [routingOrder] = InboxesAPI.setCallRouting.mock.invocationCallOrder;
    expect(updateInboxOrder).toBeLessThan(routingOrder);
  });

  it('turns WhatsApp calling off straight away', async () => {
    const wrapper = mountPage();
    await wrapper.findAll('button').at(0).trigger('click');
    await flushPromises();

    expect(InboxesAPI.disableWhatsappCalling).toHaveBeenCalledWith(52);
  });

  it("explains why calling couldn't be turned on when WhatsApp refuses the hours", async () => {
    InboxesAPI.enableWhatsappCalling.mockRejectedValue({
      response: { data: { message: 'Invalid timezone_id' } },
    });
    const wrapper = mountPage({ provider_config: { calling_enabled: false } });

    await wrapper.find('input[type="checkbox"]').setValue(true);
    await flushPromises();

    expect(alert).toHaveBeenCalledWith('Invalid timezone_id');
  });

  it('only offers to turn calling on while it is off', () => {
    const wrapper = mountPage({ provider_config: { calling_enabled: false } });

    expect(wrapper.findAll('input[type="checkbox"]')).toHaveLength(1);
    expect(wrapper.findAll('button')).toHaveLength(0);
  });

  describe('when WhatsApp may have other hours', () => {
    const applied = { business_hours_calls_enabled: true };
    const differKey = outOfHoursKey('WHATSAPP_HOURS_DIFFER');
    const appliedKey = outOfHoursKey('WHATSAPP_HOURS_APPLIED');

    it('checks WhatsApp when the tab opens and offers to apply the inbox hours', async () => {
      InboxesAPI.getWhatsappCallHours.mockResolvedValue({
        data: { matches_whatsapp: false },
      });
      const wrapper = mountPage(applied);
      await flushPromises();

      expect(InboxesAPI.getWhatsappCallHours).toHaveBeenCalledWith(52);
      expect(wrapper.text()).toContain(differKey);

      await wrapper.find('.bg-n-amber-2 button').trigger('click');
      await flushPromises();

      expect(InboxesAPI.applyWhatsappCallHours).toHaveBeenCalledWith(52);
      expect(wrapper.text()).not.toContain(differKey);
      expect(wrapper.text()).toContain(appliedKey);
    });

    it('says the hours are applied when WhatsApp has the inbox hours', async () => {
      InboxesAPI.getWhatsappCallHours.mockResolvedValue({
        data: { matches_whatsapp: true },
      });
      const wrapper = mountPage(applied);
      await flushPromises();

      expect(wrapper.text()).toContain(appliedKey);
      expect(wrapper.text()).not.toContain(differKey);
    });

    it('shows the check and the update while they run', async () => {
      let finishCheck;
      InboxesAPI.getWhatsappCallHours.mockReturnValue(
        new Promise(resolve => {
          finishCheck = resolve;
        })
      );
      const wrapper = mountPage(applied);
      await flushPromises();

      expect(wrapper.text()).toContain(
        outOfHoursKey('WHATSAPP_HOURS_CHECKING')
      );

      finishCheck({ data: { matches_whatsapp: false } });
      await flushPromises();
      InboxesAPI.applyWhatsappCallHours.mockReturnValue(new Promise(() => {}));
      await wrapper.find('.bg-n-amber-2 button').trigger('click');

      expect(wrapper.text()).toContain(
        outOfHoursKey('WHATSAPP_HOURS_APPLYING')
      );
      expect(wrapper.text()).not.toContain(differKey);
    });

    it('claims nothing when WhatsApp cannot be reached', async () => {
      InboxesAPI.getWhatsappCallHours.mockRejectedValue(new Error('down'));
      const wrapper = mountPage(applied);
      await flushPromises();

      expect(wrapper.text()).not.toContain(appliedKey);
      expect(wrapper.text()).not.toContain(differKey);
    });

    it('does not check while calling is off', async () => {
      mountPage({ provider_config: { calling_enabled: false } });
      await flushPromises();

      expect(InboxesAPI.getWhatsappCallHours).not.toHaveBeenCalled();
    });

    it('offers to turn call hours off when WhatsApp still applies them but the inbox does not', async () => {
      InboxesAPI.getWhatsappCallHours.mockResolvedValue({
        data: { matches_whatsapp: false },
      });
      const wrapper = mountPage();
      await flushPromises();

      expect(wrapper.text()).toContain(
        outOfHoursKey('WHATSAPP_HOURS_STILL_ON')
      );
      expect(wrapper.text()).not.toContain(differKey);

      await wrapper.find('.bg-n-amber-2 button').trigger('click');
      await flushPromises();

      expect(InboxesAPI.applyWhatsappCallHours).toHaveBeenCalledWith(52);
      expect(wrapper.text()).not.toContain(
        outOfHoursKey('WHATSAPP_HOURS_STILL_ON')
      );
      expect(wrapper.text()).not.toContain(appliedKey);
    });

    it('keeps the note when WhatsApp refuses the inbox hours', async () => {
      InboxesAPI.getWhatsappCallHours.mockResolvedValue({
        data: { matches_whatsapp: false },
      });
      InboxesAPI.applyWhatsappCallHours.mockRejectedValue({
        response: { data: { message: 'Invalid timezone_id' } },
      });
      const wrapper = mountPage(applied);
      await flushPromises();

      await wrapper.find('.bg-n-amber-2 button').trigger('click');
      await flushPromises();

      expect(alert).toHaveBeenCalledWith('Invalid timezone_id');
      expect(wrapper.text()).toContain(differKey);
    });
  });
});
