<!-- eslint-disable no-console -->
<script setup>
import { ref, reactive, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';

import googleSheetsExportAPI from '../../../../../api/googleSheetsExport';
import aiAgents from '../../../../../api/aiAgents';
import { watch } from 'vue';

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
  config: {
    type: Object,
    required: true,
  },
  googleSheetsAuth: {
    type: Object,
    required: true,
  },
});



console.log('=== googleSheetsAuth in GeneralTab.vue', props.googleSheetsAuth);
const { t } = useI18n();
// Watch for props.data and extract ticket system settings
watch(
  () => props.data,
  newData => {
    if (!newData?.display_flow_data) return;

    const flowData = newData.display_flow_data;
    const agentIndex = flowData.enabled_agents.indexOf('customer_service');

    // If customer_service agent isn't in the flow, skip
    if (agentIndex === -1) {
      // eslint-disable-next-line vue/no-mutating-props
      props.config.ticketSystemActive = false;
      // eslint-disable-next-line vue/no-mutating-props
      props.config.ticketCreateWhen = 'always';
      return;
    }

    const ticketSystem = flowData.agents_config?.[agentIndex]?.configurations?.ticket_system;

    // Map backend value to UI
    if (ticketSystem === 'always') {
      // eslint-disable-next-line vue/no-mutating-props
      props.config.ticketSystemActive = true;
      // eslint-disable-next-line vue/no-mutating-props
      props.config.ticketCreateWhen = 'always';
    } else if (ticketSystem === 'conditional') {
      // eslint-disable-next-line vue/no-mutating-props
      props.config.ticketSystemActive = true;
      // eslint-disable-next-line vue/no-mutating-props
      props.config.ticketCreateWhen = 'bot_fail';
    } else {
      // eslint-disable-next-line vue/no-mutating-props
      props.config.ticketSystemActive = false;
      // Optionally keep last value or reset
      // eslint-disable-next-line vue/no-mutating-props
      props.config.ticketCreateWhen = 'always';
    }
  },
  { immediate: true }  // ← Runs as soon as component mounts
);

const isSaving = ref(false);

// Local notification state (separate from parent's Google Sheets auth)
const notification = ref(null);

// Helper function to get agent ID by type
function getAgentIdByType(type) {
  const flowData = props.data?.display_flow_data;
  if (!flowData?.agents_config) return null;
  
  const agent = flowData.agents_config.find(config => config.type === type);
  return agent?.agent_id || null;
}

const agentId = computed(() => {
  return getAgentIdByType('customer_service');
});

// Computed properties based on parent's Google Sheets auth state
const ticketStep = computed(() => props.googleSheetsAuth.step);
const ticketLoading = computed(() => props.googleSheetsAuth.loading);
const ticketAccount = computed(() => props.googleSheetsAuth.account);
const ticketSheets = computed(() => ({
  output: props.googleSheetsAuth.spreadsheetUrls.customer_service.output || ''
}));
const ticketAuthError = computed(() => props.googleSheetsAuth.error);

watch(ticketAuthError, (newError) => {
  if (newError) {
    notification.value = { message: t('AGENT_MGMT.AUTH_ERROR'), type: 'error' };
  }
  else {
    notification.value = null;
  }
}, { immediate: true });


function retryAuthentication() {
  connectGoogle();
  ticketAuthError.value = null;
}

function showNotification(message, type = 'success') {
  notification.value = { message, type }
  setTimeout(() => {
    notification.value = null
  }, 3000)
}

async function connectGoogle() {
  try {
    // Use parent's loading state
    props.googleSheetsAuth.loading = true;
    const response = await googleSheetsExportAPI.getAuthorizationUrl();
    if (response.data.authorization_url) {
      showNotification('Opening Google authentication in a new tab...', 'info');
      window.location.href = response.data.authorization_url;
      // window.open(response.data.authorization_url, '_blank', 'noopener,noreferrer')
    } else {
      showNotification(
        'Failed to get authorization URL. Please check backend logs.',
        'error'
      );
    }
  } catch (error) {
    console.error('Google auth error:', error)
  } finally {
    props.googleSheetsAuth.loading = false;
  }
}

