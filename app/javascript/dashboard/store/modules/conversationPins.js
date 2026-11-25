import types from '../mutation-types';
import { throwErrorMessage } from 'dashboard/store/utils/api';

import ConversationApi from '../../api/inbox/conversation';

// Pins are personal, so the store holds the current agent's pins for the current account only, keyed by the
// conversation display id: { [conversationId]: pinnedAt }. Conversation objects stay untouched, which keeps
// the pin state correct no matter how a conversation entered the list (fetch, websocket, reopen).
// `appliedAt` is the version of the last pin/unpin applied per conversation. Both events for the same pin
// carry that pin's `pinned_at`, and the broadcast jobs are asynchronous, so a `pinned` event that lost the
// race with the `unpin` right after it would otherwise resurrect a pin the server no longer has.
// `revision` counts resets, so a hydration can tell that the map it was going to replace has been thrown
// away under it. It does not count snapshots: hydrations run one at a time, so no other one can land
// mid-flight, and the guard could only ever see which of two overlapping reads committed last, not which
// read the newer state. Individual pin events are handled by `appliedAt` instead.
const state = {
  records: {},
  appliedAt: {},
  revision: 0,
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getUIFlags: $state => $state.uiFlags,
  getRecords: $state => $state.records,
  isPinned: $state => conversationId => Boolean($state.records[conversationId]),
};

// Two hydrations in flight at once have no sound order: the guards below can tell which one committed
// last, never which one read the newer state, so the older request winning the race would replace a fresh
// snapshot with a stale one. Running them one at a time removes the question, and the checks inside only
// have to order a snapshot against the pin events that land under it. Overlapping callers collapse into a
// single follow-up run, so the last one still gets a read issued after it asked.
let inFlightHydration = null;
let inFlightRevision = null;
let followUpRequested = false;

const hydrate = async ({ commit, rootGetters, state: $state }) => {
  commit(types.SET_CONVERSATION_PINS_UI_FLAG, { isFetching: true });

  const accountId = rootGetters.getCurrentAccountId;
  const revision = $state.revision;
  // Which conversations the snapshot may not speak for is decided by what changes under it, not by a
  // clock: `pinned_at` is written before the transaction commits, so no timestamp orders an event
  // against a snapshot that could not see its row yet.
  const appliedAtBefore = { ...$state.appliedAt };
  // An unpin keeps the version of the pin it removes, so the applied version alone cannot see one land
  // mid-flight. What the map held has to travel with it.
  const recordsBefore = { ...$state.records };

  try {
    const { data } = await ConversationApi.fetchPins();
    if (rootGetters.getCurrentAccountId !== accountId) return;
    if ($state.revision !== revision) return;

    commit(types.SET_CONVERSATION_PINS, {
      pins: data,
      appliedAtBefore,
      recordsBefore,
    });
  } catch (error) {
    // A failed hydration only costs the pinned ordering, so it should not block the inbox from booting.
  } finally {
    commit(types.SET_CONVERSATION_PINS_UI_FLAG, { isFetching: false });
  }
};

const hydrateUntilSettled = async (context, runRevision) => {
  await hydrate(context);

  // A reset abandoned this run and started its own, which now owns the marker.
  if (inFlightRevision !== runRevision) return;

  if (followUpRequested) {
    followUpRequested = false;
    await hydrateUntilSettled(context, runRevision);
    return;
  }

  // Released here, in the same synchronous block as the checks above, rather than from a `.finally` on the
  // run: between the run resolving and such a callback there is a microtask in which the marker still
  // reads as busy, so a caller landing there would only raise a flag that nobody reads again.
  inFlightHydration = null;
};

