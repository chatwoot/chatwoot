import { mapGetters } from 'vuex';
import wootConstants from '../../../constants';
import {
  CMD_MUTE_CONVERSATION,
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_SNOOZE_CONVERSATION,
  CMD_UNMUTE_CONVERSATION,
} from './commandBarBusEvents';

import {
  ICON_ADD_LABEL,
  ICON_ASSIGN_AGENT,
  ICON_ASSIGN_TEAM,
  ICON_MUTE_CONVERSATION,
  ICON_REMOVE_LABEL,
  ICON_REOPEN_CONVERSATION,
  ICON_RESOLVE_CONVERSATION,
  ICON_SEND_TRANSCRIPT,
  ICON_SNOOZE_CONVERSATION,
  ICON_SNOOZE_UNTIL_NEXT_REPLY,
  ICON_SNOOZE_UNTIL_NEXT_WEEK,
  ICON_SNOOZE_UNTIL_TOMORRROW,
  ICON_UNMUTE_CONVERSATION,
} from './CommandBarIcons';

const OPEN_CONVERSATION_ACTIONS = [
  {
    id: 'resolve_conversation',
    title: 'COMMAND_BAR.COMMANDS.RESOLVE_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
    icon: ICON_RESOLVE_CONVERSATION,
    handler: () => bus.$emit(CMD_RESOLVE_CONVERSATION),
  },
  {
    id: 'snooze_conversation',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
    icon: ICON_SNOOZE_CONVERSATION,
    children: ['until_next_reply', 'until_tomorrow', 'until_next_week'],
  },
  {
    id: 'until_next_reply',
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_REPLY',
    parent: 'snooze_conversation',
    icon: ICON_SNOOZE_UNTIL_NEXT_REPLY,
    handler: () => bus.$emit(CMD_SNOOZE_CONVERSATION, 'nextReply'),
  },
  {
    id: 'until_tomorrow',
    title: 'COMMAND_BAR.COMMANDS.UNTIL_TOMORROW',
    parent: 'snooze_conversation',
    icon: ICON_SNOOZE_UNTIL_TOMORRROW,
    handler: () => bus.$emit(CMD_SNOOZE_CONVERSATION, 'tomorrow'),
  },
  {
    id: 'until_next_week',
    title: 'COMMAND_BAR.COMMANDS.UNTIL_NEXT_WEEK',
    parent: 'snooze_conversation',
    icon: ICON_SNOOZE_UNTIL_NEXT_WEEK,
    handler: () => bus.$emit(CMD_SNOOZE_CONVERSATION, 'nextWeek'),
  },
];

const RESOLVED_CONVERSATION_ACTIONS = [
  {
    id: 'reopen_conversation',
    title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
    section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
    icon: ICON_REOPEN_CONVERSATION,
    handler: () => bus.$emit(CMD_REOPEN_CONVERSATION),
  },
];

const SEND_TRANSCRIPT_ACTION = {
  id: 'send_transcript',
  title: 'COMMAND_BAR.COMMANDS.SEND_TRANSCRIPT',
  section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
  icon: ICON_SEND_TRANSCRIPT,
  handler: () => bus.$emit(CMD_SEND_TRANSCRIPT),
};

const UNMUTE_ACTION = {
  id: 'unmute_conversation',
  title: 'COMMAND_BAR.COMMANDS.UNMUTE_CONVERSATION',
  section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
  icon: ICON_UNMUTE_CONVERSATION,
  handler: () => bus.$emit(CMD_UNMUTE_CONVERSATION),
};

const MUTE_ACTION = {
  id: 'mute_conversation',
  title: 'COMMAND_BAR.COMMANDS.MUTE_CONVERSATION',
  section: 'COMMAND_BAR.SECTIONS.CONVERSATION',
  icon: ICON_MUTE_CONVERSATION,
  handler: () => bus.$emit(CMD_MUTE_CONVERSATION),
};

export const isAConversationRoute = routeName =>
  [
    'inbox_conversation',
    'conversation_through_mentions',
    'conversation_through_unattended',
    'conversation_through_inbox',
    'conversations_through_label',
    'conversations_through_team',
  ].includes(routeName);

export default {
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
  },
  computed: {
    ...mapGetters({ currentChat: 'getSelectedChat' }),
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
        actions = OPEN_CONVERSATION_ACTIONS;
      } else if (isResolved || isSnoozed) {
        actions = RESOLVED_CONVERSATION_ACTIONS;
      }
      return this.prepareActions(actions);
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
    conversationHotKeys() {
      if (isAConversationRoute(this.$route.name)) {
        return [
          ...this.statusActions,
          ...this.conversationAdditionalActions,
          ...this.assignAgentActions,
          ...this.assignTeamActions,
          ...this.labelActions,
        ];
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
