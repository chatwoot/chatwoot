<template>
  <woot-chat-list-filter
    :title="$t('CHAT_LIST.CHAT_ASSIGNEE_TYPE_FILTER_ITEMS')[activeType]['TEXT']"
    :dropdown-title="$t('CHAT_LIST.CHAT_ASSIGNEE_TYPE_FILTER')"
    :items="items"
    :selected-value="activeType"
    :active-type-count="activeTypeCount"
    @changeFilter="onTabChange"
  />
</template>

<script>
import wootConstants from 'dashboard/constants';
import WootChatListFilter from './FilterItems';
export default {
  components: {
    WootChatListFilter,
  },
  props: {
    items: {
      type: Array,
      default: () => [],
    },
  },
  data: () => ({
    activeType: wootConstants.ASSIGNEE_TYPE.ME,
  }),
  computed: {
    activeTypeCount() {
      return this.items
        ?.find(item => item.key === this.activeType)
        .count.toLocaleString();
    },
  },
  methods: {
    onTabChange(value) {
      if (value) {
        this.activeType = value;
      }
      this.$store.dispatch('setChatFilter', this.activeType);
      this.$emit('filterChange', this.activeType);
    },
  },
};
</script>
<style lang="scss" scoped>
::v-deep {
  .dropdown-pane {
    width: 14rem;
  }
}
</style>
