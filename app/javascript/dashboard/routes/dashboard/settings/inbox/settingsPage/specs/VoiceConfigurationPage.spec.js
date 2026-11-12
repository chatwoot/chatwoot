import { mount, flushPromises } from '@vue/test-utils';
import VoiceConfigurationPage from '../VoiceConfigurationPage.vue';
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
    setCallAnnouncement: vi.fn(),
    setCallRouting: vi.fn(),
    setCallRecording: vi.fn(),
  },
}));

const inbox = {
  id: 387,
  voice_enabled: true,
  api_key_sid: 'SK123',
  has_api_key_secret: true,
  account_auth_token_configured: true,
  account_sid: 'AC1234567890abcdef',
  inbound_calls_enabled: true,
  call_greeting_enabled: false,
  call_greeting_message: 'An old greeting',
  ring_strategy: 'simultaneous',
  ring_step_seconds: 20,
  assignee_rings_first: true,
  unanswered_call_timeout_seconds: 60,
  unanswered_call_message: 'Sorry, we missed you.',
  business_hours_calls_enabled: false,
  working_hours_enabled: true,
  call_cooldown_seconds: 0,
  recording_enabled: true,
  transcription_enabled: true,
};

const mountPage = (overrides = {}) =>
  mount(VoiceConfigurationPage, {
    props: { inbox: { ...inbox, ...overrides } },
    global: { stubs: { Icon: true, Spinner: true } },
  });

const saveButton = wrapper => wrapper.findAll('button').at(-1);
const greeting = wrapper => wrapper.find('#call-greeting-387');
const radio = (wrapper, value) =>
  wrapper.find(`input[type="radio"][value="${value}"]`);

describe('VoiceConfigurationPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    Object.values(InboxesAPI).forEach(fn => fn.mockResolvedValue({}));
  });

  it('shows a greeting that is off as an empty box', () => {
    expect(greeting(mountPage()).element.value).toBe('');
    expect(
      greeting(mountPage({ call_greeting_enabled: true })).element.value
    ).toBe('An old greeting');
  });

  it('shows the ring interval only when agents are added one at a time', async () => {
    const wrapper = mountPage();
    const selectCount = wrapper.findAll('select').length;

    await radio(wrapper, 'sequential').setValue(true);

    expect(wrapper.findAll('select')).toHaveLength(selectCount + 1);
  });

  it('keeps Save disabled until something changes', async () => {
    const wrapper = mountPage();
    expect(saveButton(wrapper).attributes('disabled')).toBeDefined();

    await greeting(wrapper).setValue('Welcome');

    expect(saveButton(wrapper).attributes('disabled')).toBeUndefined();
  });

  it('saves only the settings that changed, through the endpoint that owns each', async () => {
    const wrapper = mountPage();

    await greeting(wrapper).setValue(' Welcome to Acme ');
    await radio(wrapper, 'true').setValue(true);
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(InboxesAPI.setCallAnnouncement).toHaveBeenCalledTimes(1);
    expect(InboxesAPI.setCallAnnouncement).toHaveBeenCalledWith(
      387,
      'greeting',
      { enabled: true, message: 'Welcome to Acme' }
    );
    expect(InboxesAPI.setCallRouting).toHaveBeenCalledWith(
      387,
      expect.objectContaining({
        ringStrategy: 'simultaneous',
        businessHoursCallsEnabled: true,
      })
    );
    expect(InboxesAPI.setInboundCalls).not.toHaveBeenCalled();
    expect(InboxesAPI.setCallRecording).not.toHaveBeenCalled();
    expect(dispatch).toHaveBeenCalledWith('inboxes/get', 387);
  });

  it('turns the greeting off when its text is cleared', async () => {
    const wrapper = mountPage({ call_greeting_enabled: true });

    await greeting(wrapper).setValue('');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(InboxesAPI.setCallAnnouncement).toHaveBeenCalledWith(
      387,
      'greeting',
      { enabled: false, message: '' }
    );
  });

  it('saves the missed-call message with its ring time', async () => {
    const wrapper = mountPage();

    await wrapper.find('#call-missed-message-387').setValue('Call back later');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(InboxesAPI.setCallAnnouncement).toHaveBeenCalledWith(
      387,
      'unanswered',
      { enabled: true, message: 'Call back later', timeoutSeconds: 60 }
    );
  });

  it('shows the server message when a save is refused', async () => {
    InboxesAPI.setCallAnnouncement.mockRejectedValue({
      response: { data: { error: 'Add the message callers hear' } },
    });
    const wrapper = mountPage();

    await greeting(wrapper).setValue('Hi');
    await saveButton(wrapper).trigger('click');
    await flushPromises();

    expect(alert).toHaveBeenCalledWith('Add the message callers hear');
  });

  it('keeps a saved wrap-up time that is not one of the choices', () => {
    const wrapper = mountPage({ call_cooldown_seconds: 45 });
    const wrapUp = wrapper.findAll('select').at(-1);

    expect(
      wrapUp.findAll('option').map(option => option.element.value)
    ).toEqual(['0', '30', '45', '60', '120', '300', '600']);
    expect(wrapUp.element.value).toBe('45');
  });

  it('only shows the connection while calling is off', () => {
    const wrapper = mountPage({ voice_enabled: false });

    expect(wrapper.find('#call-greeting-387').exists()).toBe(false);
    expect(wrapper.findAll('button')).toHaveLength(0);
  });
});
