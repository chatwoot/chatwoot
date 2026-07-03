import AutonomiaAgentsAPI from '../../api/autonomia/agents';
import { createStore, generateMutationTypes } from '../storeFactory';

// Mirror the mutation names the factory generates for this store so a custom
// action can commit into the same records list (UPSERT) the CRUD actions use.
const mutationTypes = generateMutationTypes('AutonomiaAgents');

// G2 — instruction version history lives alongside the agent records list. It is
// a per-agent lookup (not paginated CRUD), so it gets its own state slice +
// dedicated mutation, kept out of the factory's generic `records`.
const SET_INSTRUCTION_VERSIONS = 'SET_AUTONOMIA_INSTRUCTION_VERSIONS';

export default createStore({
  name: 'AutonomiaAgents',
  API: AutonomiaAgentsAPI,
  state: () => ({
    instructionVersions: [],
  }),
  getters: {
    getInstructionVersions: state => state.instructionVersions,
  },
  mutations: {
    [SET_INSTRUCTION_VERSIONS](state, versions) {
      state.instructionVersions = versions;
    },
    // Staleness guard on the read path. A `show` (fetchingItem) fired by a tab
    // switch or the agentId watch can resolve AFTER a rollback/save write and
    // clobber the fresh record with an older snapshot (last-write-wins on the
    // shared setSingleRecord). Writers among themselves are already serialized
    // via `updatingItem`; this only closes read-clobbers-write. Skip the UPSERT
    // when the incoming payload is strictly older than what's already stored.
    // Scoped to this module so the generic setSingleRecord stays untouched.
    [mutationTypes.UPSERT](state, data) {
      const index = state.records.findIndex(record => record.id === data.id);
      if (index === -1) {
        state.records.push(data);
        return;
      }
      const current = state.records[index];
      const isStale =
        current.updated_at &&
        data.updated_at &&
        new Date(data.updated_at) < new Date(current.updated_at);
      if (isStale) return;
      state.records[index] = data;
    },
  },
  actions: () => ({
    // Load the instruction history for one agent (newest first from the API).
    async getInstructionVersions({ commit }, { agentId }) {
      const { data } = await AutonomiaAgentsAPI.getInstructionVersions(agentId);
      commit(SET_INSTRUCTION_VERSIONS, data.payload);
      return data.payload;
    },

    // Roll the agent's instruction back to a past version. The backend returns
    // the updated agent (new head) — UPSERT it so the panel/form refresh, then
    // re-fetch the history (a new 'rollback' version was just recorded).
    async restoreInstructionVersion(
      { commit, dispatch },
      { agentId, versionId }
    ) {
      // Reuse the CRUD `updatingItem` flag so a rollback and the header
      // pause/activate toggle can't write the same agent concurrently (the
      // last response would otherwise clobber the other's record in Vuex).
      commit(mutationTypes.SET_UI_FLAG, { updatingItem: true });
      try {
        const { data } = await AutonomiaAgentsAPI.restoreInstructionVersion(
          agentId,
          versionId
        );
        commit(mutationTypes.UPSERT, data);
        await dispatch('getInstructionVersions', { agentId });
        return data;
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { updatingItem: false });
      }
    },

    // Sandbox test of a draft/live agent. Returns the full evaluation
    // ({ reply, confidence, handoff, used_knowledge }) for the Test tab to
    // render; it is transient (not persisted to the records list).
    async test(_, { agentId, message, history = [], images = [] }) {
      const { data } = await AutonomiaAgentsAPI.test(agentId, {
        message,
        history,
        images,
      });
      return data;
    },

    async updateAvatar({ commit }, { agentId, avatar }) {
      const { data } = await AutonomiaAgentsAPI.updateAvatar(agentId, avatar);
      commit(mutationTypes.UPSERT, data);
      return data;
    },

    async deleteAvatar({ commit }, agentId) {
      const { data } = await AutonomiaAgentsAPI.deleteAvatar(agentId);
      commit(mutationTypes.UPSERT, data);
      return data;
    },

    // Same shape as `test`, used to suggest a reply to a human agent.
    async suggest(_, { agentId, message, history = [] }) {
      const { data } = await AutonomiaAgentsAPI.suggest(agentId, {
        message,
        history,
      });
      return data;
    },

    // Commit an agent produced elsewhere (e.g. when a Builder thread becomes
    // `ready` and returns the generated agent) into the records list so the hub
    // and panel see it without a refetch.
    upsert({ commit }, agent) {
      if (agent?.id) commit(mutationTypes.UPSERT, agent);
    },
  }),
});
