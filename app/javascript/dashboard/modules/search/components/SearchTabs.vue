<script setup>
import { computed, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';

const props = defineProps({
  tabs: {
    type: Array,
    default: () => [],
  },
  isFetchingCounts: { type: Boolean, default: false },
  selectedTab: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['tabChange']);

const { t } = useI18n();

const activeTab = ref(props.selectedTab);

watch(
  () => props.selectedTab,
  (value, oldValue) => {
    if (value !== oldValue) {
      activeTab.value = props.selectedTab;
    }
  }
);

const tabBarTabs = computed(() => {
  return props.tabs.map(tab => ({
    label: tab.name,
    count: tab.count,
    showBadge: tab.showBadge,
  }));
});

const onTabChange = selectedTab => {
  const index = props.tabs.findIndex(tab => tab.name === selectedTab.label);
  activeTab.value = index;
  emit('tabChange', props.tabs[index].key);
};
</script>

<template>
  <div class="flex items-center justify-between mt-7 mb-4">
    <TabBar
      :tabs="tabBarTabs"
      :initial-active-tab="activeTab"
      @tab-changed="onTabChange"
    >
      <template #count="{ tab }">
        <span v-if="tab.showBadge && tab.count !== null">
          {{ t('SEARCH.COUNT_BADGE', { count: tab.count }) }}
        </span>
        <span
          v-else-if="tab.showBadge && isFetchingCounts"
          :aria-label="t('SEARCH.COUNTS_LOADING')"
        >
          {{ t('SEARCH.COUNT_PENDING') }}
        </span>
        <span
          v-else-if="tab.showBadge"
          :aria-label="t('SEARCH.COUNTS_UNAVAILABLE')"
        >
          {{ t('SEARCH.COUNT_UNKNOWN') }}
        </span>
      </template>
    </TabBar>
  </div>
</template>