function disconnectGoogle() {
  // TODO: Implement disconnect logic
  console.log('Disconnect Google account clicked');
  googleSheetsExportAPI.disconnectAccount()
    .then(() => {
      // Clear parent's auth state
      props.googleSheetsAuth.account = null;
      props.googleSheetsAuth.step = 'auth';
      props.googleSheetsAuth.spreadsheetUrls.customer_service.output = '';
      props.googleSheetsAuth.error = null;
      showNotification('Google account disconnected successfully.', 'success');
    })
    .catch(error => {
      console.error('Failed to disconnect Google account:', error);
      showNotification(
        'Failed to disconnect Google account. Please try again.',
        'error'
      );
    });
}

async function createTicketSheet() {
  try {
    props.googleSheetsAuth.loading = true;
    console.log(JSON.stringify(props.data));
    
    const flowData = props.data.display_flow_data;
    const payload = {
      account_id: parseInt(flowData.account_id, 10),
      agent_id: agentId.value,
      type: 'tickets',
    };
    
    const response = await googleSheetsExportAPI.createSpreadsheet(payload);
    
    // Update parent's auth state
    props.googleSheetsAuth.spreadsheetUrls.customer_service.output = response.data.spreadsheet_url;
    props.googleSheetsAuth.step = 'sheetConfig';
    
    showNotification('Ticket output sheet created successfully!', 'success')
  } catch (error) {
    console.error('Failed to create ticket sheet:', error)
    showNotification(
      'Failed to create ticket sheet. Please try again.',
      'error'
    );
  } finally {
    props.googleSheetsAuth.loading = false;
  }
}

