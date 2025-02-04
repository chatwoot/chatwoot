import ConversationApi from '../../../../api/inbox/conversation';
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

export const isOnCallingNudgesView = ({ route: { name: routeName } }) => {
  const CALLING_NUDGES_ROUTES = [
    'conversation_calling_nudges',
    'conversation_through_calling_nudges',
  ];
  return CALLING_NUDGES_ROUTES.includes(routeName);
};

export const isOnMissedCallsView = ({ route: { name: routeName } }) => {
  const MISSED_CALLS_ROUTES = [
    'conversation_missed_calls',
    'conversation_through_missed_calls',
  ];
  return MISSED_CALLS_ROUTES.includes(routeName);
};

export const isOnFoldersView = ({ route: { name: routeName } }) => {
  const FOLDER_ROUTES = [
    'folder_conversations',
    'conversations_through_folders',
  ];
  return FOLDER_ROUTES.includes(routeName);
};

export const checkIfConversationPartOfFolder = async (
  conversation,
  rootState
) => {
  try {
    let page = 1;
    let foldersId = rootState.route.params.id;

    // get folders from customViews/getCustomViews
    let folders = rootState.customViews.records;

    let activeFolder = () => {
      if (foldersId) {
        const activeView = folders.filter(
          view => view.id === Number(foldersId)
        );
        const [firstValue] = activeView;
        return firstValue;
      }
      return undefined;
    };

    let payload = activeFolder().query;

    const { data } = await ConversationApi.filter({
      queryData: payload,
      page,
    });

    return data.payload.some(item => item.id === conversation.id);
  } catch (error) {
    // Handle error
    return false;
  }
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
