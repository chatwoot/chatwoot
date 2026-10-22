import { MESSAGE_STATUS, MESSAGE_TYPE } from 'shared/constants/messages';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import {
  applyPageFilters,
  applyRoleFilter,
  isForeign,
  isTranslatable,
  languageCode,
  sortComparator,
} from './helpers';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import {
  TRANSLATION_PROVIDERS,
  translationProvider,
} from 'dashboard/helper/translationProvider';
import { createFiltersMatcher } from './helpers/filterHelpers';
import {
  getUserPermissions,
  getUserRole,
} from '../../../helper/permissionsHelper';
import camelcaseKeys from 'camelcase-keys';

const languageName = code =>
  languages.find(language => language.id === languageCode(code))?.name || code;

export const getSelectedChatConversation = ({
  allConversations,
  selectedChatId,
}) =>
  allConversations.filter(conversation => conversation.id === selectedChatId);

const getters = {
  getAllConversations: ({ allConversations, chatSortFilter: sortKey }) => {
    return allConversations.sort((a, b) => sortComparator(a, b, sortKey));
  },
  getFilteredConversations: (
    { allConversations, chatSortFilter, appliedFilters, appliedFiltersSortBy },
    _,
    __,
    rootGetters
  ) => {
    const currentUser = rootGetters.getCurrentUser;
    const currentUserId = rootGetters.getCurrentUser.id;
    const currentAccountId = rootGetters.getCurrentAccountId;

    const permissions = getUserPermissions(currentUser, currentAccountId);
    const userRole = getUserRole(currentUser, currentAccountId);
    const matchesFilters = createFiltersMatcher(appliedFilters);

    return allConversations
      .filter(conversation => {
        const matchesFilterResult = matchesFilters(conversation);
        const allowedForRole = applyRoleFilter(
          conversation,
          userRole,
          permissions,
          currentUserId
        );

        return matchesFilterResult && allowedForRole;
      })
      .sort((a, b) =>
        sortComparator(a, b, appliedFiltersSortBy || chatSortFilter)
      );
  },
  getSelectedChat: ({ selectedChatId, allConversations }) => {
    const selectedChat = allConversations.find(
      conversation => conversation.id === selectedChatId
    );
    return selectedChat || {};
  },
  getSelectedChatAttachments: ({ selectedChatId, attachments }) => {
    return attachments[selectedChatId] || [];
  },
  getSelectedChatAttachmentsLoaded: ({ selectedChatId, attachments }) =>
    selectedChatId !== null && attachments[selectedChatId] !== undefined,
  getChatListFilters: ({ conversationFilters }) => conversationFilters,
  getLastEmailInSelectedChat: (stage, _getters) => {
    const selectedChat = _getters.getSelectedChat;
    const { messages = [] } = selectedChat;
    const lastEmail = [...messages].reverse().find(message => {
      const {
        message_type: messageType,
        content_attributes: contentAttributes,
      } = message;
      if (message.private || contentAttributes?.forwarded_message_id) {
        return false;
      }

      return [MESSAGE_TYPE.OUTGOING, MESSAGE_TYPE.INCOMING].includes(
        messageType
      );
    });

    return lastEmail;
  },
  getMineChats: (_state, _, __, rootGetters) => activeFilters => {
    const currentUserID = rootGetters.getCurrentUser?.id;

    return _state.allConversations.filter(conversation => {
      const { assignee } = conversation.meta;
      const isAssignedToMe = assignee && assignee.id === currentUserID;
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      const isChatMine = isAssignedToMe && shouldFilter;

      return isChatMine;
    });
  },
  getAppliedConversationFiltersV2: _state => {
    // TODO: Replace existing one with V2 after migrating the filters to use camelcase
    return _state.appliedFilters.map(camelcaseKeys);
  },
  getAppliedConversationFilters: _state => {
    return _state.appliedFilters;
  },
  getAppliedContactFilter: ({ appliedFilters }) => {
    const [filter, ...rest] = appliedFilters;
    if (rest.length || filter?.attribute_key !== 'contact_id') return null;

    return filter.values?.[0] ?? null;
  },
  getAppliedConversationFiltersQuery: _state => {
    const hasAppliedFilters = _state.appliedFilters.length !== 0;
    return hasAppliedFilters
      ? filterQueryGenerator(_state.appliedFilters, { useLocalTimezone: false })
      : [];
  },
  getUnAssignedChats: _state => activeFilters => {
    return _state.allConversations.filter(conversation => {
      const isUnAssigned = !conversation.meta.assignee;
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      return isUnAssigned && shouldFilter;
    });
  },
  getParticipatingChats: (_state, _, __, rootGetters) => activeFilters => {
    const currentUserId = rootGetters.getCurrentUser?.id;
    const getWatchers = rootGetters['conversationWatchers/getByConversationId'];
    return _state.allConversations.filter(conversation => {
      const watchers = getWatchers(conversation.id);
      // Watchers are only loaded for the conversation open in the detail
      // panel. If loaded and current user is not in them, filter it out.
      if (watchers && !watchers.some(w => w.id === currentUserId)) {
        return false;
      }
      return applyPageFilters(conversation, activeFilters);
    });
  },
  getAllStatusChats: (_state, _, __, rootGetters) => activeFilters => {
    const currentUser = rootGetters.getCurrentUser;
    const currentUserId = rootGetters.getCurrentUser.id;
    const currentAccountId = rootGetters.getCurrentAccountId;

    const permissions = getUserPermissions(currentUser, currentAccountId);
    const userRole = getUserRole(currentUser, currentAccountId);

    return _state.allConversations.filter(conversation => {
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      const allowedForRole = applyRoleFilter(
        conversation,
        userRole,
        permissions,
        currentUserId
      );

      return shouldFilter && allowedForRole;
    });
  },
  getChatListLoadingStatus: ({ listLoadingStatus }) => listLoadingStatus,
  getAllMessagesLoaded(_state) {
    const [chat] = getSelectedChatConversation(_state);
    return !chat || chat.allMessagesLoaded === undefined
      ? false
      : chat.allMessagesLoaded;
  },
  getUnreadCount(_state) {
    const [chat] = getSelectedChatConversation(_state);
    if (!chat) return [];
    return chat.messages.filter(
      chatMessage =>
        chatMessage.created_at * 1000 > chat.agent_last_seen_at * 1000 &&
        chatMessage.message_type === 0 &&
        chatMessage.private !== true
    ).length;
  },
  getChatStatusFilter: ({ chatStatusFilter }) => chatStatusFilter,
  getChatSortFilter: ({ chatSortFilter }) => chatSortFilter,
  getSelectedInbox: ({ currentInbox }) => currentInbox,
  getConversationById: _state => conversationId => {
    return _state.allConversations.find(
      value => value.id === Number(conversationId)
    );
  },
  getConversationParticipants: _state => {
    return _state.conversationParticipants;
  },
  getConversationLastSeen: _state => {
    return _state.conversationLastSeen;
  },

  getContextMenuChatId: _state => {
    return _state.contextMenuChatId;
  },

  getCopilotAssistant: _state => {
    return _state.copilotAssistant;
  },

  getAutoTranslate: (_state, _getters, _rootState, rootGetters) => {
    const accountId = rootGetters.getCurrentAccountId;
    const account = rootGetters['accounts/getAccount'](accountId) || {};
    const locale = rootGetters.getUISettings?.locale || account.locale || 'en';
    const language =
      _getters.getSelectedChat.additional_attributes?.conversation_language;
    const isFeatureEnabled = feature =>
      rootGetters['accounts/isFeatureEnabledonAccount'](accountId, feature);
    const googleConnected =
      !!rootGetters['integrations/getIntegration']('google_translate').enabled;
    const provider = translationProvider(account.settings);
    const serviceAvailable =
      provider === TRANSLATION_PROVIDERS.GOOGLE
        ? googleConnected
        : isFeatureEnabled(FEATURE_FLAGS.CAPTAIN_TASKS);
    const enabled =
      isFeatureEnabled(FEATURE_FLAGS.AUTO_TRANSLATE) &&
      account.settings?.auto_translate === true &&
      serviceAvailable;

    return {
      enabled,
      provider,
      locale,
      sameLanguage:
        !!language && languageCode(language) === languageCode(locale),
      language: enabled && language ? languageName(language) : '',
      agentLanguage: languageName(locale),
    };
  },

  getMessageTranslationState: (_state, _getters) => messageId => {
    const { enabled, locale, language, sameLanguage } =
      _getters.getAutoTranslate;
    const messages = _getters.getSelectedChat.messages ?? [];
    const message = messages.find(item => item.id === messageId) ?? {};
    const attributes = message.content_attributes ?? {};
    const translations = attributes.translations ?? {};
    const translation = translations[locale];
    // A reply or template keeps its author's own text under the language it was written in.
    const ownLanguage = translation ? locale : Object.keys(translations)[0];
    const translatable = isTranslatable(message);
    const foreign = isForeign(message, locale);
    const waiting = translatable
      ? _state.autoTranslating[locale]?.[messageId] === true
      : !!attributes.translation_pending ||
        (message.status === MESSAGE_STATUS.PROGRESS &&
          !message.private &&
          !attributes.forwarded_message_id);
    return {
      pending:
        enabled &&
        (foreign || (!!language && !sameLanguage)) &&
        !translation &&
        !attributes.translation_failed &&
        waiting,
      failed: enabled && !!attributes.translation_failed,
      // A message already in the agent language is stored with its own text as the translation.
      sameLanguage:
        enabled && translatable && !foreign && translation === message.content,
      sourceLanguage: attributes.source_language
        ? languageName(attributes.source_language)
        : language,
      originalLanguage: languageName(ownLanguage ?? locale),
    };
  },
};

export default getters;
