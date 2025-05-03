import MessageApi from "../../../../api/inbox/message";
import ConversationApi from "../../../../api/inbox/conversation";
import types from '../../../mutation-types';


export default {
  performQualityCheck(_, { conversationId, draftMessage }) {
    return ConversationApi.performQualityCheck(conversationId, draftMessage);
  },
  translateDraftMessage(_, { conversationId, message }) {
    return ConversationApi.translateDraftMessage(conversationId, message);
  },
  performConversationSummary(_, { conversationId }) {
    return ConversationApi.performConversationSummary(conversationId);
  },
  setQualityScores({ commit }, scores) {
    commit(types.SET_QUALITY_SCORES, scores);
  },
  saveQualityScores(_, { conversationId, messageId, scores}) {
    return MessageApi.saveQualityScores(conversationId, messageId, scores);
  },
}
