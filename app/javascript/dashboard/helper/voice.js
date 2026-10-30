import {
  CONTENT_TYPES,
  VOICE_CALL_DIRECTION,
  VOICE_CALL_STATUS,
} from 'dashboard/components-next/message/constants';
import CallsAPI from 'dashboard/api/calls';
import { MESSAGE_TYPE } from 'shared/constants/messages';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import { useCallsStore } from 'dashboard/stores/calls';
import types from 'dashboard/store/mutation-types';

export const TERMINAL_STATUSES = [
  'completed',
  'busy',
  'failed',
  'rejected',
  'no-answer',
  'canceled',
  'missed',
  'ended',
];

// A message.created for a ringing call is queued through ActionCableBroadcastJob and can
// be delivered after the call has already been accepted/ended via a synchronous broadcast.
// Track dismissed call sids at module scope so that late, stale "ringing" snapshot doesn't
// resurrect a card every caller of handleVoiceCallCreated (hydration and real-time alike)
// has already cleared.
const dismissedCallSids = new Set();
export const markCallDismissed = callSid => {
  if (callSid) dismissedCallSids.add(callSid);
};

// Which Twilio call (if any) this tab is actively joining/owns. Must be set
// synchronously BEFORE the join API call — mirrors useWhatsappCallSession's
// activeCallId — so the account-wide voice_call.accepted broadcast (which can
// arrive before the join promise resolves) doesn't mistake this tab's own
// call for a sibling tab's and tear it down mid-join.
let localCallSid = null;
export const markLocalCall = callSid => {
  localCallSid = callSid || null;
};
export const isLocalCall = callSid =>
  !!callSid && localCallSid != null && callSid === localCallSid;
export const clearLocalCall = callSid => {
  if (localCallSid === callSid) localCallSid = null;
};

export const isInbound = direction => direction === 'inbound';

const isVoiceCallMessage = message => {
  return CONTENT_TYPES.VOICE_CALL === message?.content_type;
};

const shouldSkipCall = (callDirection, senderId, currentUserId) => {
  return callDirection === 'outbound' && senderId !== currentUserId;
};

const extractAssigneeId = conversation => {
  return conversation?.assignee_id || conversation?.meta?.assignee?.id || null;
};

const isAssignedToAnotherAgent = (assigneeId, currentUserId) => {
  if (currentUserId == null) return false;
  return !!assigneeId && assigneeId !== currentUserId;
};

// The server picks the agents an inbound Twilio call rings and names them on the
// call's message, so its assignee no longer decides who sees the ringing card.
const isRoutedCall = (provider, callDirection) =>
  provider === VOICE_CALL_PROVIDERS.TWILIO &&
  callDirection === VOICE_CALL_DIRECTION.INBOUND;

const shouldShowCall = ({
  callDirection,
  senderId,
  assigneeId,
  currentUserId,
  provider,
  status,
  ringUserIds,
}) => {
  if (shouldSkipCall(callDirection, senderId, currentUserId)) return false;
  // Outbound calls are scoped to the initiator via shouldSkipCall; the
  // conversation may be auto-assigned to a different agent on creation, so
  // skip the assignee filter for outbound to avoid hiding the caller's own widget.
  if (callDirection === 'outbound') return true;
  // Once the ring is over the accepted/ended broadcasts decide what each tab keeps
  if (isRoutedCall(provider, callDirection)) {
    return (
      status !== VOICE_CALL_STATUS.RINGING ||
      (ringUserIds || []).includes(currentUserId)
    );
  }
  return !isAssignedToAnotherAgent(assigneeId, currentUserId);
};

// Agents who are not online or have turned calls off get no ringing popup for
// inbound calls, but outbound calls always belong to the initiator, and existing
// (already-surfaced) calls keep going so a status change mid-call doesn't yank
// away an active widget.
const shouldRingInbound = (callDirection, receivesCalls) => {
  if (callDirection === 'outbound') return true;
  return receivesCalls;
};

function extractCallerSnapshot(message) {
  // Snapshot caller info from the message at add-time so the widget can keep
  // rendering it after the user navigates away from a conversation list that
  // had the conversation hydrated (and Vuex evicts it from the store).
  // Only incoming messages carry the contact as the sender; on outbound calls
  // the sender is the initiating agent, so skip the snapshot and let the widget
  // fall back to the conversation's contact (conversation.meta.sender).
  if (message?.message_type !== MESSAGE_TYPE.INCOMING) return null;
  const sender = message?.sender;
  if (!sender) return null;
  return {
    name: sender.name,
    phone: sender.phone_number,
    avatar: sender.avatar || sender.thumbnail,
    additionalAttributes: sender.additional_attributes || {},
  };
}

