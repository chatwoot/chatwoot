<script setup>
import { computed, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  tabs: {
    type: Array,
    default: () => [],
  },
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
    count: tab.showBadge ? tab.count : null,
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
    />

    <Button
      :label="t('SEARCH.SORT_BY.RELEVANCE')"
      sm
      link
      slate
      class="hover:!no-underline pointer-events-none lg:inline-flex hidden"
      icon="i-lucide-arrow-up-down"
    />
  </div>
</template>
