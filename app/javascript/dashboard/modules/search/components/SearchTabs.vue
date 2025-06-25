<script setup>
import { ref, watch } from 'vue';

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

const onTabChange = index => {
  activeTab.value = index;
  emit('tabChange', props.tabs[index].key);
};
</script>

<template>
  <div class="mt-1 border-b border-n-weak">
    <woot-tabs :index="activeTab" :border="false" @change="onTabChange">
      <woot-tabs-item
        v-for="(item, index) in tabs"
        :key="item.key"
        :index="index"
        :name="item.name"
        :count="item.count"
        :show-badge="item.showBadge"
      />
    </woot-tabs>
  </div>
</template>
