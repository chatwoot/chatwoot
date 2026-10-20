import { setActivePinia, createPinia } from 'pinia';
import { useCallsStore } from '../calls';

vi.mock('dashboard/api/channel/voice/twilioVoiceClient', () => ({
  default: { endClientCall: vi.fn() },
}));
vi.mock('dashboard/composables/useWhatsappCallSession', () => ({
  cleanupWhatsappSession: vi.fn(),
}));

describe('calls store hold state', () => {
  beforeEach(() => setActivePinia(createPinia()));

  it('marks the active call on hold and back', () => {
    const store = useCallsStore();
    store.addCall({ callSid: 'CA1', provider: 'twilio' });
    store.setCallActive('CA1');

    store.setCallOnHold('CA1', true);
    expect(store.activeCall.onHold).toBe(true);

    store.setCallOnHold('CA1', false);
    expect(store.activeCall.onHold).toBe(false);
  });

  it('starts a newly joined call off hold', () => {
    const store = useCallsStore();
    store.addCall({ callSid: 'CA1', provider: 'twilio' });
    store.setCallOnHold('CA1', true);

    store.setCallActive('CA1');

    expect(store.activeCall.onHold).toBe(false);
  });

  it('drops the hold state with the call when it ends', () => {
    const store = useCallsStore();
    store.addCall({ callSid: 'CA1', provider: 'twilio' });
    store.setCallActive('CA1');
    store.setCallOnHold('CA1', true);

    store.clearActiveCall();

    expect(store.activeCall).toBeNull();
    expect(store.calls).toEqual([]);
  });
});
