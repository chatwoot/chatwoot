<template>
  <woot-context-menu
    :x="contextMenuPosition.x"
    :y="contextMenuPosition.y"
    @close="handleClose"
  >
    <div
      class="bg-white dark:bg-slate-900 w-40 py-1 border shadow-md border-slate-100 dark:border-slate-500 rounded-xl"
    >
      <menu-item
        v-for="item in menuItems"
        :key="item.key"
        :label="item.label"
        @click="onMenuItemClick(item.key)"
      />
    </div>
  </woot-context-menu>
</template>

<script>
import MenuItem from './MenuItem.vue';
export default {
  components: {
    MenuItem,
  },
  props: {
    contextMenuPosition: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      menuItems: [
        {
          key: 'mark_as_read',
          label: this.$t('INBOX.MENU_ITEM.MARK_AS_READ'),
        },
        {
          key: 'mark_as_unread',
          label: this.$t('INBOX.MENU_ITEM.MARK_AS_UNREAD'),
        },
        {
          key: 'snooze',
          label: this.$t('INBOX.MENU_ITEM.SNOOZE'),
        },
        {
          key: 'delete',
          label: this.$t('INBOX.MENU_ITEM.DELETE'),
        },
      ],
    };
  },
  methods: {
    handleClose() {
      this.$emit('close');
    },
    onMenuItemClick(key) {
      this.$emit('click', key);
      this.handleClose();
    },
  },
};
</script>
