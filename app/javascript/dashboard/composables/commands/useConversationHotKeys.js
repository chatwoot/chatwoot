import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { emitter } from 'shared/helpers/mitt';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { useAI } from 'dashboard/composables/useAI';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import { CMD_AI_ASSIST } from 'dashboard/helper/commandbar/events';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';

import wootConstants from 'dashboard/constants/globals';

import {
  ICON_ADD_LABEL,
  ICON_ASSIGN_AGENT,
  ICON_ASSIGN_PRIORITY,
  ICON_ASSIGN_TEAM,
  ICON_REMOVE_LABEL,
  ICON_PRIORITY_URGENT,
  ICON_PRIORITY_HIGH,
  ICON_PRIORITY_LOW,
  ICON_PRIORITY_MEDIUM,
  ICON_PRIORITY_NONE,
  ICON_AI_ASSIST,
  ICON_AI_SUMMARY,
  ICON_AI_SHORTEN,
  ICON_AI_EXPAND,
  ICON_AI_GRAMMAR,
} from 'dashboard/helper/commandbar/icons';

import {
  OPEN_CONVERSATION_ACTIONS,
  SNOOZE_CONVERSATION_ACTIONS,
  RESOLVED_CONVERSATION_ACTIONS,
  SEND_TRANSCRIPT_ACTION,
  UNMUTE_ACTION,
  MUTE_ACTION,
} from 'dashboard/helper/commandbar/actions';
import {
  isAConversationRoute,
  isAInboxViewRoute,
} from 'dashboard/helper/routeHelpers';

const prepareActions = (actions, t) => {
  return actions.map(action => ({
    ...action,
    title: t(action.title),
    section: t(action.section),
  }));
};

const createPriorityOptions = (t, currentPriority) => {
  return [
    {
      label: t('CONVERSATION.PRIORITY.OPTIONS.NONE'),
      key: null,
      icon: ICON_PRIORITY_NONE,
    },
    {
      label: t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
      key: 'urgent',
      icon: ICON_PRIORITY_URGENT,
    },
    {
      label: t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
      key: 'high',
      icon: ICON_PRIORITY_HIGH,
    },
    {
      label: t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
      key: 'medium',
      icon: ICON_PRIORITY_MEDIUM,
    },
    {
      label: t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
      key: 'low',
      icon: ICON_PRIORITY_LOW,
    },
  ].filter(item => item.key !== currentPriority);
};

const createNonDraftMessageAIAssistActions = (t, replyMode) => {
  if (replyMode === REPLY_EDITOR_MODES.REPLY) {
    return [
      {
        label: t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.REPLY_SUGGESTION'),
        key: 'reply_suggestion',
        icon: ICON_AI_ASSIST,
      },
    ];
  }
  return [
    {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.SUMMARIZE'),
      key: 'summarize',
      icon: ICON_AI_SUMMARY,
    },
  ];
};

const createDraftMessageAIAssistActions = t => {
  return [
    {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.REPHRASE'),
      key: 'rephrase',
      icon: ICON_AI_ASSIST,
    },
    {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.FIX_SPELLING_GRAMMAR'),
      key: 'fix_spelling_grammar',
      icon: ICON_AI_GRAMMAR,
    },
    {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.EXPAND'),
      key: 'expand',
      icon: ICON_AI_EXPAND,
    },
    {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.SHORTEN'),
      key: 'shorten',
      icon: ICON_AI_SHORTEN,
    },
    {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.MAKE_FRIENDLY'),
      key: 'make_friendly',
      icon: ICON_AI_ASSIST,
    },
    {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.MAKE_FORMAL'),
      key: 'make_formal',
      icon: ICON_AI_ASSIST,
    },
    {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.SIMPLIFY'),
      key: 'simplify',
      icon: ICON_AI_ASSIST,
    },
  ];
};