function extractCallData(message) {
  const call = message?.call || {};
  return {
    callSid: call.provider_call_id,
    callId: call.id,
    provider: call.provider,
    status: call.status,
    callDirection: call.direction === 'outgoing' ? 'outbound' : 'inbound',
    conversationId: message?.conversation_id,
    inboxId: message?.inbox_id ?? message?.conversation?.inbox_id,
    assigneeId: extractAssigneeId(message?.conversation),
    senderId: message?.sender?.id,
    ringUserIds: message?.content_attributes?.data?.ring_user_ids,
    caller: extractCallerSnapshot(message),
  };
}

export function handleVoiceCallCreated(message, currentUserId, receivesCalls) {
  if (!isVoiceCallMessage(message)) return;

  const {
    callSid,
    callId,
    provider,
    status,
    callDirection,
    conversationId,
    inboxId,
    assigneeId,
    senderId,
    ringUserIds,
  } = extractCallData(message);

  if (callSid && dismissedCallSids.has(callSid)) return;

  // A voice_call message can be created already terminal when the caller hangs
  // up before connect. Only ring while the call is actually ringing; mirrors the
  // guard in seedCallsFromHydratedMessages.
  if (status !== VOICE_CALL_STATUS.RINGING) return;

  if (
    !shouldShowCall({
      callDirection,
      senderId,
      assigneeId,
      currentUserId,
      provider,
      status,
      ringUserIds,
    })
  ) {
    return;
  }

  if (!shouldRingInbound(callDirection, receivesCalls)) return;

  const callsStore = useCallsStore();
  callsStore.addCall({
    callSid,
    callId,
    provider,
    conversationId,
    inboxId,
    callDirection,
    senderId,
    caller: extractCallerSnapshot(message),
  });
}

// A routed call rings agents whose conversation list may not hold its conversation, and the
// call widget mounts only once a call is in the store, so a page load asks the server for the
// calls ringing for this agent
export async function loadRingingCalls() {
  const { data } = await CallsAPI.get({
    status: VOICE_CALL_STATUS.RINGING,
    direction: VOICE_CALL_DIRECTION.INBOUND,
  });
  const callsStore = useCallsStore();
  data.payload
    .filter(
      call =>
        isRoutedCall(call.provider, call.direction) &&
        !call.agent &&
        !dismissedCallSids.has(call.call_id)
    )
    .forEach(call => {
      callsStore.addCall({
        callSid: call.call_id,
        callId: call.id,
        provider: call.provider,
        conversationId: call.conversation.display_id,
        inboxId: call.inbox.id,
        callDirection: call.direction,
        caller: call.contact && {
          name: call.contact.name,
          phone: call.contact.phone_number,
          avatar: call.contact.avatar,
          additionalAttributes: {},
        },
      });
    });
}

export function handleVoiceCallUpdated(
  commit,
  message,
  currentUserId,
  receivesCalls
) {
  if (!isVoiceCallMessage(message)) return;

  const {
    callSid,
    callId,
    provider,
    status,
    callDirection,
    conversationId,
    inboxId,
    assigneeId,
    senderId,
    ringUserIds,
  } = extractCallData(message);

  const callsStore = useCallsStore();

  // Guard against a still-queued ringing message.created arriving after this
  // terminal update, same as the accepted/ended broadcast handlers.
  if (TERMINAL_STATUSES.includes(status)) markCallDismissed(callSid);

  callsStore.handleCallStatusChanged({ callSid, status, conversationId });

  commit(types.UPDATE_MESSAGE_CALL_STATUS, {
    conversationId,
    callStatus: status,
    callSid,
  });

  if (
    !shouldShowCall({
      callDirection,
      senderId,
      assigneeId,
      currentUserId,
      provider,
      status,
      ringUserIds,
    })
  ) {
    callsStore.removeCall(callSid);
    return;
  }

  if (status === 'ringing') {
    // A ring that reached another agent re-sends the call, which a dismiss here must survive
    if (isRoutedCall(provider, callDirection) && dismissedCallSids.has(callSid))
      return;
    if (!shouldRingInbound(callDirection, receivesCalls)) return;

    callsStore.addCall({
      callSid,
      callId,
      provider,
      conversationId,
      inboxId,
      callDirection,
      senderId,
      caller: extractCallerSnapshot(message),
    });
  }
}

export function syncConversationCallVisibility(conversation, currentUserId) {
  const assigneeId = extractAssigneeId(conversation);
  if (!isAssignedToAnotherAgent(assigneeId, currentUserId)) return;

  // Outbound calls belong to the initiator regardless of who the conversation
  // is currently assigned to (auto-assignment may flip mid-call). Mirror
  // shouldShowCall's outbound exception so an in-progress outbound call isn't
  // ripped out from under the caller when the conversation reassigns.
  const callsStore = useCallsStore();
  const callsToRemove = callsStore.calls.filter(
    call =>
      call.conversationId === conversation.id &&
      !isRoutedCall(call.provider, call.callDirection) &&
      !shouldShowCall({
        callDirection: call.callDirection,
        senderId: call.senderId,
        assigneeId,
        currentUserId,
      })
  );
  callsToRemove.forEach(call => callsStore.removeCall(call.callSid));
}
