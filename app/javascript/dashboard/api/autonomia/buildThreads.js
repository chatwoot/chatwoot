/* global axios */
import getUuid from 'widget/helpers/uuid';
import ApiClient from '../ApiClient';

// The Builder conversation: an AI that interviews the user and, when it has
// enough information, generates the agent. The route is TOP-LEVEL under the
// autonomia namespace (`autonomia/build_threads`), NOT nested under agents — an
// existing agent is referenced in the body via `autonomia_agent_id`.
//
// The generation is ASYNCHRONOUS: create/messages return 202 Accepted with
// status `processing`; the front polls `show` until status becomes
// `ready`/`failed`. The thread response is enveloped in `payload` and carries
// `status` (open | processing | ready | failed) plus a filtered `state`
// (needs_more_info | next_question | turn). The generated agent is fetched
// separately via the agents API once the thread is `ready`.
class AutonomiaBuildThreadsAPI extends ApiClient {
  constructor() {
    super('autonomia/build_threads', { accountScoped: true });
  }

  // Opens the Builder conversation with the user's first message. `agentId`
  // (optional) ties the thread to an existing agent for guided re-tuning.
  // `...rest` carries optional flags merged into the body — e.g.
  // `image_signed_ids` (ActiveStorage refs read inline by the model for this
  // turn, multimodal). Absent → identical to the text-only open.
  create({ message, agentId, ...rest } = {}) {
    return axios.post(this.url, {
      message,
      autonomia_agent_id: agentId,
      // Idempotency id for this turn: the backend no-ops a repeated append with
      // the same client_message_id (double-click / network retry).
      client_message_id: getUuid(),
      ...rest,
    });
  }

  show(threadId) {
    return axios.get(`${this.url}/${threadId}`);
  }

  // Continues the conversation. The backend reads `params[:message]`. `extra`
  // carries optional flags merged into the body (e.g. `no_materials: true` when
  // the user declares they have no materials so the gate can close the
  // instruction without waiting for sources).
  sendMessage(threadId, message, extra = {}) {
    return axios.post(`${this.url}/${threadId}/messages`, {
      message,
      // Fresh uuid per send: dedupes this exact turn server-side without ever
      // colliding across distinct sends.
      client_message_id: getUuid(),
      ...extra,
    });
  }

  // Re-runs the generation of a failed (or stale-processing) thread: the backend
  // issues a new build_token and enqueues the SubmitJob again. Nothing is added
  // to the conversation history.
  retryBuild(threadId) {
    return axios.post(`${this.url}/${threadId}/retry`);
  }
}

export default new AutonomiaBuildThreadsAPI();
