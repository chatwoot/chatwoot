<script>
import { mapGetters } from 'vuex';
import {
  getSortedAgentsByAvailability,
  getAgentsByUpdatedPresence,
} from 'dashboard/helper/agentHelper.js';
import MenuItem from './menuItem.vue';
import MenuItemWithSubmenu from './menuItemWithSubmenu.vue';
import wootConstants from 'dashboard/constants/globals';
import AgentLoadingPlaceholder from './agentLoadingPlaceholder.vue';

export default {
  components: {
    MenuItem,
    MenuItemWithSubmenu,
    AgentLoadingPlaceholder,
  },
  props: {
    chatId: {
      type: Number,
      default: null,
    },
    status: {
      type: String,
      default: '',
    },
    hasUnreadMessages: {
      type: Boolean,
      default: false,
    },
    inboxId: {
      type: Number,
      default: null,
    },
    priority: {
      type: String,
      default: null,
    },
  },
  emits: [
    'updateConversation',
    'assignPriority',
    'markAsUnread',
    'assignAgent',
    'assignTeam',
    'assignLabel',
  ],
  data() {
    return {
      STATUS_TYPE: wootConstants.STATUS_TYPE,
      unreadOption: {
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.MARK_AS_UNREAD'),
        icon: 'mail',
      },
      statusMenuConfig: [
        {
          key: wootConstants.STATUS_TYPE.RESOLVED,
          label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.RESOLVED'),
          icon: 'checkmark',
        },
        {
          key: wootConstants.STATUS_TYPE.PENDING,
          label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.PENDING'),
          icon: 'book-clock',
        },
        {
          key: wootConstants.STATUS_TYPE.OPEN,
          label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.REOPEN'),
          icon: 'arrow-redo',
        },
      ],
      snoozeOption: {
        key: wootConstants.STATUS_TYPE.SNOOZED,
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.TITLE'),
        icon: 'snooze',
      },
      priorityConfig: {
        key: 'priority',
        label: this.$t('CONVERSATION.PRIORITY.TITLE'),
        icon: 'warning',
        options: [
          {
            label: this.$t('CONVERSATION.PRIORITY.OPTIONS.NONE'),
            key: null,
          },
          {
            label: this.$t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
            key: 'urgent',
          },
          {
            label: this.$t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
            key: 'high',
          },
          {
            label: this.$t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
            key: 'medium',
          },
          {
            label: this.$t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
            key: 'low',
          },
        ].filter(item => item.key !== this.priority),
      },
      labelMenuConfig: {
        key: 'label',
        icon: 'tag',
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.ASSIGN_LABEL'),
      },
      agentMenuConfig: {
        key: 'agent',
        icon: 'person-add',
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.ASSIGN_AGENT'),
      },
      teamMenuConfig: {
        key: 'team',
        icon: 'people-team-add',
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.ASSIGN_TEAM'),
      },
    };
  },
  computed: {
    ...mapGetters({
      labels: 'labels/getLabels',
      teams: 'teams/getTeams',
      assignableAgentsUiFlags: 'inboxAssignableAgents/getUIFlags',
      currentUser: 'getCurrentUser',
      currentAccountId: 'getCurrentAccountId',
    }),
    filteredAgentOnAvailability() {
      const agents = this.$store.getters[
        'inboxAssignableAgents/getAssignableAgents'
      ](this.inboxId);
      const agentsByUpdatedPresence = getAgentsByUpdatedPresence(
        agents,
        this.currentUser,
        this.currentAccountId
      );
      const filteredAgents = getSortedAgentsByAvailability(
        agentsByUpdatedPresence
      );
      return filteredAgents;
    },
    assignableAgents() {
      return [
        {
          confirmed: true,
          name: 'None',
          id: null,
          role: 'agent',
          account_id: 0,
          email: 'None',
        },
        ...this.filteredAgentOnAvailability,
      ];
    },
    showSnooze() {
      // Don't show snooze if the conversation is already snoozed/resolved/pending
      return this.status === wootConstants.STATUS_TYPE.OPEN;
    },
  },
  mounted() {
    this.$store.dispatch('inboxAssignableAgents/fetch', [this.inboxId]);
  },
  methods: {
    toggleStatus(status, snoozedUntil) {
      this.$emit('updateConversation', status, snoozedUntil);
    },
    async snoozeConversation() {
      await this.$store.dispatch('setContextMenuChatId', this.chatId);
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'snooze_conversation' });
    },
    assignPriority(priority) {
      this.$emit('assignPriority', priority);
    },
    show(key) {
      // If the conversation status is same as the action, then don't display the option
      // i.e.: Don't show an option to resolve if the conversation is already resolved.
      return this.status !== key;
    },
    generateMenuLabelConfig(option, type = 'text') {
      return {
        key: option.id,
        ...(type === 'icon' && { icon: option.icon }),
        ...(type === 'label' && { color: option.color }),
        ...(type === 'agent' && { thumbnail: option.thumbnail }),
        ...(type === 'agent' && { status: option.availability_status }),
        ...(type === 'text' && { label: option.label }),
        ...(type === 'label' && { label: option.title }),
        ...(type === 'agent' && { label: option.name }),
        ...(type === 'team' && { label: option.name }),
      };
    },
  },
};
</script>

<template>
  <div class="p-1 bg-white rounded-md shadow-xl dark:bg-slate-700">
    <MenuItem
      v-if="!hasUnreadMessages"
      :option="unreadOption"
      variant="icon"
      @click.stop="$emit('markAsUnread')"
    />
    <template v-for="option in statusMenuConfig">
      <MenuItem
        v-if="show(option.key)"
        :key="option.key"
        :option="option"
        variant="icon"
        @click.stop="toggleStatus(option.key, null)"
      />
    </template>
    <MenuItem
      v-if="showSnooze"
      :option="snoozeOption"
      variant="icon"
      @click.stop="snoozeConversation()"
    />

    <MenuItemWithSubmenu :option="priorityConfig">
      <MenuItem
        v-for="(option, i) in priorityConfig.options"
        :key="i"
        :option="option"
        @click.stop="assignPriority(option.key)"
      />
    </MenuItemWithSubmenu>
    <MenuItemWithSubmenu
      :option="labelMenuConfig"
      :sub-menu-available="!!labels.length"
    >
      <MenuItem
        v-for="label in labels"
        :key="label.id"
        :option="generateMenuLabelConfig(label, 'label')"
        variant="label"
        @click.stop="$emit('assignLabel', label)"
      />
    </MenuItemWithSubmenu>
    <MenuItemWithSubmenu
      :option="agentMenuConfig"
      :sub-menu-available="!!assignableAgents.length"
    >
      <AgentLoadingPlaceholder v-if="assignableAgentsUiFlags.isFetching" />
      <template v-else>
        <MenuItem
          v-for="agent in assignableAgents"
          :key="agent.id"
          :option="generateMenuLabelConfig(agent, 'agent')"
          variant="agent"
          @click.stop="$emit('assignAgent', agent)"
        />
      </template>
    </MenuItemWithSubmenu>
    <MenuItemWithSubmenu
      :option="teamMenuConfig"
      :sub-menu-available="!!teams.length"
    >
      <MenuItem
        v-for="team in teams"
        :key="team.id"
        :option="generateMenuLabelConfig(team, 'team')"
        @click.stop="$emit('assignTeam', team)"
      />
    </MenuItemWithSubmenu>
  </div>
</template>
