import getUuid from 'widget/helpers/uuid';
import AutonomiaBuildThreadsAPI from '../../api/autonomia/buildThreads';
import { throwErrorMessage } from 'dashboard/store/utils/api';

// The Builder conversation. Generation is ASYNCHRONOUS: create/send return 202
// with status `processing`; we poll `show` until it settles.
//
// IMPORTANT — the interview is MULTI-TURN. The backend `status` enum is
// `open | processing | ready | failed`, but `ready` has TWO meanings carried by
// the filtered `state` (needs_more_info | next_question | turn):
//   ready + needs_more_info=true  -> the AI still needs info. NO agent exists
//                                    yet (agent_id is nil). `next_question` holds
//                                    the next interview question, which the
//                                    backend does NOT push into `messages` — the
//                                    front renders it as an assistant turn and
//                                    re-opens the conversation so the user can
//                                    answer (their reply triggers a new build).
//   ready + needs_more_info=false -> the agent was created (agent_id set). We
//                                    fetch it and surface the review card.
// We normalize this into a UI `phase` (interviewing | reviewing) so the page
// never mistakes "thread ready" for "agent ready".
//
// IP OCULTO: we only ever surface messages + the filtered `state`; the backend
// never emits instruction/scaffold here.
const POLL_INTERVAL = 3000;
const POLL_MAX_ATTEMPTS = 120; // ~6 minutes ceiling

let pollTimer = null;

// T6 — idempotency id per TURN (not per request): minted when the user sends a
// message and reused while that exact turn is unconfirmed (double-click,
// network replay, resend after 409/failure), so the backend can dedupe the
// replayed submit. Cleared once the backend accepts the turn — a LATER answer
// with identical content (e.g. "sim" twice in the interview) gets a fresh id
// and is never swallowed by the dedupe.
let pendingTurn = null;

const clientIdForTurn = (threadId, content) => {
  if (
    pendingTurn &&
    pendingTurn.threadId === threadId &&
    pendingTurn.content === content
  ) {
    return pendingTurn.clientMessageId;
  }
  pendingTurn = { threadId, content, clientMessageId: getUuid() };
  return pendingTurn.clientMessageId;
};

export const state = {
  thread: null,
  messages: [],
  // How many authoritative backend turns MERGE_MESSAGES already reconciled —
  // the backend list is append-only, so anything past this index is a NEW turn
  // even when its content repeats an earlier one.
  mergedCount: 0,
  status: null,
  threadState: {},
  agent: null,
  // UI phase derived from status + state, so the page never confuses a `ready`
  // thread that still needs info with a finished build:
  //   interviewing -> keep chatting (the AI asked another question, or we're
  //                   waiting on the first/next answer)
  //   reviewing    -> the agent was generated; show the review card
  phase: 'interviewing',
  error: null,
  uiFlags: {
    creating: false,
    sending: false,
    fetching: false,
  },
};

