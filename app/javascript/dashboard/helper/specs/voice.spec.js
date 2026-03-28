import { createPinia, setActivePinia } from 'pinia';
import { CONTENT_TYPES } from 'dashboard/components-next/message/constants';
import { useCallsStore } from 'dashboard/stores/calls';
import {
  handleVoiceCallCreated,
  handleVoiceCallUpdated,
  syncConversationCallVisibility,
} from '../voice';

vi.mock('dashboard/api/channel/voice/twilioVoiceClient', () => ({
  default: {
    endClientCall: vi.fn(),
  },
}));

const buildVoiceMessage = overrides => ({
  content_type: CONTENT_TYPES.VOICE_CALL,
  content_attributes: {
    data: {
      call_sid: 'CALL123',
      status: 'ringing',
      call_direction: 'inbound',
    },
  },
  conversation_id: 42,
  conversation: {
    assignee_id: null,
  },
  sender: {
    id: 7,
  },
  ...overrides,
});

describe('voice helper', () => {
  const commit = vi.fn();

  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  it('shows inbound calls to everyone when the conversation is unassigned', () => {
    const callsStore = useCallsStore();

    handleVoiceCallCreated(buildVoiceMessage(), 1);

    expect(callsStore.calls).toEqual([
      expect.objectContaining({
        callSid: 'CALL123',
        conversationId: 42,
      }),
    ]);
  });

  it('hides inbound calls when they are assigned to another agent', () => {
    const callsStore = useCallsStore();

    handleVoiceCallCreated(
      buildVoiceMessage({
        conversation: {
          assignee_id: 9,
        },
      }),
      1
    );

    expect(callsStore.calls).toEqual([]);
  });

  it('removes a visible call when an update shows it is assigned to another agent', () => {
    const callsStore = useCallsStore();
    callsStore.addCall({
      callSid: 'CALL123',
      conversationId: 42,
      callDirection: 'inbound',
      senderId: 7,
    });

    handleVoiceCallUpdated(
      commit,
      buildVoiceMessage({
        conversation: {
          assignee_id: 9,
        },
      }),
      1
    );

    expect(callsStore.calls).toEqual([]);
  });

  it('removes the call widget when the conversation assignment changes to another agent', () => {
    const callsStore = useCallsStore();
    callsStore.addCall({
      callSid: 'CALL123',
      conversationId: 42,
      callDirection: 'inbound',
      senderId: 7,
    });

    syncConversationCallVisibility(
      {
        id: 42,
        meta: {
          assignee: {
            id: 9,
          },
        },
      },
      1
    );

    expect(callsStore.calls).toEqual([]);
  });
});