async function save() {
  if (isSaving.value) return; // Prevent multiple calls
  let ticketSystem = 'off';
  if (props.config.ticketSystemActive) {
    if (props.config.ticketCreateWhen === 'always') {
      ticketSystem = 'always';
    } else if (props.config.ticketCreateWhen === 'bot_fail') {
      ticketSystem = 'conditional';
    }
  }
  try {
    isSaving.value = true;
    // Hardcoded payload, exactly as you had it
    let flowData = props.data.display_flow_data;
    // console.log(flowData)
    const agent_index = flowData.enabled_agents.indexOf('customer_service');
    flowData.agents_config[agent_index].configurations.ticket_system =
      ticketSystem;
    // console.log(flowData);
    // console.log(props.config);
    const payload = {
      flow_data: flowData,
    };
    // ✅ Properly await the API call
    await aiAgents.updateAgent(props.data.id, payload);

    // ✅ Show success console.log after success
    useAlert(t('AGENT_MGMT.CSBOT.TICKET.SAVE_SUCCESS'));
  } catch (e) {
    console.error('Save error:', e);
    useAlert(t('AGENT_MGMT.CSBOT.TICKET.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
}

console.log("ticketAuthError inside GeneralTab.vue:", ticketAuthError)
console.log("is ticketAuthError value inside GeneralTab.vue:", !ticketAuthError)
console.log("is ticketAuthError value inside GeneralTab.vue:", ticketAuthError.value)
console.log("is ticketAuthError value inside GeneralTab.vue:", !ticketAuthError.value)
</script>

<template>
  <div class="w-full">
    <!-- Notification -->
    <div v-if="notification"
      :class="['fixed top-4 right-4 z-50 px-6 py-4 rounded-lg shadow-lg transition-all duration-300',
        notification.type === 'success' ? 'bg-green-500 text-white' :
        notification.type === 'error' ? 'bg-red-500 text-white' :
        notification.type === 'info' ? 'bg-blue-500 text-white' :
        'bg-gray-500 text-white']">
      <div class="flex items-center space-x-2">
        <span>{{ notification.message }}</span>
      </div>
    </div>
    
    <div class="flex flex-row gap-4">
    <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-6">
      <div class="space-y-4">
        <!-- Google Sheets Integration -->
        <div class="w-full min-w-0">
          <div class="space-y-6">
            <!-- Google Sheets Auth Flow -->
            <div v-if="ticketStep === 'auth'" class="gap-6">
              <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.EOBOT.CATALOG.SHEETS_TITLE') }}</label>
              <p class="text-gray-600 dark:text-gray-400">{{ $t('AGENT_MGMT.EOBOT.CATALOG.SHEETS_AUTH_DESC') }}</p>
              <button
                @click="connectGoogle"
                class="inline-flex items-center space-x-3 bg-green-600 hover:bg-green-700 dark:bg-green-400 dark:hover:bg-green-500 text-white px-6 py-3 rounded-lg font-medium transition-colors"
                :disabled="ticketLoading"
              >
                <span>{{ $t('AGENT_MGMT.BOOKING_BOT.AUTH_BTN') }}</span>
              </button>
            </div>
            <div v-else-if="ticketStep === 'connected'" class="py-8">
              <div class="text-center mb-8">
                <div class="w-16 h-16 bg-green-100 dark:bg-green-800 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg class="w-8 h-8 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
                  </svg>
                </div>
                <h3 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-2">{{ $t('AGENT_MGMT.BOOKING_BOT.CONNECTED_HEADER') }}</h3>
                <p class="text-gray-600 dark:text-gray-400">{{ $t('AGENT_MGMT.BOOKING_BOT.CONNECTED_DESC') }}</p>
                <p class="mt-2 text-sm text-gray-500">{{ catalogAccount?.email }}</p>
                <div class="flex gap-2 center justify-center mt-4">
                  <template v-if="true">
                    <button
                      class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
                      @click="createTicketSheet"
                      :disabled="ticketLoading"
                    >
                      <span v-if="ticketLoading">{{ $t('AGENT_MGMT.BOOKING_BOT.CREATE_SHEETS_LOADING') }}</span>
                      <span v-else>{{ $t('AGENT_MGMT.BOOKING_BOT.CREATE_SHEETS_BTN') }}</span>
                    </button>
                  </template>
                  <template v-else>
                    <div class="text-red-600 text-sm flex items-center gap-2 content-center">
                      <button
                        class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
                        @click="retryAuthentication"
                        :disabled="ticketLoading"
                      >
                        <span v-if="ticketLoading">{{ $t('AGENT_MGMT.BOOKING_BOT.RETRY_AUTH_LOADING') }}</span>
                        <span v-else>{{ $t('AGENT_MGMT.BOOKING_BOT.RETRY_AUTH_BTN') }}</span>
                      </button>
                    </div>
                  </template>
                </div>
              </div>
            </div>
            <div v-else-if="ticketStep === 'sheetConfig'">
              <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-6 mb-6 border border-blue-200 dark:border-blue-800">
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <div class="flex items-center mb-3">
                      <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                        <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                        </svg>
                      </div>
                      <div>
                        <h3 class="font-medium text-slate-900 dark:text-slate-25">
                          {{ $t('AGENT_MGMT.EOBOT.CATALOG.INPUT_SHEET_TITLE') }}
                        </h3>
                        <p class="text-sm text-slate-600 dark:text-slate-400">
                          {{ $t('AGENT_MGMT.EOBOT.CATALOG.INPUT_SHEET_DESC') }}
                        </p>
                      </div>
                    </div>
                  </div>
                  <div v-if="ticketSheets.input && !salesAuthError" class="flex flex-col gap-2">
                    <a 
                      :href="ticketSheets.input" 
                      target="_blank" 
                      class="inline-flex items-center px-4 py-2 text-sm font-medium text-blue-600 dark:text-blue-400 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 border border-blue-200 dark:border-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors shadow-sm"
                    >
                      <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>
                      </svg>
                      {{ $t('AGENT_MGMT.BOOKING_BOT.OPEN_SHEET_BTN') }}
                    </a>
                  </div>
                </div>

                <div class="border-t border-blue-200 dark:border-blue-700 pt-6">
                  <div class="flex justify-start">
                    <div v-if="ticketSheets.input && !salesAuthError">
                      <button
                        @click="syncProductColumns"
                        :disabled="syncingColumns"
                        class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center gap-2"
                      >
                        <svg v-if="syncingColumns" class="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" class="opacity-25"/>
                          <path fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" class="opacity-75"/>
                        </svg>
                        <svg v-else class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                        </svg>
                        {{ syncingColumns ? $t('AGENT_MGMT.EOBOT.CATALOG.SYNC_BUTTON_LOADING') : $t('AGENT_MGMT.EOBOT.CATALOG.SYNC_BUTTON') }}
                      </button>
                    </div>
                    <div v-else class="text-red-600 text-sm flex items-center gap-2">
                      <button
                        @click="retryAuthentication"
                        class="inline-flex items-center space-x-2 border-2 border-green-700 hover:border-green-700 dark:border-green-700 text-green-600 hover:text-green-700 dark:text-grey-400 dark:hover:text-grey-500 pr-4 py-2 rounded-md font-medium transition-colors bg-transparent hover:bg-grey-50 dark:hover:bg-grey-900/20"
                        :disabled="loading"
                      >
                        <span v-if="loading">{{ $t('AGENT_MGMT.BOOKING_BOT.RETRY_AUTH_LOADING') }}</span>
                        <span>{{ t('AGENT_MGMT.BOOKING_BOT.RETRY_AUTH_BTN') }}</span>
                      </button>
                    </div>
                    <div class="gap-2 items-center">
                      <button
                        @click="disconnectGoogle"
                        class="inline-flex items-center space-x-2 border-2 border-red-600 hover:border-red-700 dark:border-red-400 dark:hover:border-red-500 text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-500 px-4 py-2 rounded-md font-medium transition-colors bg-transparent hover:bg-red-50 dark:hover:bg-red-900/20 ml-3"
                        :disabled="loading"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-ban-icon lucide-ban"><path d="M4.929 4.929 19.07 19.071"/><circle cx="12" cy="12" r="10"/></svg>
                        <span>{{ $t('AGENT_MGMT.BOOKING_BOT.DISC_BTN') }}</span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Output Sheet Section - Order Tracking -->
              <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-6 mb-6 border border-blue-200 dark:border-blue-800">
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                      <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                      </svg>
                    </div>
                    <div>
                      <h4 class="font-medium text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.EOBOT.CATALOG.OUTPUT_SHEET_TITLE') }}</h4>
                      <p class="text-sm text-slate-600 dark:text-slate-400">{{ $t('AGENT_MGMT.EOBOT.CATALOG.OUTPUT_SHEET_DESC') }}</p>
                    </div>
                  </div>
                  <a 
                    v-if="ticketSheets.output && !salesAuthError"
                    :href="ticketSheets.output" 
                    target="_blank" 
                    class="inline-flex items-center px-4 py-2 text-sm font-medium text-blue-600 dark:text-blue-400 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 border border-blue-200 dark:border-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors shadow-sm"
                  >
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>
                    </svg>
                    {{ $t('AGENT_MGMT.BOOKING_BOT.OPEN_SHEET_BTN') }}
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="w-[240px] flex flex-col gap-3">
      <div class="sticky top-4 bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-4 shadow-sm">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
            <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
            </svg>
          </div>
          <div>
            <h3 class="font-semibold text-slate-700 dark:text-slate-300">{{ $t('AGENT_MGMT.CSBOT.TICKET.GENERAL_SETTINGS') }}</h3>
            <p class="text-sm text-slate-500 dark:text-slate-400">{{ $t('AGENT_MGMT.CSBOT.TICKET.SYSTEM_SETTINGS') }}</p>
          </div>
        </div>
        
        <Button
          class="w-full"
          :is-loading="isSaving"
          :disabled="isSaving"
          @click="() => save()"
        >
          <span class="flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
            </svg>
            {{ $t('AGENT_MGMT.CSBOT.TICKET.SAVE_BUTTON') }}
          </span>
        </Button>

      </div>
      </div>
    </div>
  </div>
</template>
