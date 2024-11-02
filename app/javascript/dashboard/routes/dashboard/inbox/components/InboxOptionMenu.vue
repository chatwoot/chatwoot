<script>
import MenuItem from './MenuItem.vue';
export default {
  components: {
    MenuItem,
  },
  emits: ['optionClick'],
  data() {
    return {
      menuItems: [
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
    onClick(key) {
      this.$emit('optionClick', key);
    },
  },
};
</script>

<template>
  <div
    class="z-50 flex flex-col w-40 gap-1 py-1 bg-white border divide-y shadow-md dark:bg-slate-900 border-slate-100 dark:border-slate-700/50 rounded-xl divide-slate-100 dark:divide-slate-700/50"
  >
    <div class="flex flex-col">
      <MenuItem
        v-for="item in menuItems"
        :key="item.key"
        :label="item.label"
        @click.stop="onClick(item.key)"
      />
    </div>
  </div>
</template>