export const getters = {
  getThread($state) {
    return $state.thread;
  },
  getMessages($state) {
    return $state.messages;
  },
  getStatus($state) {
    return $state.status;
  },
  getThreadState($state) {
    return $state.threadState;
  },
  getAgent($state) {
    return $state.agent;
  },
  getPhase($state) {
    return $state.phase;
  },
  getError($state) {
    return $state.error;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

// Maps the enveloped thread response into the slices we track. Returns the
// normalized payload so callers can react to `status`/`agent_id`.
//
// We MERGE the backend `messages` (which only ever carry user/assistant turns
// that were persisted server-side — the interview `next_question` is NOT one of
// them) into the local list instead of replacing it, so the question bubbles the
// front injects between turns survive each re-poll and the full interview stays
// visible.
const applyThreadResponse = (commit, data) => {
  const payload = data.payload || data || {};
  commit('SET_THREAD', {
    id: payload.id,
    agent_id: payload.agent_id,
  });
  if (payload.messages) commit('MERGE_MESSAGES', payload.messages);
  if (payload.status) commit('SET_STATUS', payload.status);
  if (payload.state) commit('SET_THREAD_STATE', payload.state);
  return payload;
};

const clearPoll = () => {
  if (pollTimer) {
    clearTimeout(pollTimer);
    pollTimer = null;
  }
};

export const actions = {
  // Opens (or re-opens) a Builder thread and begins polling. `agentId` (optional)
  // ties the thread to an existing agent for guided re-tuning. The remaining
  // params (e.g. `type`, and `image_signed_ids` for multimodal turns) flow
  // through `...rest` to the create call.
  //
  // IA-FALA-PRIMEIRO: `message` is OPTIONAL. The Builder page opens the thread
  // on mount with only the chosen `type` (no user message) so the Construtor
  // emits the opening turn; the greeting/first question arrive via polling. When
  // a `message` is present (the legacy fallback path) it is echoed optimistically.
  start: async ({ commit, dispatch }, { agentId, message, ...rest } = {}) => {
    commit('SET_UI_FLAG', { creating: true });
    clearPoll();
    pendingTurn = null;
    commit('RESET');
    // Optimistically echo the user's turn so the bubble shows instantly, even
    // before the 202 lands (the backend will return the same turn). Skipped on
    // the opening (no message) — the AI speaks first there.
    if (message) commit('APPEND_MESSAGE', { role: 'user', content: message });
    try {
      const { data } = await AutonomiaBuildThreadsAPI.create({
        agentId,
        message,
        ...rest,
      });
      const payload = applyThreadResponse(commit, data);
      dispatch('poll', { threadId: payload.id });
      return payload;
    } catch (error) {
      commit('SET_ERROR', 'send');
      commit('SET_STATUS', 'failed');
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { creating: false });
    }
  },

  fetch: async ({ commit, dispatch }, { threadId }) => {
    commit('SET_UI_FLAG', { fetching: true });
    try {
      const { data } = await AutonomiaBuildThreadsAPI.show(threadId);
      const payload = applyThreadResponse(commit, data);
      dispatch('onSettled', payload);
      return payload;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { fetching: false });
    }
  },

  send: async (
    { commit, dispatch, state: $state },
    { threadId, content, extra = {}, echo = true } = {}
  ) => {
    if (!threadId) return null;
    commit('SET_UI_FLAG', { sending: true });
    commit('SET_ERROR', null);
    commit('SET_PHASE', 'interviewing');
    clearPoll();
    // Echo the user's answer instantly so the conversation never appears to
    // "swallow" the message while the next build is enqueued. Wizard "signal"
    // turns (materials done / skipped) pass `echo: false` so the bubble does
    // not show that internal message to the user.
    if (echo && content) {
      commit('APPEND_MESSAGE', { role: 'user', content });
    }
    // Same turn -> same id: a double-click or a resend of this exact message
    // reuses the pending id so the backend replies idempotently instead of
    // stacking a duplicate turn + build.
    const clientMessageId = clientIdForTurn(threadId, content);
    try {
      const { data } = await AutonomiaBuildThreadsAPI.sendMessage(
        threadId,
        content,
        extra,
        clientMessageId
      );
      // Turn accepted and persisted server-side: the next identical content is
      // a NEW turn and must get a fresh id.
      pendingTurn = null;
      const payload = applyThreadResponse(commit, data);
      dispatch('poll', { threadId: payload.id });
      return payload;
    } catch (error) {
      // 409 build_in_progress: the previous build is still running server-side —
      // this is NOT a failure. Drop the optimistic echo (the turn was rejected),
      // resume polling the in-flight build and rethrow the raw axios error so
      // the page can show the friendly "still working" alert.
      if (error?.response?.status === 409) {
        const last = $state.messages[$state.messages.length - 1];
        if (echo && last?.role === 'user' && last.content === content) {
          commit('SET_MESSAGES', $state.messages.slice(0, -1));
        }
        dispatch('poll', { threadId });
        throw error;
      }
      commit('SET_ERROR', 'send');
      commit('SET_STATUS', 'failed');
      return throwErrorMessage(error);
    } finally {
      commit('SET_UI_FLAG', { sending: false });
    }
  },

  // Re-runs the generation of a `failed` (or stale) thread via the retry
  // endpoint — unlike the old behavior of just re-polling, this actually
  // re-enqueues the SubmitJob with a fresh build_token, then polls to settle.
  retry: async ({ commit, dispatch }, { threadId } = {}) => {
    if (!threadId) return null;
    commit('SET_ERROR', null);
    commit('SET_PHASE', 'interviewing');
    clearPoll();
    try {
      const { data } = await AutonomiaBuildThreadsAPI.retryBuild(threadId);
      const payload = applyThreadResponse(commit, data);
      dispatch('poll', { threadId: payload.id });
      return payload;
    } catch (error) {
      return throwErrorMessage(error);
    }
  },

  // The user reached Materiais and has nothing to upload: send a short signal
  // turn with `no_materials: true` so the backend gate can close the
  // instruction without waiting on sources. Not echoed as a visible bubble.
  declareNoMaterials: ({ dispatch }, { threadId, content }) =>
    dispatch('send', {
      threadId,
      content,
      extra: { no_materials: true },
      echo: false,
    }),

  // The user finished including/reviewing materials: send a short signal turn so
  // the backend gate (sources accepted) closes the instruction. Not echoed.
  // `force_close: true` is a deterministic, language-independent close signal so
  // the backend never depends on matching localized text (e.g. the EN finalize
  // phrase did not match the PT-only close regex) to finalize the instruction.
  completeMaterials: ({ dispatch }, { threadId, content }) =>
    dispatch('send', {
      threadId,
      content,
      extra: { force_close: true },
      echo: false,
    }),

  // Polls `show` until the build settles (ready/failed), then stops. Self-
  // clearing; a new start/send resets the loop. On exhausting the (long) window
  // without settling we surface a visible timeout instead of going quiet.
  poll: ({ commit, dispatch }, { threadId, attempt = 0 }) => {
    clearPoll();
    if (!threadId) return;
    if (attempt >= POLL_MAX_ATTEMPTS) {
      commit('SET_ERROR', 'timeout');
      commit('SET_STATUS', 'failed');
      return;
    }
    pollTimer = setTimeout(async () => {
      pollTimer = null;
      let payload = null;
      try {
        payload = await dispatch('fetch', { threadId });
      } catch (error) {
        // Transient poll failure (network blip): the build is still running on
        // the server, so keep polling rather than going silent — the timeout
        // ceiling is the only hard stop.
        payload = null;
      }
      if (
        payload &&
        (payload.status === 'ready' || payload.status === 'failed')
      ) {
        return;
      }
      dispatch('poll', { threadId, attempt: attempt + 1 });
    }, POLL_INTERVAL);
  },

  // Resolve a settled build into a UI phase. `ready` is ambiguous on the wire,
  // so we read the filtered `state`:
  //   - needs_more_info=true  -> render the next interview question as an
  //     assistant bubble and RE-OPEN the thread (status `open`, phase
  //     `interviewing`) so the user can answer; their reply triggers a new
  //     build. NO agent exists yet, so we do NOT fetch one.
  //   - needs_more_info=false -> the agent was generated; fetch it and switch to
  //     the `reviewing` phase so the review card can appear.
  //   - failed                -> surface a visible error.
  onSettled: async ({ commit, dispatch, state: $state }, payload) => {
    if (!payload) return;

    if (payload.status === 'failed') {
      commit('SET_ERROR', 'failed');
      return;
    }

    if (payload.status !== 'ready') return;

    const needsMoreInfo = payload.state?.needs_more_info === true;
    const nextQuestion = (payload.state?.next_question || '').trim();

    if (needsMoreInfo) {
      // Continue the interview: show the question and let the user answer. The
      // backend now persists the assistant turn in `messages` (so refreshes keep
      // the flow), which MERGE_MESSAGES already delivered above — the local
      // append is only a fallback for payloads that don't carry it yet.
      // T6 — check only the LAST message (the current turn), never the whole
      // list: a global content match would hide a legitimate REPEATED question
      // (the Builder re-asks after an insufficient answer).
      const lastMessage = $state.messages[$state.messages.length - 1];
      const alreadyShown =
        lastMessage?.role === 'assistant' &&
        lastMessage.content === nextQuestion;
      if (nextQuestion && !alreadyShown) {
        commit('APPEND_MESSAGE', { role: 'assistant', content: nextQuestion });
      }
      commit('SET_PHASE', 'interviewing');
      // Re-open so the input is enabled for the next answer.
      commit('SET_STATUS', 'open');
      return;
    }

    // Build complete: the agent lives in the agents API, not the thread payload.
    commit('SET_PHASE', 'reviewing');
    if (!payload.agent_id) return;
    try {
      const agent = await dispatch('autonomiaAgents/show', payload.agent_id, {
        root: true,
      });
      if (agent) commit('SET_AGENT', agent);
    } catch (error) {
      // The hub/panel can still fetch the agent on navigation; swallow here.
    }
  },

  stopPolling: () => {
    clearPoll();
  },
};

