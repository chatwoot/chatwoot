<template>
  <div class="menu-container">
    <template v-for="option in statusMenuConfig">
      <menu-item
        v-if="show(option.key)"
        :key="option.key"
        :option="option"
        variant="icon"
        @click="toggleStatus(option.key, null)"
      />
    </template>
    <menu-item-with-submenu :option="snoozeMenuConfig">
      <menu-item
        v-for="(option, i) in snoozeMenuConfig.options"
        :key="i"
        :option="option"
        @click="snoozeConversation(option.snoozedUntil)"
      />
    </menu-item-with-submenu>
    <menu-item-with-submenu
      :option="labelMenuConfig"
      :sub-menu-available="!!labels.length"
    >
      <template>
        <menu-item
          v-for="label in labels"
          :key="label.id"
          :option="generateMenuLabelConfig(label, 'label')"
          variant="label"
          @click="$emit('assign-label', label)"
        />
      </template>
    </menu-item-with-submenu>
    <menu-item-with-submenu
      :option="agentMenuConfig"
      :sub-menu-available="!!assignableAgents.length"
    >
      <agent-loading-placeholder v-if="assignableAgentsUiFlags.isFetching" />
      <template v-else>
        <menu-item
          v-for="agent in assignableAgents"
          :key="agent.id"
          :option="generateMenuLabelConfig(agent, 'agent')"
          variant="agent"
          @click="$emit('assign-agent', agent)"
        />
      </template>
    </menu-item-with-submenu>
    <menu-item-with-submenu
      :option="teamMenuConfig"
      :sub-menu-available="!!teams.length"
    >
      <menu-item
        v-for="team in teams"
        :key="team.id"
        :option="generateMenuLabelConfig(team, 'team')"
        @click="$emit('assign-team', team)"
      />
    </menu-item-with-submenu>
  </div>
</template>

<script>
import MenuItem from './menuItem.vue';
import MenuItemWithSubmenu from './menuItemWithSubmenu.vue';
import wootConstants from 'dashboard/constants.js';
import snoozeTimesMixin from 'dashboard/mixins/conversation/snoozeTimesMixin';
import { mapGetters } from 'vuex';
import AgentLoadingPlaceholder from './agentLoadingPlaceholder.vue';
export default {
  components: {
    MenuItem,
    MenuItemWithSubmenu,
    AgentLoadingPlaceholder,
  },
  mixins: [snoozeTimesMixin],
  props: {
    status: {
      type: String,
      default: '',
    },
    inboxId: {
      type: Number,
      default: null,
    },
  },
  data() {
    return {
      STATUS_TYPE: wootConstants.STATUS_TYPE,
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
      snoozeMenuConfig: {
        key: 'snooze',
        label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.TITLE'),
        icon: 'snooze',
        options: [
          {
            label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.NEXT_REPLY'),
            key: 'next-reply',
            snoozedUntil: null,
          },
          {
            label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.TOMORROW'),
            key: 'tomorrow',
            snoozedUntil: 'tomorrow',
          },
          {
            label: this.$t('CONVERSATION.CARD_CONTEXT_MENU.SNOOZE.NEXT_WEEK'),
            key: 'next-week',
            snoozedUntil: 'nextWeek',
          },
        ],
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
    }),
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
        ...this.$store.getters['inboxAssignableAgents/getAssignableAgents'](
          this.inboxId
        ),
      ];
    },
  },
  mounted() {
    this.$store.dispatch('inboxAssignableAgents/fetch', [this.inboxId]);
  },
  methods: {
    toggleStatus(status, snoozedUntil) {
      this.$emit('update-conversation', status, snoozedUntil);
    },
    snoozeConversation(snoozedUntil) {
      this.$emit(
        'update-conversation',
        this.STATUS_TYPE.SNOOZED,
        this.snoozeTimes[snoozedUntil] || null
      );
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
        ...(type === 'text' && { label: option.label }),
        ...(type === 'label' && { label: option.title }),
        ...(type === 'agent' && { label: option.name }),
        ...(type === 'team' && { label: option.name }),
      };
    },
  },
};
</script>

<style lang="scss" scoped>
.menu-container {
  padding: var(--space-smaller);
  background-color: var(--white);
  box-shadow: var(--shadow-context-menu);
  border-radius: var(--border-radius-normal);
}
</style>