export const actions = {
  fetch: context => {
    const { revision } = context.state;

    // Serialization holds between reads of the same map. A reset threw the running read's map away and it
    // can no longer commit, so folding the new account behind it would leave that account with no pins for
    // as long as a request nothing bounds takes to settle. The abandoned read still returns, and its own
    // revision check drops it.
    if (inFlightHydration && inFlightRevision === revision) {
      followUpRequested = true;
      return inFlightHydration;
    }

    followUpRequested = false;
    inFlightRevision = revision;
    inFlightHydration = hydrateUntilSettled(context, revision);
    return inFlightHydration;
  },

  pin: async ({ commit, rootGetters }, conversationId) => {
    // Display ids restart per account, so a response that outlives the account it was made in would pin an
    // unrelated conversation.
    const accountId = rootGetters.getCurrentAccountId;
    try {
      const { data } = await ConversationApi.pin(conversationId);
      if (rootGetters.getCurrentAccountId !== accountId) return;

      commit(types.SET_CONVERSATION_PIN, data);
    } catch (error) {
      throwErrorMessage(error);
    }
  },

  unpin: async ({ commit, rootGetters, state: $state }, conversationId) => {
    const accountId = rootGetters.getCurrentAccountId;
    const pinnedAt = $state.records[conversationId];
    try {
      await ConversationApi.unpin(conversationId);
      if (rootGetters.getCurrentAccountId !== accountId) return;

      commit(types.REMOVE_CONVERSATION_PIN, {
        conversation_id: conversationId,
        pinned_at: pinnedAt,
      });
    } catch (error) {
      throwErrorMessage(error);
    }
  },

  reset: ({ commit }) => commit(types.CLEAR_CONVERSATION_PINS),

  add: ({ commit }, data) => commit(types.SET_CONVERSATION_PIN, data),

  remove: ({ commit }, data) => commit(types.REMOVE_CONVERSATION_PIN, data),
};

export const mutations = {
  [types.SET_CONVERSATION_PINS_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },

  // Pins are keyed by conversation display id, which restarts per account, so carrying a map across an
  // account switch would light up unrelated conversations. Bumping the revision also discards a hydration
  // still in flight for the account being left.
  [types.CLEAR_CONVERSATION_PINS]($state) {
    $state.records = {};
    $state.appliedAt = {};
    $state.revision += 1;
  },

  [types.SET_CONVERSATION_PINS](
    $state,
    { pins, appliedAtBefore = {}, recordsBefore = {} }
  ) {
    const records = (pins || []).reduce(
      (acc, { conversation_id: conversationId, pinned_at: pinnedAt }) => ({
        ...acc,
        [conversationId]: pinnedAt,
      }),
      {}
    );

    // Only the conversations whose state moved while the request was in flight are kept from local state;
    // the server speaks for every other one. Discarding the whole snapshot instead would leave a cold
    // hydration with nothing but the deltas those events carried.
    // Both halves are needed: an unpin carries the version of the pin it removes, so it moves the map
    // without moving the version, and a snapshot taken before it would otherwise put the pin back.
    Object.keys($state.appliedAt).forEach(conversationId => {
      const sameVersion =
        $state.appliedAt[conversationId] === appliedAtBefore[conversationId];
      const samePin =
        $state.records[conversationId] === recordsBefore[conversationId];
      if (sameVersion && samePin) return;

      const local = $state.records[conversationId];
      if (local === undefined) delete records[conversationId];
      else records[conversationId] = local;
    });

    $state.records = records;
    // Versions of conversations that are no longer pinned are kept, so a later snapshot cannot re-arm an
    // event that was already superseded.
    $state.appliedAt = { ...$state.appliedAt, ...records };
  },

  [types.SET_CONVERSATION_PIN](
    $state,
    { conversation_id: conversationId, pinned_at: pinnedAt }
  ) {
    const appliedAt = $state.appliedAt[conversationId];
    // Re-applying the pin currently held is a no-op; anything else at or below the applied version is an
    // event a newer pin or unpin already superseded.
    const isSupersededPin =
      appliedAt !== undefined &&
      pinnedAt <= appliedAt &&
      $state.records[conversationId] !== pinnedAt;
    if (isSupersededPin) return;

    $state.records = { ...$state.records, [conversationId]: pinnedAt };
    $state.appliedAt = { ...$state.appliedAt, [conversationId]: pinnedAt };
  },

  [types.REMOVE_CONVERSATION_PIN](
    $state,
    { conversation_id: conversationId, pinned_at: pinnedAt }
  ) {
    const appliedAt = $state.appliedAt[conversationId];
    const isSupersededUnpin =
      pinnedAt !== undefined && appliedAt !== undefined && pinnedAt < appliedAt;
    if (isSupersededUnpin) return;

    const { [conversationId]: _removed, ...rest } = $state.records;
    $state.records = rest;
    $state.appliedAt = {
      ...$state.appliedAt,
      [conversationId]: Math.max(pinnedAt ?? 0, appliedAt ?? 0),
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
