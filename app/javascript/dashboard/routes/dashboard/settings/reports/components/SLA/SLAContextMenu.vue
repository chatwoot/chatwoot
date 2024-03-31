<template>
  <div
    class="bg-white dark:bg-slate- rounded-xl border-slate-100 dark:border-slate-900 border-solid border"
  >
    <menu-item
      :option="unreadOption"
      variant="icon"
      @click="$emit('mark-as-unread')"
    />
    <menu-item-with-submenu :option="priorityConfig">
      <menu-item
        v-for="(option, i) in priorityConfig.options"
        :key="i"
        :option="option"
      />
    </menu-item-with-submenu>
    <template v-for="option in statusMenuConfig">
      <menu-item
        v-if="show(option.key)"
        :key="option.key"
        :option="option"
        variant="icon"
      />
    </template>
    <menu-item
      v-if="show(snoozeOption.key)"
      :option="snoozeOption"
      variant="icon"
    />

    <menu-item-with-submenu :option="priorityConfig">
      <menu-item
        v-for="(option, i) in priorityConfig.options"
        :key="i"
        :option="option"
      />
    </menu-item-with-submenu>
  </div>
</template>

<script>
import MenuItem from './MenuItem.vue';
import MenuItemWithSubmenu from './menuItemWithSubmenu.vue';
import wootConstants from 'dashboard/constants/globals';
import agentMixin from 'dashboard/mixins/agentMixin';
import { mapGetters } from 'vuex';
export default {
  components: {
    MenuItem,
    MenuItemWithSubmenu,
  },
  mixins: [agentMixin],
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
    };
  },
  computed: {
    ...mapGetters({}),
  },
  methods: {
    show(key) {
      // If the conversation status is same as the action, then don't display the option
      // i.e.: Don't show an option to resolve if the conversation is already resolved.
      return this.status !== key;
    },
  },
};
</script>
