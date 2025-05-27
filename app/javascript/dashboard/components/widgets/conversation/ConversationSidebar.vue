<script setup>
import { computed, ref } from 'vue';
import CopilotContainer from '../../copilot/CopilotContainer.vue';
import ShopeeContainer from './ShopeeContainer.vue';
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel.vue';

defineProps({
  currentChat: {
    required: true,
    type: Object,
  },
});

const emit = defineEmits(['toggleContactPanel']);
const { t } = useI18n();
const channelType = computed(() => {
  return props.currentChat?.channel || props.currentChat?.meta?.channel || '';
});
const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);
const copilotEnabled = computed(() => {
  return isFeatureEnabledonAccount.value(
    currentAccountId.value,
    FEATURE_FLAGS.CAPTAIN
  );
});
const shopeeEnabled = computed(() => {
  return channelType.value === 'Channel::Shopee';
});
const tabs = computed(() => {
  let availableTabs = [
    { value: 'contact', label: t('CONVERSATION.SIDEBAR.CONTACT') },
  ];
  if (copilotEnabled.value) {
    availableTabs.push({
      value: 'copilot',
      label: t('CONVERSATION.SIDEBAR.COPILOT'),
    });
  }
  if (shopeeEnabled.value) {
    availableTabs.push({
      value: 'shopee',
      label: t('CONVERSATION.SIDEBAR.SHOPEE'),
    });
  }
  return availableTabs;
});
const activeTabValue = ref('contact');
const activeTabIndex = computed(() => {
  const activeIndex = tabs.value.findIndex(
    tab => tab.value === activeTabValue.value
  );
  return activeIndex === -1 ? 0 : activeIndex;
});
const activeContent = value => {
  return tabs.value[activeTabIndex.value].value === value;
};
const toggleContactPanel = () => {
  emit('toggleContactPanel');
};
const handleTabChange = selectedTab => {
  activeTabValue.value = selectedTab.value;
};
</script>

<template>
  <div
    class="h-full overflow-hidden z-10 w-80 min-w-80 2xl:min-w-96 2xl:w-96 flex flex-col bg-n-background ltr:border-l rtl:border-r border-slate-100 dark:border-slate-900"
  >
    <div v-if="tabs.length > 1" class="flex-none p-2">
      <TabBar
        :tabs="tabs"
        :initial-active-tab="activeTabIndex"
        class="w-full [&>button]:w-full"
        @tab-changed="handleTabChange"
      />
    </div>
    <div class="flex-auto w-full overflow-hidden">
      <ContactPanel
        v-if="activeContent('contact')"
        :conversation-id="currentChat.id"
        :inbox-id="currentChat.inbox_id"
        :on-toggle="toggleContactPanel"
      />
      <CopilotContainer
        v-else-if="activeContent('copilot') && copilotEnabled"
        :key="currentChat.id"
        :conversation-inbox-type="channelType"
        :conversation-id="currentChat.id"
        class="flex-1"
      />
      <ShopeeContainer
        v-else-if="activeContent('shopee') && shopeeEnabled"
        :current-chat="currentChat"
        class="flex-1"
      />
    </div>
  </div>
</template>
