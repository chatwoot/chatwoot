<script setup>
import { computed } from 'vue';
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';

defineProps({
  currentChat: {
    required: true,
    type: Object,
  },
});

const { uiSettings } = useUISettings();

const activeTab = computed(() => {
  const { is_contact_sidebar_open: isContactSidebarOpen } = uiSettings.value;

  if (isContactSidebarOpen) {
    return 0;
  }
  return null;
});
</script>

<template>
  <div
    class="ltr:border-l rtl:border-r border-n-weak h-full overflow-hidden z-10 w-[320px] min-w-[320px] 2xl:min-w-[360px] 2xl:w-[360px] flex flex-col bg-n-background"
  >
    <div class="flex flex-1 overflow-auto">
      <ContactPanel
        v-show="activeTab === 0"
        :conversation-id="currentChat.id"
        :inbox-id="currentChat.inbox_id"
      />
    </div>
  </div>
</template>