export function useConversationHotKeys() {
  const { t } = useI18n();
  const store = useStore();
  const route = useRoute();

  const {
    activeLabels,
    inactiveLabels,
    addLabelToConversation,
    removeLabelFromConversation,
  } = useConversationLabels();

  const { isAIIntegrationEnabled } = useAI();
  const { agentsList } = useAgentsList();

  const currentChat = useMapGetter('getSelectedChat');
  const replyMode = useMapGetter('draftMessages/getReplyEditorMode');
  const contextMenuChatId = useMapGetter('getContextMenuChatId');
  const teams = useMapGetter('teams/getTeams');
  const getDraftMessage = useMapGetter('draftMessages/get');

  const conversationId = computed(() => currentChat.value?.id);
  const draftKey = computed(
    () => `draft-${conversationId.value}-${replyMode.value}`
  );

  const draftMessage = computed(() => getDraftMessage.value(draftKey.value));

  const hasAnAssignedTeam = computed(() => !!currentChat.value?.meta?.team);

  const teamsList = computed(() => {
    if (hasAnAssignedTeam.value) {
      return [{ id: 0, name: t('TEAMS_SETTINGS.LIST.NONE') }, ...teams.value];
    }
    return teams.value;
  });

  const onChangeAssignee = action => {
    store.dispatch('assignAgent', {
      conversationId: currentChat.value.id,
      agentId: action.agentInfo.id,
    });
  };

  const onChangePriority = action => {
    store.dispatch('assignPriority', {
      conversationId: currentChat.value.id,
      priority: action.priority.key,
    });
  };

  const onChangeTeam = action => {
    store.dispatch('assignTeam', {
      conversationId: currentChat.value.id,
      teamId: action.teamInfo.id,
    });
  };

  const statusActions = computed(() => {
    const isOpen = currentChat.value?.status === wootConstants.STATUS_TYPE.OPEN;
    const isSnoozed =
      currentChat.value?.status === wootConstants.STATUS_TYPE.SNOOZED;
    const isResolved =
      currentChat.value?.status === wootConstants.STATUS_TYPE.RESOLVED;

    let actions = [];
    if (isOpen) {
      actions = [...OPEN_CONVERSATION_ACTIONS, ...SNOOZE_CONVERSATION_ACTIONS];
    } else if (isResolved || isSnoozed) {
      actions = RESOLVED_CONVERSATION_ACTIONS;
    }
    return prepareActions(actions, t);
  });

  const priorityOptions = computed(() =>
    createPriorityOptions(t, currentChat.value?.priority)
  );

  const assignAgentActions = computed(() => {
    const agentOptions = agentsList.value.map(agent => ({
      id: `agent-${agent.id}`,
      title: agent.name,
      parent: 'assign_an_agent',
      section: t('COMMAND_BAR.SECTIONS.CHANGE_ASSIGNEE'),
      agentInfo: agent,
      icon: ICON_ASSIGN_AGENT,
      handler: onChangeAssignee,
    }));
    return [
      {
        id: 'assign_an_agent',
        title: t('COMMAND_BAR.COMMANDS.ASSIGN_AN_AGENT'),
        section: t('COMMAND_BAR.SECTIONS.CONVERSATION'),
        icon: ICON_ASSIGN_AGENT,
        children: agentOptions.map(option => option.id),
      },
      ...agentOptions,
    ];
  });

  const assignPriorityActions = computed(() => {
    const options = priorityOptions.value.map(priority => ({
      id: `priority-${priority.key}`,
      title: priority.label,
      parent: 'assign_priority',
      section: t('COMMAND_BAR.SECTIONS.CHANGE_PRIORITY'),
      priority: priority,
      icon: priority.icon,
      handler: onChangePriority,
    }));
    return [
      {
        id: 'assign_priority',
        title: t('COMMAND_BAR.COMMANDS.ASSIGN_PRIORITY'),
        section: t('COMMAND_BAR.SECTIONS.CONVERSATION'),
        icon: ICON_ASSIGN_PRIORITY,
        children: options.map(option => option.id),
      },
      ...options,
    ];
  });

  const assignTeamActions = computed(() => {
    const teamOptions = teamsList.value.map(team => ({
      id: `team-${team.id}`,
      title: team.name,
      parent: 'assign_a_team',
      section: t('COMMAND_BAR.SECTIONS.CHANGE_TEAM'),
      teamInfo: team,
      icon: ICON_ASSIGN_TEAM,
      handler: onChangeTeam,
    }));
    return [
      {
        id: 'assign_a_team',
        title: t('COMMAND_BAR.COMMANDS.ASSIGN_A_TEAM'),
        section: t('COMMAND_BAR.SECTIONS.CONVERSATION'),
        icon: ICON_ASSIGN_TEAM,
        children: teamOptions.map(option => option.id),
      },
      ...teamOptions,
    ];
  });

  const addLabelActions = computed(() => {
    const availableLabels = inactiveLabels.value.map(label => ({
      id: label.title,
      title: `#${label.title}`,
      parent: 'add_a_label_to_the_conversation',
      section: t('COMMAND_BAR.SECTIONS.ADD_LABEL'),
      icon: ICON_ADD_LABEL,
      handler: action => addLabelToConversation({ title: action.id }),
    }));
    return [
      ...availableLabels,
      {
        id: 'add_a_label_to_the_conversation',
        title: t('COMMAND_BAR.COMMANDS.ADD_LABELS_TO_CONVERSATION'),
        section: t('COMMAND_BAR.SECTIONS.CONVERSATION'),
        icon: ICON_ADD_LABEL,
        children: inactiveLabels.value.map(label => label.title),
      },
    ];
  });

  const removeLabelActions = computed(() => {
    const activeLabelsComputed = activeLabels.value.map(label => ({
      id: label.title,
      title: `#${label.title}`,
      parent: 'remove_a_label_to_the_conversation',
      section: t('COMMAND_BAR.SECTIONS.REMOVE_LABEL'),
      icon: ICON_REMOVE_LABEL,
      handler: action => removeLabelFromConversation(action.id),
    }));
    return [
      ...activeLabelsComputed,
      {
        id: 'remove_a_label_to_the_conversation',
        title: t('COMMAND_BAR.COMMANDS.REMOVE_LABEL_FROM_CONVERSATION'),
        section: t('COMMAND_BAR.SECTIONS.CONVERSATION'),
        icon: ICON_REMOVE_LABEL,
        children: activeLabels.value.map(label => label.title),
      },
    ];
  });

  const labelActions = computed(() => {
    if (activeLabels.value.length) {
      return [...addLabelActions.value, ...removeLabelActions.value];
    }
    return addLabelActions.value;
  });

  const conversationAdditionalActions = computed(() => {
    return prepareActions(
      [
        currentChat.value.muted ? UNMUTE_ACTION : MUTE_ACTION,
        SEND_TRANSCRIPT_ACTION,
      ],
      t
    );
  });

  const AIAssistActions = computed(() => {
    const aiOptions = draftMessage.value
      ? createDraftMessageAIAssistActions(t)
      : createNonDraftMessageAIAssistActions(t, replyMode.value);
    const options = aiOptions.map(item => ({
      id: `ai-assist-${item.key}`,
      title: item.label,
      parent: 'ai_assist',
      section: t('COMMAND_BAR.SECTIONS.AI_ASSIST'),
      priority: item,
      icon: item.icon,
      handler: () => emitter.emit(CMD_AI_ASSIST, item.key),
    }));
    return [
      {
        id: 'ai_assist',
        title: t('COMMAND_BAR.COMMANDS.AI_ASSIST'),
        section: t('COMMAND_BAR.SECTIONS.AI_ASSIST'),
        icon: ICON_AI_ASSIST,
        children: options.map(option => option.id),
      },
      ...options,
    ];
  });

  const isConversationOrInboxRoute = computed(() => {
    return isAConversationRoute(route.name) || isAInboxViewRoute(route.name);
  });

  const shouldShowSnoozeOption = computed(() => {
    return (
      isAConversationRoute(route.name, true, false) && contextMenuChatId.value
    );
  });

  const getDefaultConversationHotKeys = computed(() => {
    const defaultConversationHotKeys = [
      ...statusActions.value,
      ...conversationAdditionalActions.value,
      ...assignAgentActions.value,
      ...assignTeamActions.value,
      ...labelActions.value,
      ...assignPriorityActions.value,
    ];
    if (isAIIntegrationEnabled.value) {
      return [...defaultConversationHotKeys, ...AIAssistActions.value];
    }
    return defaultConversationHotKeys;
  });

  const conversationHotKeys = computed(() => {
    if (shouldShowSnoozeOption.value) {
      return prepareActions(SNOOZE_CONVERSATION_ACTIONS, t);
    }
    if (isConversationOrInboxRoute.value) {
      return getDefaultConversationHotKeys.value;
    }
    return [];
  });

  return {
    conversationHotKeys,
  };
}
