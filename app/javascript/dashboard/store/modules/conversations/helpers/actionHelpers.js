import types from '../../../mutation-types';

export const setPageFilter = ({ dispatch, filter, page, markEndReached }) => {
  dispatch('conversationPage/setCurrentPage', { filter, page }, { root: true });
  if (markEndReached) {
    dispatch('conversationPage/setEndReached', { filter }, { root: true });
  }
};

export const setContacts = (commit, chatList) => {
  commit(
    `contacts/${types.SET_CONTACTS}`,
    chatList.map(chat => chat.meta.sender)
  );
};

export const isOnMentionsView = ({ route: { name: routeName } }) => {
  const MENTION_ROUTES = [
    'conversation_mentions',
    'conversation_through_mentions',
  ];
  return MENTION_ROUTES.includes(routeName);
};

export const isOnUnattendedView = ({ route: { name: routeName } }) => {
  const UNATTENDED_ROUTES = [
    'conversation_unattended',
    'conversation_through_unattended',
  ];
  return UNATTENDED_ROUTES.includes(routeName);
};

export const isOnUnreadView = ({ route: { name: routeName } }) => {
  const UNREAD_ROUTES = ['conversation_unread', 'conversation_through_unread'];
  return UNREAD_ROUTES.includes(routeName);
};

export const isOnFoldersView = ({ route: { name: routeName } }) => {
  const FOLDER_ROUTES = [
    'folder_conversations',
    'conversations_through_folders',
  ];
  return FOLDER_ROUTES.includes(routeName);
};

export const isOnOpenView = ({ route: { name: routeName } }) => {
  const OPEN_ROUTES = [
    'conversation_open_status',
    'conversation_through_open_status',
  ];
  return OPEN_ROUTES.includes(routeName);
};

export const isOnSnoozedView = ({ route: { name: routeName } }) => {
  const SNOOZED_ROUTES = [
    'conversation_snoozed_status',
    'conversation_through_snoozed_status',
  ];
  return SNOOZED_ROUTES.includes(routeName);
};

export const isOnPendingView = ({ route: { name: routeName } }) => {
  const PENDING_ROUTES = [
    'conversation_pending_status',
    'conversation_through_pending_status',
  ];
  return PENDING_ROUTES.includes(routeName);
};

export const isOnResolvedView = ({ route: { name: routeName } }) => {
  const RESOLVED_ROUTES = [
    'conversation_resolved_status',
    'conversation_through_resolved_status',
  ];
  return RESOLVED_ROUTES.includes(routeName);
};

export const buildConversationList = (
  context,
  requestPayload,
  responseData,
  filterType
) => {
  const { payload: conversationList, meta: metaData } = responseData;
  context.commit(types.SET_ALL_CONVERSATION, conversationList);
  context.dispatch('conversationStats/set', metaData);
  context.dispatch(
    'conversationLabels/setBulkConversationLabels',
    conversationList
  );
  context.commit(types.CLEAR_LIST_LOADING_STATUS);
  setContacts(context.commit, conversationList);
  setPageFilter({
    dispatch: context.dispatch,
    filter: filterType,
    page: requestPayload.page,
    markEndReached: !conversationList.length,
  });
};
