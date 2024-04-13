<template>
  <div class="relative flex">
    <div class="items-center flex justify-between">
      <filter-item
        type="status"
        :selected-value="chatStatus"
        :items="chatStatusItems"
        path-prefix="CHAT_LIST.CHAT_STATUS_FILTER_ITEMS"
        @onChangeFilter="onChangeFilter"
      />
    </div>
  </div>
</template>

<script>
import wootConstants from 'dashboard/constants/globals';
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import FilterItem from './FilterItem.vue';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

export default {
  components: {
    FilterItem,
  },
  mixins: [clickaway, uiSettingsMixin],
  data() {
    return {
      showActionsDropdown: false,
      chatStatusItems: this.$t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS'),
    };
  },
  computed: {
    ...mapGetters({
      chatStatusFilter: 'getChatStatusFilter',
    }),
    chatStatus() {
      const { conversations_filter_by: filterBy = {} } = this.uiSettings;
      const { status } = filterBy;
      return status || wootConstants.STATUS_TYPE.OPEN;
    },
  },
  methods: {
    onTabChange(value) {
      this.$emit('changeFilter', value);
      this.closeDropdown();
    },
    onChangeFilter(value, type) {
      this.$emit('changeFilter', value, type);
      this.saveSelectedFilter(type, value);
    },
    saveSelectedFilter(type, value) {
      this.updateUISettings({
        conversations_filter_by: {
          status: type === 'status' ? value : this.chatStatus,
        },
      });
    },
  },
};
</script>
<style lang="scss" scoped>
.basic-filter {
  @apply w-52 p-4 top-6;
}
</style>
