import { mapGetters } from 'vuex';
import wootConstants from 'dashboard/constants/globals';
import { emitter } from 'shared/helpers/mitt';

import { CMD_AI_ASSIST } from './commandBarBusEvents';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import aiMixin from 'dashboard/mixins/aiMixin';
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
} from './CommandBarIcons';

import {
  OPEN_CONVERSATION_ACTIONS,
  SNOOZE_CONVERSATION_ACTIONS,
  RESOLVED_CONVERSATION_ACTIONS,
  SEND_TRANSCRIPT_ACTION,
  UNMUTE_ACTION,
  MUTE_ACTION,
} from './commandBarActions';
import {
  isAConversationRoute,
  isAInboxViewRoute,
} from '../../../helper/routeHelpers';
export default {
  mixins: [aiMixin],
  watch: {
    assignableAgents() {
      this.setCommandbarData();
    },
    currentChat() {
      this.setCommandbarData();
    },
    teamsList() {
      this.setCommandbarData();
    },
    activeLabels() {
      this.setCommandbarData();
    },
    draftMessage() {
      this.setCommandbarData();
    },
    replyMode() {
      this.setCommandbarData();
    },
    contextMenuChatId() {
      this.setCommandbarData();
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      replyMode: 'draftMessages/getReplyEditorMode',
      contextMenuChatId: 'getContextMenuChatId',
    }),
    draftMessage() {
      return this.$store.getters['draftMessages/get'](this.draftKey);
    },
    draftKey() {
      return `draft-${this.conversationId}-${this.replyMode}`;
    },
    inboxId() {
      return this.currentChat?.inbox_id;
    },
    conversationId() {
      return this.currentChat?.id;
    },

    statusActions() {
      const isOpen =
        this.currentChat?.status === wootConstants.STATUS_TYPE.OPEN;
      const isSnoozed =
        this.currentChat?.status === wootConstants.STATUS_TYPE.SNOOZED;
      const isResolved =
        this.currentChat?.status === wootConstants.STATUS_TYPE.RESOLVED;

      let actions = [];
      if (isOpen) {
        actions = [
          ...OPEN_CONVERSATION_ACTIONS,
          ...SNOOZE_CONVERSATION_ACTIONS,
        ];
      } else if (isResolved || isSnoozed) {
        actions = RESOLVED_CONVERSATION_ACTIONS;
      }
      return this.prepareActions(actions);
    },

    priorityOptions() {
      return [
        {
          label: this.$t('CONVERSATION.PRIORITY.OPTIONS.NONE'),
          key: null,
          icon: ICON_PRIORITY_NONE,
        },
        {
          label: this.$t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
          key: 'urgent',
          icon: ICON_PRIORITY_URGENT,
        },
        {
          label: this.$t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
          key: 'high',
          icon: ICON_PRIORITY_HIGH,
        },
        {
          label: this.$t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
          key: 'medium',
          icon: ICON_PRIORITY_MEDIUM,
        },
        {
          label: this.$t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
          key: 'low',
          icon: ICON_PRIORITY_LOW,
        },
      ].filter(item => item.key !== this.currentChat?.priority);
    },
    assignAgentActions() {
      const agentOptions = this.agentsList.map(agent => ({
        id: `agent-${agent.id}`,
        title: agent.name,
        parent: 'assign_an_agent',
        section: this.$t('COMMAND_BAR.SECTIONS.CHANGE_ASSIGNEE'),
        agentInfo: agent,
        icon: ICON_ASSIGN_AGENT,
        handler: this.onChangeAssignee,
      }));
      return [
        {
          id: 'assign_an_agent',
          title: this.$t('COMMAND_BAR.COMMANDS.ASSIGN_AN_AGENT'),
          section: this.$t('COMMAND_BAR.SECTIONS.CONVERSATION'),
          icon: ICON_ASSIGN_AGENT,
          children: agentOptions.map(option => option.id),
        },
        ...agentOptions,
      ];
    },
    assignPriorityActions() {
      const options = this.priorityOptions.map(priority => ({
        id: `priority-${priority.key}`,
        title: priority.label,
        parent: 'assign_priority',
        section: this.$t('COMMAND_BAR.SECTIONS.CHANGE_PRIORITY'),
        priority: priority,
        icon: priority.icon,
        handler: this.onChangePriority,
      }));
      return [
        {
          id: 'assign_priority',
          title: this.$t('COMMAND_BAR.COMMANDS.ASSIGN_PRIORITY'),
          section: this.$t('COMMAND_BAR.SECTIONS.CONVERSATION'),
          icon: ICON_ASSIGN_PRIORITY,
          children: options.map(option => option.id),
        },
        ...options,
      ];
    },
    assignTeamActions() {
      const teamOptions = this.teamsList.map(team => ({
        id: `team-${team.id}`,
        title: team.name,
        parent: 'assign_a_team',
        section: this.$t('COMMAND_BAR.SECTIONS.CHANGE_TEAM'),
        teamInfo: team,
        icon: ICON_ASSIGN_TEAM,
        handler: this.onChangeTeam,
      }));
      return [
        {
          id: 'assign_a_team',
          title: this.$t('COMMAND_BAR.COMMANDS.ASSIGN_A_TEAM'),
          section: this.$t('COMMAND_BAR.SECTIONS.CONVERSATION'),
          icon: ICON_ASSIGN_TEAM,
          children: teamOptions.map(option => option.id),
        },
        ...teamOptions,
      ];
    },

    addLabelActions() {
      const availableLabels = this.inactiveLabels.map(label => ({
        id: label.title,
        title: `#${label.title}`,
        parent: 'add_a_label_to_the_conversation',
        section: this.$t('COMMAND_BAR.SECTIONS.ADD_LABEL'),
        icon: ICON_ADD_LABEL,
        handler: action => this.addLabelToConversation({ title: action.id }),
      }));
      return [
        ...availableLabels,
        {
          id: 'add_a_label_to_the_conversation',
          title: this.$t('COMMAND_BAR.COMMANDS.ADD_LABELS_TO_CONVERSATION'),
          section: this.$t('COMMAND_BAR.SECTIONS.CONVERSATION'),
          icon: ICON_ADD_LABEL,
          children: this.inactiveLabels.map(label => label.title),
        },
      ];
    },
    removeLabelActions() {
      const activeLabels = this.activeLabels.map(label => ({
        id: label.title,
        title: `#${label.title}`,
        parent: 'remove_a_label_to_the_conversation',
        section: this.$t('COMMAND_BAR.SECTIONS.REMOVE_LABEL'),
        icon: ICON_REMOVE_LABEL,
        handler: action => this.removeLabelFromConversation(action.id),
      }));
      return [
        ...activeLabels,
        {
          id: 'remove_a_label_to_the_conversation',
          title: this.$t('COMMAND_BAR.COMMANDS.REMOVE_LABEL_FROM_CONVERSATION'),
          section: this.$t('COMMAND_BAR.SECTIONS.CONVERSATION'),
          icon: ICON_REMOVE_LABEL,
          children: this.activeLabels.map(label => label.title),
        },
      ];
    },
    labelActions() {
      if (this.activeLabels.length) {
        return [...this.addLabelActions, ...this.removeLabelActions];
      }
      return this.addLabelActions;
    },
    conversationAdditionalActions() {
      return this.prepareActions([
        this.currentChat.muted ? UNMUTE_ACTION : MUTE_ACTION,
        SEND_TRANSCRIPT_ACTION,
      ]);
    },

    nonDraftMessageAIAssistActions() {
      if (this.replyMode === REPLY_EDITOR_MODES.REPLY) {
        return [
          {
            label: this.$t(
              'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.REPLY_SUGGESTION'
            ),
            key: 'reply_suggestion',
            icon: ICON_AI_ASSIST,
          },
        ];
      }
      return [
        {
          label: this.$t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.SUMMARIZE'),
          key: 'summarize',
          icon: ICON_AI_SUMMARY,
        },
      ];
    },

    draftMessageAIAssistActions() {
      return [
        {
          label: this.$t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.REPHRASE'),
          key: 'rephrase',
          icon: ICON_AI_ASSIST,
        },
        {
          label: this.$t(
            'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.FIX_SPELLING_GRAMMAR'
          ),
          key: 'fix_spelling_grammar',
          icon: ICON_AI_GRAMMAR,
        },
        {
          label: this.$t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.EXPAND'),
          key: 'expand',
          icon: ICON_AI_EXPAND,
        },
        {
          label: this.$t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.SHORTEN'),
          key: 'shorten',
          icon: ICON_AI_SHORTEN,
        },
        {
          label: this.$t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.MAKE_FRIENDLY'),
          key: 'make_friendly',
          icon: ICON_AI_ASSIST,
        },
        {
          label: this.$t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.MAKE_FORMAL'),
          key: 'make_formal',
          icon: ICON_AI_ASSIST,
        },
        {
          label: this.$t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.SIMPLIFY'),
          key: 'simplify',
          icon: ICON_AI_ASSIST,
        },
      ];
    },

    AIAssistActions() {
      const aiOptions = this.draftMessage
        ? this.draftMessageAIAssistActions
        : this.nonDraftMessageAIAssistActions;
      const options = aiOptions.map(item => ({
        id: `ai-assist-${item.key}`,
        title: item.label,
        parent: 'ai_assist',
        section: this.$t('COMMAND_BAR.SECTIONS.AI_ASSIST'),
        priority: item,
        icon: item.icon,
        handler: () => emitter.emit(CMD_AI_ASSIST, item.key),
      }));
      return [
        {
          id: 'ai_assist',
          title: this.$t('COMMAND_BAR.COMMANDS.AI_ASSIST'),
          section: this.$t('COMMAND_BAR.SECTIONS.AI_ASSIST'),
          icon: ICON_AI_ASSIST,
          children: options.map(option => option.id),
        },
        ...options,
      ];
    },

    isConversationOrInboxRoute() {
      return (
        isAConversationRoute(this.$route.name) ||
        isAInboxViewRoute(this.$route.name)
      );
    },

    shouldShowSnoozeOption() {
      return (
        isAConversationRoute(this.$route.name, true, false) &&
        this.contextMenuChatId
      );
    },

    getDefaultConversationHotKeys() {
      const defaultConversationHotKeys = [
        ...this.statusActions,
        ...this.conversationAdditionalActions,
        ...this.assignAgentActions,
        ...this.assignTeamActions,
        ...this.labelActions,
        ...this.assignPriorityActions,
      ];
      if (this.isAIIntegrationEnabled) {
        return [...defaultConversationHotKeys, ...this.AIAssistActions];
      }
      return defaultConversationHotKeys;
    },

    conversationHotKeys() {
      if (this.shouldShowSnoozeOption) {
        return this.prepareActions(SNOOZE_CONVERSATION_ACTIONS);
      }
      if (this.isConversationOrInboxRoute) {
        return this.getDefaultConversationHotKeys;
      }
      return [];
    },
  },

  methods: {
    onChangeAssignee(action) {
      this.$store.dispatch('assignAgent', {
        conversationId: this.currentChat.id,
        agentId: action.agentInfo.id,
      });
    },
    onChangePriority(action) {
      this.$store.dispatch('assignPriority', {
        conversationId: this.currentChat.id,
        priority: action.priority.key,
      });
    },
    onChangeTeam(action) {
      this.$store.dispatch('assignTeam', {
        conversationId: this.currentChat.id,
        teamId: action.teamInfo.id,
      });
    },
    prepareActions(actions) {
      return actions.map(action => ({
        ...action,
        title: this.$t(action.title),
        section: this.$t(action.section),
      }));
    },
  },
};
