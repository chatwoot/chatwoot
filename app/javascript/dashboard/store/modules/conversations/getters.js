import { MESSAGE_STATUS, MESSAGE_TYPE } from 'shared/constants/messages';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import {
  applyPageFilters,
  applyRoleFilter,
  isContactSide,
  languageCode,
  sortComparator,
} from './helpers';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
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
    const account =
      rootGetters['accounts/getAccount'](rootGetters.getCurrentAccountId) || {};
    const locale = rootGetters.getUISettings?.locale || account.locale || 'en';
    const chat = _getters.getSelectedChat;
    const language = chat.additional_attributes?.conversation_language;
    const isFeatureEnabled = feature =>
      rootGetters['accounts/isFeatureEnabledonAccount'](
        rootGetters.getCurrentAccountId,
        feature
      );
    const enabled =
      isFeatureEnabled(FEATURE_FLAGS.AUTO_TRANSLATE) &&
      isFeatureEnabled(FEATURE_FLAGS.CAPTAIN_TASKS) &&
      account.settings?.auto_translate !== false &&
      rootGetters['globalConfig/get'].isCaptainConfigured;
    const sameLanguage =
      !!language && languageCode(language) === languageCode(locale);

    return {
      enabled,
      locale,
      sameLanguage,
      translated: !!chat.messages?.some(
        message => message.content_attributes?.translations
      ),
      active: enabled && !!language && !sameLanguage,
      language: enabled && language ? languageName(language) : '',
      agentLanguage: languageName(locale),
    };
  },

  getMessageTranslationState: (_state, _getters) => messageId => {
    const { enabled, active, locale, language, sameLanguage, translated } =
      _getters.getAutoTranslate;
    const message =
      _getters.getSelectedChat.messages?.find(item => item.id === messageId) ??
      {};
    const attributes = message.content_attributes ?? {};
    const translations = attributes.translations ?? {};
    const contactSide =
      isContactSide(message.message_type, message.sender?.type) &&
      !!message.content &&
      !attributes.deleted;
    const waiting = contactSide
      ? _state.autoTranslating[locale]?.[messageId] === true
      : message.status === MESSAGE_STATUS.PROGRESS && !message.private;

    const untranslated = !translations[locale];
    const sourceLanguage = attributes.source_language;
    // Stored with another language, a message is translated even after the thread switched to the agent language.
    const foreign =
      !!sourceLanguage && languageCode(sourceLanguage) !== languageCode(locale);
    // Once a translated thread switches to the agent language, its remaining messages need no translation either.
    const writtenInAgentLanguage = untranslated
      ? sameLanguage && translated
      : translations[locale] ===
        (attributes.email?.html_content?.full || message.content);

    return {
      pending: (active || (enabled && foreign)) && untranslated && waiting,
      failed: enabled && !!attributes.translation_failed,
      sameLanguage:
        enabled && contactSide && writtenInAgentLanguage && !foreign,
      sourceLanguage: sourceLanguage ? languageName(sourceLanguage) : language,
    };
  },
};

export default getters;
