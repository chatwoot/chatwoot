import { useRoute } from 'vue-router';
import {
  frontendURL,
  conversationUrl,
  conversationListPageURL,
} from 'dashboard/helper/URLHelper';
import {
  isOnMentionsView,
  isOnParticipatingView,
  isOnUnattendedView,
  isOnFoldersView,
} from 'dashboard/store/modules/conversations/helpers/actionHelpers';
import wootConstants from 'dashboard/constants/globals';

// Builds conversation and conversation list paths that keep the context of the
// active route — the inbox, label, team or folder the agent is working from.
export function useConversationRoutePath() {
  const route = useRoute();

  const buildConversationPath = conversationId => {
    const {
      params: { accountId, inbox_id: inboxId, label, teamId },
      name,
    } = route;

    let conversationType = '';
    if (isOnMentionsView({ route: { name } })) {
      conversationType = 'mention';
    } else if (isOnUnattendedView({ route: { name } })) {
      conversationType = 'unattended';
    }

    return frontendURL(
      conversationUrl({
        accountId,
        activeInbox: inboxId,
        id: conversationId,
        label,
        teamId,
        foldersId: isOnFoldersView({ route: { name } }) ? route.params.id : 0,
        conversationType,
      })
    );
  };

  const buildConversationListPath = () => {
    const {
      params: { accountId, inbox_id: inboxId, label, teamId },
      name,
    } = route;
    const { CONVERSATION_TYPE } = wootConstants;

    let conversationType = '';
    if (isOnMentionsView({ route: { name } })) {
      conversationType = CONVERSATION_TYPE.MENTION;
    } else if (isOnParticipatingView({ route: { name } })) {
      conversationType = CONVERSATION_TYPE.PARTICIPATING;
    } else if (isOnUnattendedView({ route: { name } })) {
      conversationType = CONVERSATION_TYPE.UNATTENDED;
    }

    return conversationListPageURL({
      accountId,
      conversationType,
      customViewId: isOnFoldersView({ route: { name } }) ? route.params.id : 0,
      inboxId,
      label,
      teamId,
    });
  };

  return { buildConversationPath, buildConversationListPath };
}
