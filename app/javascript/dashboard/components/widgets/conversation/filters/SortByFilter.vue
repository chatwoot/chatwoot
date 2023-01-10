<template>
  <woot-chat-list-filter
    :title="activeSortByLabel"
    :dropdown-title="$t('CHAT_LIST.CHAT_SORT_BY_FILTER')"
    :items="sortByItems"
    :selected-value="activeSortBy"
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

  data: () => ({
    activeSortBy: wootConstants.SORT_BY_TYPE.LATEST,
    sortByItems: [
      {
        key: wootConstants.SORT_BY_TYPE.LATEST,
        name: 'Last activity at',
        label: 'Sorted by last activity',
      },
      {
        key: wootConstants.SORT_BY_TYPE.CREATED_AT,
        name: 'Created at',
        label: 'Sorted by created at',
      },
      {
        key: wootConstants.SORT_BY_TYPE.LAST_USER_MESSAGE_AT,
        name: 'Last user message at',
        label: 'Sorted by last message',
      },
    ],
  }),

  computed: {
    activeSortByLabel() {
      return this.sortByItems.find(item => item.key === this.activeSortBy)
        .label;
    },
  },

  methods: {
    onTabChange(value) {
      if (value) {
        this.activeSortBy = value;
      }
      this.$store.dispatch('setChatSortByFilter', this.activeSortBy);
      this.$emit('changeSortByFilter', this.activeSortBy);
    },
  },
};
</script>
