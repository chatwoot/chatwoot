<template>
  <select v-model="activeSortBy" class="status--filter" @change="onTabChange()">
    <option value="sort" disabled>
      {{ $t('CHAT_LIST.CHAT_SORT_BY_FILTER') }}
    </option>
    <option
      v-for="(value, status) in $t('CHAT_LIST.CHAT_SORT_BY_FILTER_ITEMS')"
      :key="status"
      :value="status"
    >
      {{ value['TEXT'] }}
    </option>
  </select>
</template>

<script>
import wootConstants from 'dashboard/constants';
export default {
  data: () => ({
    activeSortBy: wootConstants.SORT_BY_TYPE.LATEST,
  }),
  methods: {
    onTabChange() {
      this.$store.dispatch('setChatSortByFilter', this.activeSortBy);
      this.$emit('changeSortByFilter', this.activeSortBy);
    },
  },
};
</script>
