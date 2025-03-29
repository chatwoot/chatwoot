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
    class="z-50 flex flex-col max-w-64 min-w-40 gap-1 bg-n-alpha-3 backdrop-blur-[100px] divide-y py-2 px-2 outline outline-1 outline-n-container shadow-lg rounded-xl divide-n-weak dark:divide-n-strong"
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
