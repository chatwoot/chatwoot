<template>
  <woot-chat-list-filter
    title="View"
    :items="sortByItems"
    icon="menu-icon"
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
  data() {
    return {
      activeSortBy: wootConstants.SORT_BY_TYPE.LATEST,
      sortByItems: [
        {
          key: wootConstants.SORT_BY_TYPE.LATEST,
          name: this.$t('CHAT_LIST.CHAT_SORT_BY_FILTER.ITEMS.LATEST.NAME'),
          label: this.$t('CHAT_LIST.CHAT_SORT_BY_FILTER.ITEMS.LATEST.LABEL'),
        },
        {
          key: wootConstants.SORT_BY_TYPE.CREATED_AT,
          name: this.$t('CHAT_LIST.CHAT_SORT_BY_FILTER.ITEMS.CREATED_AT.NAME'),
          label: this.$t(
            'CHAT_LIST.CHAT_SORT_BY_FILTER.ITEMS.CREATED_AT.LABEL'
          ),
        },
        {
          key: wootConstants.SORT_BY_TYPE.LAST_USER_MESSAGE_AT,
          name: this.$t(
            'CHAT_LIST.CHAT_SORT_BY_FILTER.ITEMS.LAST_USER_MESSAGE_AT.NAME'
          ),
          label: this.$t(
            'CHAT_LIST.CHAT_SORT_BY_FILTER.ITEMS.LAST_USER_MESSAGE_AT.LABEL'
          ),
        },
      ],
    };
  },

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
