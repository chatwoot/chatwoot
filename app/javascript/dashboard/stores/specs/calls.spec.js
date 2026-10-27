import { setActivePinia, createPinia } from 'pinia';
import { useCallsStore } from '../calls';

describe('calls store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it('applies a status that arrived before the call was added', () => {
    const store = useCallsStore();

    store.handleCallStatusChanged({ callSid: 'CA1', status: 'in-progress' });
    store.addCall({ callSid: 'CA1', conversationId: 12 });

    expect(store.calls[0].status).toBe('in-progress');
    expect(store.pendingStatuses).toEqual({});
  });

  it('forgets an early status once the call ends', () => {
    const store = useCallsStore();

    store.handleCallStatusChanged({ callSid: 'CA1', status: 'in-progress' });
    store.handleCallStatusChanged({ callSid: 'CA1', status: 'completed' });
    store.addCall({ callSid: 'CA1', conversationId: 12 });

    expect(store.calls[0].status).toBeUndefined();
  });
});
