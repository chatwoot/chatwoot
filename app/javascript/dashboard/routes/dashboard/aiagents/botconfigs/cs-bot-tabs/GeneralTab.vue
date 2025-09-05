<!-- eslint-disable no-console -->
<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAlert } from 'dashboard/composables'
import Button from 'dashboard/components-next/button/Button.vue'

// Google Sheets Auth Flow for Tickets
import googleSheetsExportAPI from '../../../../../api/googleSheetsExport'
// ✅ Add this line to fix the "aiAgents is not defined" error
import aiAgents from '../../../../../api/aiAgents'
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
});

const { t } = useI18n();
// Watch for props.data and extract ticket system settings
watch(
  () => props.data,
  (newData) => {
    if (!newData?.display_flow_data) return;

    const flowData = newData.display_flow_data;
    const agentIndex = flowData.enabled_agents.indexOf('customer_service');

    // If customer_service agent isn't in the flow, skip
    if (agentIndex === -1) {
      props.config.ticketSystemActive = false;
      props.config.ticketCreateWhen = 'always';
      return;
    }

    const ticketSystem = flowData.agents_config?.[agentIndex]?.configurations?.ticket_system;

    // Map backend value to UI
    if (ticketSystem === 'always') {
      props.config.ticketSystemActive = true;
      props.config.ticketCreateWhen = 'always';
    } else if (ticketSystem === 'conditional') {
      props.config.ticketSystemActive = true;
      props.config.ticketCreateWhen = 'bot_fail';
    } else {
      props.config.ticketSystemActive = false;
      // Optionally keep last value or reset
      props.config.ticketCreateWhen = 'always';
    }
  },
  { immediate: true }  // ← Runs as soon as component mounts
);

const isSaving = ref(false);

// Google Sheets Integration State
const ticketStep = ref('auth'); // 'auth', 'connected', 'sheetConfig'
const ticketLoading = ref(false);
const ticketAccount = ref(null); // { email: '...', name: '...' }
const ticketSheets = reactive({ output: '' });
const notification = ref(null);

// Check auth status on mount
onMounted(async () => {
  await checkAuthStatus();
});

function showNotification(message, type = 'success') {
  notification.value = { message, type }
  setTimeout(() => {
    notification.value = null
  }, 3000)
}

async function connectGoogle() {
  try {
    ticketLoading.value = true
    const response = await googleSheetsExportAPI.getAuthorizationUrl()
    if (response.data.authorization_url) {
      showNotification('Opening Google authentication in a new tab...', 'info')
      window.open(response.data.authorization_url, '_blank', 'noopener,noreferrer')
    } else {
      showNotification('Failed to get authorization URL. Please check backend logs.', 'error')
    }
  } catch (error) {
    showNotification('Authentication failed. Please try again.', 'error')
    console.error('Google auth error:', error)
  } finally {
    ticketLoading.value = false
  }
}

async function checkAuthStatus() {
  alert("checking auth status...")
  try {
    ticketLoading.value = true;
    const response = await googleSheetsExportAPI.getStatus();
    // eslint-disable-next-line no-alert
    alert(JSON.stringify(response.data));
    if (response.data.authorized) {
      ticketStep.value = 'connected';
      ticketAccount.value = {
        email: response.data.email,
        name: 'Connected Account',
      };
      try {
        // console.log('props.data:', props.data);
        // console.log(
        //   'props.data.display_flow_data:',
        //   props.data.display_flow_data
        // );
        const flowData = props.data.display_flow_data;
        const payload = {
          account_id: parseInt(flowData.account_id, 10),
          agent_id: String(props.data.id),
          type: 'tickets',
        };
        alert(JSON.stringify(payload))
        console.log('payload:', payload);
        const spreadsheet_url_response =
          await googleSheetsExportAPI.getSpreadsheetUrl(payload);
        alert(JSON.stringify(payload))
        alert(JSON.stringify(spreadsheet_url_response))

        console.log(
          'spreadsheet_url_response.data:',
          spreadsheet_url_response.data
        );
        if (spreadsheet_url_response.data.spreadsheet_url) {
          ticketSheets.output = spreadsheet_url_response.data.spreadsheet_url;
          ticketStep.value = 'sheetConfig';
        } else {
          ticketSheets.output = '';
        }
      } catch (error) {
        console.error('Failed to check authorization status while retrieving spreadsheet data:', error);
        ticketStep.value = 'connected';
      }
    } else {
      ticketStep.value = 'auth';
    }
    console.log('ticketStep:', ticketStep);
    // eslint-disable-next-line no-alert
    console.log('ticketAccount:', ticketAccount);
  } catch (error) {
    console.error('Failed to check authorization status:', error)
    ticketStep.value = 'auth'
  } finally {
    ticketLoading.value = false
  }
  console.log('ticketStep.value:', ticketStep.value);
  alert("checking auth status DONE")
}

