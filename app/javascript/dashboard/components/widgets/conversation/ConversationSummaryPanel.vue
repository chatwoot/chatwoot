<script setup>
  import { ref, computed } from 'vue';
  import { useI18n } from 'vue-i18n';
  import { useUISettings } from 'dashboard/composables/useUISettings';
  import ConversationSummary from './ConversationSummary.vue';
  import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';
  
  const props = defineProps({
    conversationId: {
      type: [Number, String],
      required: true,
    },
  });
  
  const { t } = useI18n();
  
  const { updateUISettings } = useUISettings();
  const conversationSummaryRef = ref(null);
  
  // Computed property to handle header buttons
  const headerButtons = computed(() => [
    {
      key: 'refresh',
      icon: 'i-lucide-refresh-cw',
      label: t('CONVERSATION.SUMMARY.REFRESH_LABEL'),
      tooltip: t('CONVERSATION.SUMMARY.REFRESH_TOOLTIP'),
      disabled: false,
    },
  ]);
  
  // Handle actions for header buttons
  const handleHeaderAction = key => {
    if (key === 'refresh') {
      conversationSummaryRef.value?.fetchSummary(true);
    }
  };
  
  // Function to close the panel
  const closePanel = () => {
    updateUISettings({
      is_conversation_summary_open: false,
    });
  };
  </script>
  
  <template>
    <div class="flex flex-col h-full w-full bg-n-background">
      <!-- Header section with disclaimer -->
      <SidebarActionsHeader
        :title="$t('CONVERSATION.SIDEBAR.SUMMARY')"
        :buttons="headerButtons"
        close-icon="i-lucide-panel-left-close"
        @click="handleHeaderAction"
        @close="closePanel"
      >
        <div class="px-4 pb-2">
          <p class="text-xs text-n-slate-11 italic">
            {{ $t('CONVERSATION.SUMMARY.DISCLAIMER') }}
          </p>
        </div>
      </SidebarActionsHeader>
      
      <div class="flex-1 overflow-y-auto">
        <ConversationSummary
          ref="conversationSummaryRef"
          :conversation-id="conversationId"
        />
      </div>
    </div>
  </template>
  
  