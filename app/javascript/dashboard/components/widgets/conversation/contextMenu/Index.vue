<script>
import { mapGetters } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import {
  getSortedAgentsByAvailability,
  getAgentsByUpdatedPresence,
} from 'dashboard/helper/agentHelper.js';
import { picoSearch } from '@scmmishra/pico-search';
import MenuItem from './menuItem.vue';
import MenuItemWithSubmenu from './menuItemWithSubmenu.vue';
import wootConstants from 'dashboard/constants/globals';
import AgentLoadingPlaceholder from './agentLoadingPlaceholder.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const MENU = {
  MARK_AS_READ: 'mark-as-read',
  MARK_AS_UNREAD: 'mark-as-unread',
  PRIORITY: 'priority',
  STATUS: 'status',
  SNOOZE: 'snooze',
  AGENT: 'agent',
  TEAM: 'team',
  LABEL: 'label',
  DELETE: 'delete',
  OPEN_NEW_TAB: 'open-new-tab',
  COPY_LINK: 'copy-link',
};

export default {
  components: {
    MenuItem,
    MenuItemWithSubmenu,
    AgentLoadingPlaceholder,
    NextInput,
    Icon,
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
    conversationLabels: {
      type: Array,
      default: () => [],
    },
    conversationUrl: {
      type: String,
      default: '',
    },
    allowedOptions: {
      type: Array,
      default: () => [],
    },
  },
  emits: [
    'updateConversation',
    'assignPriority',
    'markAsUnread',
    'markAsRead',
    'assignAgent',
    'assignTeam',
    'assignLabel',
    'removeLabel',
    'deleteConversation',
    'close',
  ],
  setup() {
    const { isAdmin } = useAdmin();
    return {
      isAdmin,
    };
  },
  data() {
    return {
      MENU,
      labelSearchQuery: '',
      STATUS_TYPE: wootConstants.STATUS_TYPE,
      readOption: {
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.MARK_AS_READ'),
        icon: 'mail',
      },
      unreadOption: {
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.MARK_AS_UNREAD'),
        icon: 'mail-unread',
      },
      statusMenuConfig: [
        {
          key: wootConstants.STATUS_TYPE.RESOLVED,
          label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.RESOLVED'),
          icon: 'checkmark',
        },
        {
          key: wootConstants.STATUS_TYPE.OPEN,
          label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.REOPEN'),
          icon: 'arrow-redo',
        },
        {
          key: wootConstants.STATUS_TYPE.PENDING,
          label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.PENDING'),
          icon: 'book-clock',
        },
      ],
      snoozeOption: {
        key: wootConstants.STATUS_TYPE.SNOOZED,
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.TITLE'),
        icon: 'snooze',
      },
      priorityConfig: {
        key: MENU.PRIORITY,
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
        key: MENU.LABEL,
        icon: 'tag',
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.ASSIGN_LABEL'),
      },
      agentMenuConfig: {
        key: MENU.AGENT,
        icon: 'person-add',
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.ASSIGN_AGENT'),
      },
      teamMenuConfig: {
        key: MENU.TEAM,
        icon: 'people-team-add',
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.ASSIGN_TEAM'),
      },
      deleteOption: {
        key: MENU.DELETE,
        icon: 'delete',
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.DELETE'),
      },
      openInNewTabOption: {
        key: MENU.OPEN_NEW_TAB,
        icon: 'open',
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.OPEN_IN_NEW_TAB'),
      },
      copyLinkOption: {
        key: MENU.COPY_LINK,
        icon: 'copy',
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.COPY_LINK'),
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
    filteredLabels() {
      const labels = this.labelSearchQuery
        ? picoSearch(this.labels, this.labelSearchQuery, ['title'])
        : this.labels;
      // Assigned labels first, keeping each group's existing order.
      const isAssigned = label => this.conversationLabels.includes(label.title);
      return [...labels].sort((a, b) => isAssigned(b) - isAssigned(a));
    },
  },
  mounted() {
    this.$store.dispatch('inboxAssignableAgents/fetch', [this.inboxId]);
  },
  methods: {
    isAllowed(keys) {
      if (!this.allowedOptions.length) return true;
      return keys.some(key => this.allowedOptions.includes(key));
    },
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
    deleteConversation() {
      this.$emit('deleteConversation', this.chatId);
    },
    openInNewTab() {
      if (!this.conversationUrl) return;

      const url = `${window.chatwootConfig.hostURL}${this.conversationUrl}`;
      window.open(url, '_blank', 'noopener,noreferrer');
      this.$emit('close');
    },
    async copyConversationLink() {
      if (!this.conversationUrl) return;
      try {
        const url = `${window.chatwootConfig.hostURL}${this.conversationUrl}`;
        await copyTextToClipboard(url);
        useAlert(this.$t('CONVERSATION.CARD_CONTEXT_MENU.COPY_LINK_SUCCESS'));
        this.$emit('close');
      } catch (error) {
        // error
      }
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
  <div
    class="p-1 rounded-md shadow-xl bg-n-alpha-3/50 backdrop-blur-[100px] outline-1 outline outline-n-weak/50"
  >
    <template v-if="isAllowed([MENU.MARK_AS_READ, MENU.MARK_AS_UNREAD])">
      <MenuItem
        v-if="!hasUnreadMessages"
        :option="unreadOption"
        variant="icon"
        @click.stop="$emit('markAsUnread')"
      />
      <MenuItem
        v-else
        :option="readOption"
        variant="icon"
        @click.stop="$emit('markAsRead')"
      />
      <hr class="m-1 rounded border-b border-n-weak dark:border-n-weak" />
    </template>
    <template v-if="isAllowed([MENU.STATUS, MENU.SNOOZE])">
      <template v-for="option in statusMenuConfig">
        <MenuItem
          v-if="show(option.key) && isAllowed([MENU.STATUS])"
          :key="option.key"
          :option="option"
          variant="icon"
          @click.stop="toggleStatus(option.key, null)"
        />
      </template>
      <MenuItem
        v-if="showSnooze && isAllowed([MENU.SNOOZE])"
        :option="snoozeOption"
        variant="icon"
        @click.stop="snoozeConversation()"
      />
      <hr class="m-1 rounded border-b border-n-weak dark:border-n-weak" />
    </template>
    <template
      v-if="isAllowed([MENU.PRIORITY, MENU.LABEL, MENU.AGENT, MENU.TEAM])"
    >
      <MenuItemWithSubmenu
        v-if="isAllowed([MENU.PRIORITY])"
        :option="priorityConfig"
      >
        <MenuItem
          v-for="(option, i) in priorityConfig.options"
          :key="i"
          :option="option"
          @click.stop="assignPriority(option.key)"
        />
      </MenuItemWithSubmenu>
      <MenuItemWithSubmenu
        v-if="isAllowed([MENU.LABEL])"
        :option="labelMenuConfig"
        :sub-menu-available="!!labels.length"
      >
        <div class="pb-1 w-[12.5rem]">
          <NextInput
            v-model="labelSearchQuery"
            type="search"
            size="sm"
            class="w-full"
            custom-input-class="!ps-8 !text-xs"
            :placeholder="$t('CONVERSATION.CARD_CONTEXT_MENU.SEARCH_LABELS')"
            @click.stop
            @keydown.stop
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute z-10 -translate-y-1/2 pointer-events-none size-3.5 text-n-slate-10 top-1/2 start-2"
              />
            </template>
          </NextInput>
        </div>
        <div class="overflow-x-hidden overflow-y-auto max-h-[12.5rem]">
          <MenuItem
            v-for="label in filteredLabels"
            :key="label.id"
            :option="generateMenuLabelConfig(label, 'label')"
            :variant="
              conversationLabels.includes(label.title)
                ? 'label-assigned'
                : 'label'
            "
            @mousedown.prevent
            @click.stop="
              conversationLabels.includes(label.title)
                ? $emit('removeLabel', label)
                : $emit('assignLabel', label)
            "
          />
          <p
            v-if="!filteredLabels.length"
            class="px-2 py-2 m-0 text-xs text-center text-n-slate-11"
          >
            {{ $t('CONVERSATION.CARD_CONTEXT_MENU.NO_LABELS_FOUND') }}
          </p>
        </div>
      </MenuItemWithSubmenu>
      <MenuItemWithSubmenu
        v-if="isAllowed([MENU.AGENT])"
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
        v-if="isAllowed([MENU.TEAM])"
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
      <hr class="m-1 rounded border-b border-n-weak dark:border-n-weak" />
    </template>
    <template v-if="isAllowed([MENU.OPEN_NEW_TAB, MENU.COPY_LINK])">
      <MenuItem
        v-if="isAllowed([MENU.OPEN_NEW_TAB])"
        :option="openInNewTabOption"
        variant="icon"
        @click.stop="openInNewTab"
      />
      <MenuItem
        v-if="isAllowed([MENU.COPY_LINK])"
        :option="copyLinkOption"
        variant="icon"
        @click.stop="copyConversationLink"
      />
    </template>
    <template v-if="isAdmin && isAllowed([MENU.DELETE])">
      <hr class="m-1 rounded border-b border-n-weak dark:border-n-weak" />
      <MenuItem
        :option="deleteOption"
        variant="icon"
        @click.stop="deleteConversation"
      />
    </template>
  </div>
</template>
