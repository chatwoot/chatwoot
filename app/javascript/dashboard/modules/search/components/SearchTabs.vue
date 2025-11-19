<script setup>
import { computed, watch, ref } from 'vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';

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
  <div class="mt-7 mb-4">
    <TabBar
      :tabs="tabBarTabs"
      :initial-active-tab="activeTab"
      @tab-changed="onTabChange"
    />
  </div>
</template>
