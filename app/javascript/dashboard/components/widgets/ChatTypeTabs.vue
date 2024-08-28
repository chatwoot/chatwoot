<script setup>
import { ref, computed } from 'vue';
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

const chatTypeTabsRef = ref(null);

const activeTabIndex = computed(() => {
  return props.items.findIndex(item => item.key === props.activeTab);
});

const onTabChange = selectedTabIndex => {
  if (props.items[selectedTabIndex].key !== props.activeTab) {
    emit('chatTabChange', props.items[selectedTabIndex].key);
  }
};

const keyboardEvents = {
  'Alt+KeyN': {
    action: () => {
      if (props.activeTab === wootConstants.ASSIGNEE_TYPE.ALL) {
        onTabChange(0);
      } else {
        onTabChange(activeTabIndex.value + 1);
      }
    },
  },
};
useKeyboardEvents(keyboardEvents, chatTypeTabsRef);
</script>

<template>
  <div ref="chatTypeTabsRef">
    <woot-tabs
      :index="activeTabIndex"
      class="tab--chat-type py-0 px-4 w-full"
      @change="onTabChange"
    >
      <woot-tabs-item
        v-for="item in items"
        :key="item.key"
        :name="item.name"
        :count="item.count"
      />
    </woot-tabs>
  </div>
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
