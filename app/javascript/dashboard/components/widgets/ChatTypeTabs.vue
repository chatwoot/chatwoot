<script setup>
import { computed } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import wootConstants from 'dashboard/constants/globals';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
  activeTab: {
    type: String,
    default: wootConstants.ASSIGNEE_TYPE.ME,
  },
});

const emit = defineEmits(['chatTabChange']);

const activeTabIndex = computed(() => {
  return props.items.findIndex(item => item.key === props.activeTab);
});

const onTabChange = selectedTabIndex => {
  if (selectedTabIndex >= 0 && selectedTabIndex < props.items.length) {
    const selectedItem = props.items[selectedTabIndex];
    if (selectedItem.key !== props.activeTab) {
      emit('chatTabChange', selectedItem.key);
    }
  }
};

const keyboardEvents = {
  'Alt+KeyN': {
    action: () => {
      if (props.activeTab === wootConstants.ASSIGNEE_TYPE.ALL) {
        onTabChange(0);
      } else {
        const nextIndex = (activeTabIndex.value + 1) % props.items.length;
        onTabChange(nextIndex);
      }
    },
  },
};

useKeyboardEvents(keyboardEvents);
</script>

<template>
  <woot-tabs
    :index="activeTabIndex"
    class="w-full px-3 -mt-1 py-0 tab--chat-type"
    @change="onTabChange"
  >
    <woot-tabs-item
      v-for="(item, index) in items"
      :key="item.key"
      class="text-sm"
      :index="index"
      :name="item.name"
      :count="item.count"
    />
  </woot-tabs>
</template>

<style scoped lang="scss">
.tab--chat-type {
  ::v-deep {
    .tabs {
      @apply p-0;
    }
  }
}
</style>