async function createTicketSheet() {
  ticketLoading.value = true
  try {
    // TODO: Call backend to create ticket output sheet
    // For now, simulate sheet creation
    // await new Promise(resolve => setTimeout(resolve, 1200))
    // eslint-disable-next-line no-alert
    alert(JSON.stringify(props.data));
    // eslint-disable-next-line no-console
    const flowData = props.data.display_flow_data;
    const payload = {
      account_id: parseInt(flowData.account_id, 10),
      agent_id: String(props.data.id),
      type: 'tickets',
    };
    // console.log(payload);
    const response = await googleSheetsExportAPI.createSpreadsheet(payload);
    // console.log(response)
    ticketSheets.output = response.data.spreadsheet_url;
    ticketStep.value = 'sheetConfig';
    showNotification('Ticket output sheet created successfully!', 'success')
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to create ticket sheet:', error)
    showNotification(
      'Failed to create ticket sheet. Please try again.',
      'error'
    );
  } finally {
    ticketLoading.value = false;
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

    // ✅ Show success alert after success
    useAlert(t('AGENT_MGMT.CSBOT.TICKET.SAVE_SUCCESS'));
  } catch (e) {
    console.error('Save error:', e);
    useAlert(t('AGENT_MGMT.CSBOT.TICKET.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
}
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

        
        <!-- Sistem Tiket Toggle -->
        <div class="mb-6">
          <label class="block font-medium mb-2">{{ $t('AGENT_MGMT.CSBOT.TICKET.SYSTEM_TITLE') }}</label>
          <p class="text-sm text-gray-500 mb-3">{{ $t('AGENT_MGMT.CSBOT.TICKET.SYSTEM_DESC') }}</p>
          <label class="inline-flex items-center cursor-pointer">
            <input type="checkbox" v-model="config.ticketSystemActive" class="sr-only peer">
            <div
              class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
            </div>
            <span class="ml-3 text-sm text-slate-700 dark:text-slate-300">
              {{ config.ticketSystemActive ? $t('AGENT_MGMT.CSBOT.TICKET.ACTIVE') : $t('AGENT_MGMT.CSBOT.TICKET.INACTIVE') }}
            </span>
          </label>
        </div>

        <!-- Kapan tiket dibuat -->
        <div v-if="config.ticketSystemActive" class="mb-6">
          <label class="block font-medium mb-2">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_WHEN') }}</label>
          <p class="text-sm text-gray-500 mb-3">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_WHEN_DESC') }}</p>
          <select 
            v-model="config.ticketCreateWhen" 
            class="w-full mb-0 p-2 text-sm  border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
          >
            <option value="always">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_ALWAYS') }}</option>
            <option value="bot_fail">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_ON_FAIL') }}</option>
          </select>
        </div>

        <!-- Google Sheets Integration -->
        <div v-if="config.ticketSystemActive" class="mb-6">
          <h4 class="text-md font-medium text-slate-900 dark:text-slate-25 mb-3">Ticket Output Integration</h4>
          <p class="text-sm text-gray-500 mb-4">Connect to Google Sheets to automatically save tickets data</p>
          
          <!-- Google Sheets Auth Flow -->
          <div v-if="ticketStep === 'auth'" class="mb-6">
            <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-6 border border-blue-200 dark:border-blue-800">
              <div class="flex items-center gap-3 mb-3">
                <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                    <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                    </svg>
                  </div>
                <div>
                  <h5 class="text-sm font-medium text-blue-900 dark:text-blue-100">Google Sheets Connection</h5>
                  <p class="text-xs text-blue-700 dark:text-blue-300">Authorize access to create ticket output sheets</p>
                </div>
              </div>
              
              <button
                @click="connectGoogle"
                class="inline-flex items-center space-x-3 bg-green-600 hover:bg-green-700 dark:bg-green-400 dark:hover:bg-green-500 text-white px-6 py-3 rounded-lg font-medium transition-colors"
                :disabled="ticketLoading"
              >
                <svg v-if="ticketLoading" class="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" class="opacity-25"/>
                  <path fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" class="opacity-75"/>
                </svg>
                <svg v-else class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                </svg>
                <span>{{ ticketLoading ? 'Connecting...' : 'Connect Google Account' }}</span>
              </button>
            </div>
          </div>

          <!-- Connected State -->
          <div v-else-if="ticketStep === 'connected'" class="mb-6">
            <div class="dark:from-green-900/20 dark:to-emerald-900/20 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-8 h-8 bg-green-100 dark:bg-green-900/50 rounded-lg flex items-center justify-center">
                    <svg class="w-4 h-4 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                    </svg>
                  </div>
                  <div>
                    <h5 class="text-sm font-medium text-green-900 dark:text-green-100">Google Account Connected</h5>
                    <p class="text-xs text-green-700 dark:text-green-300">{{ ticketAccount?.email || 'Connected successfully' }}</p>
                  </div>
                </div>
                <button
                  class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
                  @click="createTicketSheet"
                  :disabled="loading"
                >
                  <span v-if="loading">{{ $t('AGENT_MGMT.BOOKING_BOT.CREATE_SHEETS_LOADING') }}</span>
                  <span v-else>{{ $t('AGENT_MGMT.BOOKING_BOT.CREATE_SHEETS_BTN') }}</span>
                </button>
              </div>
            </div>
          </div>

          <!-- Sheet Configuration -->
          <div v-else-if="ticketStep === 'sheetConfig'" class="mb-6">
            <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-6 border border-blue-200 dark:border-blue-800">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                    <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                    </svg>
                  </div>
                  <div>
                    <h5 class="text-sm font-medium text-slate-900 dark:text-slate-100">Ticket Output Sheet</h5>
                    <p class="text-xs text-slate-600 dark:text-slate-300">Tickets will be automatically saved here</p>
                  </div>
                </div>
                  <div class="space-y-3">
                    <div class="flex items-center justify-between bg-gray-50 dark:bg-gray-800 rounded-lg">
                      <a 
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
