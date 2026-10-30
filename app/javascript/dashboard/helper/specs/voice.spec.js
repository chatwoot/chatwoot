import {
  handleVoiceCallCreated,
  handleVoiceCallUpdated,
  loadRingingCalls,
  markCallDismissed,
  syncConversationCallVisibility,
} from '../voice';

import CallsAPI from 'dashboard/api/calls';

const { callsStore } = vi.hoisted(() => ({
  callsStore: {
    calls: [],
    addCall: vi.fn(),
    removeCall: vi.fn(),
    handleCallStatusChanged: vi.fn(),
  },
}));

vi.mock('dashboard/stores/calls', () => ({ useCallsStore: () => callsStore }));
vi.mock('dashboard/api/calls', () => ({ default: { get: vi.fn() } }));

const ME = 7;
const TEAMMATE = 8;

const callMessage = ({
  sid,
  provider = 'twilio',
  status = 'ringing',
  ringUserIds,
  assigneeId = null,
}) => ({
  content_type: 'voice_call',
  message_type: 0,
  conversation_id: 42,
  inbox_id: 3,
  conversation: { assignee_id: assigneeId },
  sender: { id: 99, name: 'Caller' },
  content_attributes: { data: { ring_user_ids: ringUserIds } },
  call: {
    provider_call_id: sid,
    id: 1,
    provider,
    status,
    direction: 'incoming',
  },
});

describe('voice call ringing', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    callsStore.calls = [];
  });

  it('rings an inbound Twilio call for the agents the server names, whoever is assigned', () => {
    handleVoiceCallCreated(
      callMessage({ sid: 'CA1', ringUserIds: [ME], assigneeId: TEAMMATE }),
      ME,
      true
    );
    handleVoiceCallCreated(
      callMessage({ sid: 'CA2', ringUserIds: [TEAMMATE], assigneeId: ME }),
      ME,
      true
    );

    expect(callsStore.addCall).toHaveBeenCalledTimes(1);
    expect(callsStore.addCall).toHaveBeenCalledWith(
      expect.objectContaining({ callSid: 'CA1' })
    );
  });

  it('adds the card when the ring reaches this agent and drops it when they leave the ring', () => {
    const commit = vi.fn();
    handleVoiceCallUpdated(
      commit,
      callMessage({ sid: 'CA3', ringUserIds: [TEAMMATE, ME] }),
      ME,
      true
    );
    expect(callsStore.addCall).toHaveBeenCalledWith(
      expect.objectContaining({ callSid: 'CA3' })
    );

    handleVoiceCallUpdated(
      commit,
      callMessage({ sid: 'CA3', ringUserIds: [TEAMMATE] }),
      ME,
      true
    );
    expect(callsStore.removeCall).toHaveBeenCalledWith('CA3');
  });

  it('keeps a card dismissed in another tab closed when the original ring arrives late', () => {
    handleVoiceCallUpdated(
      vi.fn(),
      callMessage({ sid: 'CA9', ringUserIds: [TEAMMATE] }),
      ME,
      true
    );
    handleVoiceCallCreated(
      callMessage({ sid: 'CA9', ringUserIds: [ME, TEAMMATE] }),
      ME,
      true
    );

    expect(callsStore.addCall).not.toHaveBeenCalled();
  });

  it('keeps a card this agent dismissed closed when the ring reaches another agent', () => {
    markCallDismissed('CA4');

    handleVoiceCallUpdated(
      vi.fn(),
      callMessage({ sid: 'CA4', ringUserIds: [ME, TEAMMATE] }),
      ME,
      true
    );

    expect(callsStore.addCall).not.toHaveBeenCalled();
  });

  it('leaves an answered Twilio call to the accepted and ended broadcasts', () => {
    handleVoiceCallUpdated(
      vi.fn(),
      callMessage({ sid: 'CA5', status: 'in-progress', ringUserIds: [] }),
      ME,
      true
    );

    expect(callsStore.removeCall).not.toHaveBeenCalled();
  });

  it('keeps a ringing Twilio card when its conversation is assigned to a teammate', () => {
    callsStore.calls = [
      {
        callSid: 'CA6',
        conversationId: 42,
        provider: 'twilio',
        callDirection: 'inbound',
      },
    ];

    syncConversationCallVisibility({ id: 42, assignee_id: TEAMMATE }, ME);

    expect(callsStore.removeCall).not.toHaveBeenCalled();
  });

  it('still hides a WhatsApp call assigned to another agent', () => {
    handleVoiceCallCreated(
      callMessage({ sid: 'WA1', provider: 'whatsapp', assigneeId: TEAMMATE }),
      ME,
      true
    );

    expect(callsStore.addCall).not.toHaveBeenCalled();
  });

  it('restores the Twilio calls ringing for this agent on page load', async () => {
    const ringing = (sid, extra = {}) => ({
      id: 1,
      call_id: sid,
      provider: 'twilio',
      direction: 'inbound',
      agent: null,
      conversation: { id: 501, display_id: 42 },
      inbox: { id: 3 },
      contact: { name: 'Caller', phone_number: '+15550100', avatar: '' },
      ...extra,
    });
    CallsAPI.get.mockResolvedValue({
      data: {
        payload: [
          ringing('CA7'),
          ringing('CA8', { agent: { id: TEAMMATE } }),
          ringing('WA2', { provider: 'whatsapp' }),
        ],
      },
    });

    await loadRingingCalls();

    expect(CallsAPI.get).toHaveBeenCalledWith({
      status: 'ringing',
      direction: 'inbound',
    });
    expect(callsStore.addCall).toHaveBeenCalledTimes(1);
    expect(callsStore.addCall).toHaveBeenCalledWith(
      expect.objectContaining({
        callSid: 'CA7',
        conversationId: 42,
        inboxId: 3,
        caller: expect.objectContaining({ name: 'Caller' }),
      })
    );
  });
});
