import {
  handleVoiceCallCreated,
  handleVoiceCallUpdated,
  loadRingingCalls,
  markCallDismissed,
  syncConversationCallVisibility,
  markLocalCall,
  clearLocalCall,
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
  dismissedUserIds = [],
  assigneeId = null,
}) => ({
  content_type: 'voice_call',
  message_type: 0,
  conversation_id: 42,
  inbox_id: 3,
  conversation: { assignee_id: assigneeId },
  sender: { id: 99, name: 'Caller' },
  content_attributes: {
    data: { ring_user_ids: ringUserIds, dismissed_user_ids: dismissedUserIds },
  },
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
      callMessage({
        sid: 'CA9',
        ringUserIds: [TEAMMATE],
        dismissedUserIds: [ME],
      }),
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

  it('shows the card once a widening ring reaches an agent it had not reached yet', () => {
    const commit = vi.fn();
    handleVoiceCallUpdated(
      commit,
      callMessage({ sid: 'CA15', ringUserIds: [TEAMMATE] }),
      ME,
      true
    );
    handleVoiceCallUpdated(
      commit,
      callMessage({ sid: 'CA15', ringUserIds: [TEAMMATE, ME] }),
      ME,
      true
    );

    expect(callsStore.addCall).toHaveBeenCalledWith(
      expect.objectContaining({ callSid: 'CA15' })
    );
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

  it('keeps the call this tab is joining when another tab dismisses it', () => {
    markLocalCall('CA14');

    handleVoiceCallUpdated(
      vi.fn(),
      callMessage({ sid: 'CA14', ringUserIds: [TEAMMATE] }),
      ME,
      true
    );
    clearLocalCall('CA14');

    expect(callsStore.removeCall).not.toHaveBeenCalled();
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

  it('drops a ringing Twilio card once the agent can no longer open its conversation, but not the call this tab is on', () => {
    callsStore.calls = [
      {
        callSid: 'CA12',
        conversationId: 42,
        provider: 'twilio',
        callDirection: 'inbound',
      },
      {
        callSid: 'CA13',
        conversationId: 42,
        provider: 'twilio',
        callDirection: 'inbound',
        isActive: true,
      },
    ];
    markLocalCall('CA13');

    syncConversationCallVisibility(
      { id: 42, assignee_id: TEAMMATE },
      ME,
      () => false
    );
    clearLocalCall('CA13');

    expect(callsStore.removeCall).toHaveBeenCalledTimes(1);
    expect(callsStore.removeCall).toHaveBeenCalledWith('CA12');

    // The dismiss outlives a late re-send of the ring
    handleVoiceCallCreated(
      callMessage({ sid: 'CA12', ringUserIds: [ME] }),
      ME,
      true
    );
    expect(callsStore.addCall).not.toHaveBeenCalled();
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
    CallsAPI.get
      .mockResolvedValueOnce({
        data: {
          meta: { total_pages: 2 },
          payload: [
            ringing('CA7'),
            ringing('CA8', { agent: { id: TEAMMATE } }),
            ringing('CA11', { agent: { id: ME } }),
            ringing('WA2', { provider: 'whatsapp' }),
          ],
        },
      })
      .mockResolvedValueOnce({
        data: { meta: { total_pages: 2 }, payload: [ringing('CA10')] },
      });

    await loadRingingCalls(ME);

    expect(CallsAPI.get).toHaveBeenCalledTimes(2);
    expect(CallsAPI.get).toHaveBeenCalledWith({
      status: 'ringing',
      direction: 'inbound',
      page: 2,
    });
    expect(callsStore.addCall).toHaveBeenCalledTimes(3);
    expect(callsStore.addCall).toHaveBeenCalledWith(
      expect.objectContaining({ callSid: 'CA10' })
    );
    expect(callsStore.addCall).toHaveBeenCalledWith(
      expect.objectContaining({ callSid: 'CA11' })
    );
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
