<template>
  <div
    class="flex flex-col gap-1 bg-white z-50 dark:bg-slate-900 w-40 py-1 border shadow-md border-slate-100 dark:border-slate-500 rounded-xl divide-y divide-slate-100 dark:divide-slate-700/50"
  >
    <div class="flex flex-col">
      <menu-item
        v-for="item in menuItems"
        :key="item.key"
        :label="item.label"
        @click="onMenuItemClick(item.key)"
      />
    </div>
    <div class="flex flex-col">
      <menu-item
        v-for="item in commonMenuItems"
        :key="item.key"
        :label="item.label"
        @click="onMenuItemClick(item.key)"
      />
    </div>
  </div>
</template>

<script>
import MenuItem from './MenuItem.vue';
export default {
  components: {
    MenuItem,
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
      commonMenuItems: [
        {
          key: 'mark_all_read',
          label: this.$t('INBOX.MENU_ITEM.MARK_ALL_READ'),
        },
        {
          key: 'delete_all',
          label: this.$t('INBOX.MENU_ITEM.DELETE_ALL'),
        },
        {
          key: 'delete_all_read',
          label: this.$t('INBOX.MENU_ITEM.DELETE_ALL_READ'),
        },
      ],
    };
  },
  methods: {
    onMenuItemClick(key) {
      this.$emit('option-click', key);
    },
  },
};
</script>
