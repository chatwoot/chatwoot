<script>
import wootConstants from 'dashboard/constants/globals';
import { mapGetters } from 'vuex';
import FilterItem from './FilterItem.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import NextButton from 'dashboard/components-next/button/Button.vue';

const CHAT_STATUS_FILTER_ITEMS = Object.freeze([
  'open',
  'resolved',
  'pending',
  'snoozed',
  'all',
]);

const SORT_ORDER_ITEMS = Object.freeze([
  'last_activity_at_asc',
  'last_activity_at_desc',
  'created_at_desc',
  'created_at_asc',
  'priority_desc',
  'priority_asc',
  'waiting_since_asc',
  'waiting_since_desc',
]);

export default {
  components: {
    FilterItem,
    NextButton,
  },
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['changeFilter'],
  setup() {
    const { updateUISettings } = useUISettings();

    return {
      updateUISettings,
    };
  },
  data() {
    return {
      showActionsDropdown: false,
      chatStatusItems: CHAT_STATUS_FILTER_ITEMS,
      chatSortItems: SORT_ORDER_ITEMS,
    };
  },
  computed: {
    ...mapGetters({
      chatStatusFilter: 'getChatStatusFilter',
      chatSortFilter: 'getChatSortFilter',
    }),
    chatStatus() {
      return this.chatStatusFilter || wootConstants.STATUS_TYPE.OPEN;
    },
    sortFilter() {
      return (
        this.chatSortFilter || wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC
      );
    },
  },
  methods: {
    onTabChange(value) {
      this.$emit('changeFilter', value);
      this.closeDropdown();
    },
    toggleDropdown() {
      this.showActionsDropdown = !this.showActionsDropdown;
    },
    closeDropdown() {
      this.showActionsDropdown = false;
    },
    onChangeFilter(value, type) {
      this.$emit('changeFilter', value, type);
      this.saveSelectedFilter(type, value);
    },
    saveSelectedFilter(type, value) {
      this.updateUISettings({
        conversations_filter_by: {
          status: type === 'status' ? value : this.chatStatus,
          order_by: type === 'sort' ? value : this.sortFilter,
        },
      });
    },
  },
};
</script>

<template>
  <div class="relative flex">
    <NextButton
      v-tooltip.right="$t('CHAT_LIST.SORT_TOOLTIP_LABEL')"
      icon="i-lucide-arrow-up-down"
      slate
      faded
      xs
      @click="toggleDropdown"
    />
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="mt-1 dropdown-pane dropdown-pane--open !w-52 !p-4 top-6 border !border-n-weak dark:!border-n-weak !bg-n-alpha-3 dark:!bg-n-alpha-3 backdrop-blur-[100px]"
      :class="{
        'ltr:left-0 rtl:right-0': !isOnExpandedLayout,
        'ltr:right-0 rtl:left-0': isOnExpandedLayout,
      }"
    >
      <div class="flex items-center justify-between last:mt-4">
        <span class="text-xs font-medium text-n-slate-12">{{
          $t('CHAT_LIST.CHAT_SORT.STATUS')
        }}</span>
        <FilterItem
          type="status"
          :selected-value="chatStatus"
          :items="chatStatusItems"
          path-prefix="CHAT_LIST.CHAT_STATUS_FILTER_ITEMS"
          @on-change-filter="onChangeFilter"
        />
      </div>
      <div class="flex items-center justify-between last:mt-4">
        <span class="text-xs font-medium text-n-slate-12">{{
          $t('CHAT_LIST.CHAT_SORT.ORDER_BY')
        }}</span>
        <FilterItem
          type="sort"
          :selected-value="sortFilter"
          :items="chatSortItems"
          path-prefix="CHAT_LIST.SORT_ORDER_ITEMS"
          @on-change-filter="onChangeFilter"
        />
      </div>
    </div>
  </div>
</template>