export const mutations = {
  SET_UI_FLAG($state, flags) {
    $state.uiFlags = { ...$state.uiFlags, ...flags };
  },
  SET_THREAD($state, thread) {
    $state.thread = thread;
  },
  SET_MESSAGES($state, messages) {
    $state.messages = messages || [];
  },
  // Append a single locally-authored turn (the optimistic user echo, or the
  // assistant `next_question` the front renders between builds). Tagged
  // `local: true` so MERGE_MESSAGES can later match it against the backend
  // turn that confirms it, instead of duplicating the bubble.
  APPEND_MESSAGE($state, message) {
    if (!message || !message.content) return;
    $state.messages = [...$state.messages, { ...message, local: true }];
  },
  // Reconcile the authoritative backend turns with the local list — by
  // POSITION in the thread, never by global role+content (E1 persists every
  // assistant turn, so a content match would hide a legitimate REPEATED
  // question). The backend list is append-only: everything past `mergedCount`
  // is a genuinely NEW turn. Each new turn either confirms one pending local
  // bubble (optimistic user echo / FE-injected question, matched once by
  // role+content) or is appended in order.
  MERGE_MESSAGES($state, incoming) {
    const list = Array.isArray(incoming) ? incoming : [];
    const known = $state.mergedCount || 0;
    let merged = [...$state.messages];
    list.slice(known).forEach(turn => {
      const localIndex = merged.findIndex(
        m => m.local && m.role === turn.role && m.content === turn.content
      );
      merged =
        localIndex >= 0
          ? merged.map((m, i) => (i === localIndex ? { ...turn } : m))
          : [...merged, turn];
    });
    $state.mergedCount = Math.max(known, list.length);
    $state.messages = merged;
  },
  SET_STATUS($state, status) {
    $state.status = status;
  },
  SET_THREAD_STATE($state, threadState) {
    $state.threadState = threadState || {};
  },
  SET_AGENT($state, agent) {
    $state.agent = agent;
  },
  SET_PHASE($state, phase) {
    $state.phase = phase;
  },
  SET_ERROR($state, error) {
    $state.error = error;
  },
  RESET($state) {
    $state.thread = null;
    $state.messages = [];
    $state.mergedCount = 0;
    $state.status = null;
    $state.threadState = {};
    $state.agent = null;
    $state.phase = 'interviewing';
    $state.error = null;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
