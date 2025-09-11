<script setup>
import { ref, reactive, onMounted, computed } from 'vue';
import googleSheetsExportAPI from '../../../../api/googleSheetsExport';
import FileKnowledgeSources from '../knowledge-sources/FileKnowledgeSources.vue';
import aiAgents from '../../../../api/aiAgents';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
});

// Tab management
const activeIndex = ref(0);
const tabs = computed(() => [
  {
    key: '0',
    index: 0,
    name: t('AGENT_MGMT.BOOKING_BOT.GENERAL_TAB'),
    icon: 'i-lucide-settings',
  },
  {
    key: '1',
    index: 1,
    name: t('AGENT_MGMT.BOOKING_BOT.FILE_TAB'),
    icon: 'i-lucide-folder',
  },
]);

// Steps: 'auth', 'connected', 'sheetConfig'
const step = ref('auth');
const loading = ref(false);
const account = ref(null); // { email: '...', name: '...' }
const sheets = reactive({ input: '', output: '' });
const notification = ref(null);

// Save state
const isSaving = ref(false);

const templates = [
  {
    label: t('AGENT_MGMT.BOOKING_BOT.TEMPLATE_OPTIONS.KLINIK'),
    value: 'klinik',
  },
  {
    label: t('AGENT_MGMT.BOOKING_BOT.TEMPLATE_OPTIONS.LAPANGAN'),
    value: 'lapangan',
  },
];
const selectedTemplate = ref(templates[0].value);
const minDuration = ref('');

// New fields for resource and location columns
const resourceColumn = ref(['resource', 'resource2', 'resource3']);
const locationColumn = ref(['location']);
const syncingColumns = ref(false);


// Helper function to get agent ID by type
function getAgentIdByType(type) {
  const flowData = props.data?.display_flow_data;
  if (!flowData?.agents_config) return null;
  
  const agent = flowData.agents_config.find(config => config.type === type);
  return agent?.agent_id || null;
}

const agentId = computed(() => {
  return getAgentIdByType('booking');
});

async function connectGoogle() {
  try {
    loading.value = true;
    const response = await googleSheetsExportAPI.getAuthorizationUrl();
    if (response.data.authorization_url) {
      showNotification('Redirecting to Google for authentication...', 'info');
      window.location.href = response.data.authorization_url;
    } else {
      showNotification('Failed to get authorization URL. Please check backend logs.', 'error');
    }
  } catch (error) {
    showNotification('Authentication failed. Please try again.', 'error');
  } finally {
    loading.value = false;
  }
}

async function checkAuthStatus() {
  // useAlert(t('IN BOOKING...'));
  console.log('checking auth status...');
  try {
    loading.value = true;
    const response = await googleSheetsExportAPI.getStatus();
    console.log(JSON.stringify(response.data));
    if (response.data.authorized) {
      step.value = 'connected';
      account.value = {
        email: response.data.email,
        name: 'Connected Account',
      };
      try {
        const flowData = props.data.display_flow_data;
        if (flowData.agents_config[0].configurations.minimum_duration) {
          minDuration.value =
            flowData.agents_config[0].configurations.minimum_duration;
        }
        if (flowData.agents_config[0].configurations.industry) {
          selectedTemplate.value =
            flowData.agents_config[0].configurations.industry;
        }
        const payload = {
          account_id: parseInt(flowData.account_id, 10),
          agent_id: agentId.value,
          type: 'booking',
        };
        console.log(JSON.stringify(payload));
        console.log('payload:', payload);
        const spreadsheet_url_response =
          await googleSheetsExportAPI.getSpreadsheetUrl(payload);
        console.log(JSON.stringify(payload));
        console.log(JSON.stringify(spreadsheet_url_response));

        console.log(
          'spreadsheet_url_response.data:',
          spreadsheet_url_response.data
        );
        if (spreadsheet_url_response.data) {
          sheets.input = spreadsheet_url_response.data.input_spreadsheet_url;
          sheets.output = spreadsheet_url_response.data.output_spreadsheet_url;
          step.value = 'sheetConfig';
        } else {
          sheets.input = '';
          sheets.output = '';
        }
      } catch (error) {
        console.error(
          'Failed to check authorization status while retrieving spreadsheet data:',
          error
        );
        step.value = 'connected';
      }
    } else {
      step.value = 'auth';
    }
    console.log('step:', step);
    console.log('account:', account);
  } catch (error) {
    console.error('Failed to check authorization status:', error)
    step.value = 'auth';
  } finally {
    loading.value = false;
  }
  console.log('step.value:', step.value);
  console.log('checking auth status DONE');
}

function showNotification(message, type = 'success') {
  notification.value = { message, type };
  setTimeout(() => {
    notification.value = null;
  }, 3000);
}

async function syncScheduleColumns() {
  try {
    syncingColumns.value = true;
    showNotification('Syncing schedule columns from sheet...', 'info');

    // TODO: Replace with your actual API endpoint
    // prepare payload
    // retrieve resource_names, location_names, & resource_types
    // save to flow_data
    let flowData = props.data.display_flow_data;
    const payload = {
      account_id: parseInt(flowData.account_id, 10),
      agent_id: agentId.value,
      type: 'booking',
    }

    const result = await googleSheetsExportAPI.syncSpreadsheet(payload);
    console.log('flowData:', flowData);
    console.log('result:', result);
    const agentsConfig = flowData.agents_config;
    // const agent_index = agentsConfig.findIndex(
    //   agent => agent.type === 'booking'
    // );
    const agent_index = flowData.enabled_agents.indexOf('booking');
    console.log('agent_index:', agent_index);
    flowData.agents_config[agent_index].configurations.resource_names =
      result.data.data.unique_resource_names;
    flowData.agents_config[agent_index].configurations.location_names =
      result.data.data.unique_location_names;
    flowData.agents_config[agent_index].configurations.resource_types =
      result.data.data.unique_resource_types;
    // console.log(flowData);
    // console.log(props.config);
    const updatePayload = {
      flow_data: flowData,
    };
    // eslint-disable-next-line no-console
    console.log('payload:', updatePayload);
    // ✅ Properly await the API call
    await aiAgents.updateAgent(props.data.id, updatePayload);
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to sync schedule columns:', error);
    showNotification('Failed to sync schedule columns', 'error');
    syncingColumns.value = false;
  } finally {
    syncingColumns.value = false;
  }
}



async function save() {
  if (isSaving.value) return; // Prevent multiple calls
  const configData = {
    selectedTemplate: selectedTemplate.value,
    minDuration: minDuration.value,
  };
  try {
    isSaving.value = true;
    // Hardcoded payload, exactly as you had it
    let flowData = props.data.display_flow_data;
    // eslint-disable-next-line no-console
    const agent_index = flowData.enabled_agents.indexOf('booking');

    if (agent_index === -1) {
      useAlert(t('AGENT_MGMT.WEBSITE_SETTINGS.AGENT_NOT_FOUND'))
      return;
    }

    flowData.agents_config[agent_index].configurations.minimum_duration =
      configData.minDuration;
    flowData.agents_config[agent_index].configurations.industry =
      configData.selectedTemplate;
    // console.log(flowData);
    // console.log(props.config);
    const payload = {
      flow_data: flowData,
    };
    console.log("payload:", payload);
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

// async function save() {
//   try {
//     isSaving.value = true;

//     // TODO: API call to save booking bot configuration
//     const configData = {
//       selectedTemplate: selectedTemplate.value,
//       minDuration: minDuration.value,
//       resourceColumns: resourceColumn.value,
//       locationColumns: locationColumn.value,
//       sheets: { ...sheets }
//     };
//     // eslint-disable-next-line no-console
//     console.log('configData:', configData);
//     await new Promise(resolve => setTimeout(resolve, 1000));
//     useAlert(t('AGENT_MGMT.BOOKING_BOT.SAVE_SUCCESS'));
//   } catch (e) {
//     useAlert(t('AGENT_MGMT.BOOKING_BOT.SAVE_ERROR'));
//     // eslint-disable-next-line no-console
//     console.error('Save error:', e);
//   } finally {
//     isSaving.value = false;
//   }
// }

onMounted(async () => {
  // eslint-disable-next-line no-use-before-define
  await checkAuthStatus();
});

// async function createSheets() {
//   loading.value = true;
//   // TODO: Call backend to create sheets if needed
//   // For now, just simulate success
//   setTimeout(() => {
//     sheets.input = 'https://docs.google.com/spreadsheets/d/input-sheet-id';
//     sheets.output = 'https://docs.google.com/spreadsheets/d/output-sheet-id';
//     loading.value = false;
//     step.value = 'sheetConfig';
//   }, 1200);
// }

async function createSheets() {
  loading.value = true;
  try {
    // TODO: Call backend to create output sheet
    // For now, simulate sheet creation
    // await new Promise(resolve => setTimeout(resolve, 1200))
    // eslint-disable-next-line no-console
    console.log(JSON.stringify(props.data));
    // eslint-disable-next-line no-console
    const flowData = props.data.display_flow_data;
    const payload = {
      account_id: parseInt(flowData.account_id, 10),
      agent_id: agentId.value,
      type: 'booking',
    };
    // console.log(payload);
    const response = await googleSheetsExportAPI.createSpreadsheet(payload);
    // console.log(response)
    sheets.input = response.data.input_spreadsheet_url;
    sheets.output = response.data.output_spreadsheet_url;
    step.value = 'sheetConfig';
    showNotification('Output sheet created successfully!', 'success');
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to create sheet:', error);
    showNotification('Failed to create sheet. Please try again.', 'error');
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <div class="w-full">
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
    
    <div class="pb-4">
      <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-1">
        {{ $t('AGENT_MGMT.BOOKING_BOT.HEADER') }}
      </h2>
      <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
        {{ $t('AGENT_MGMT.BOOKING_BOT.HEADER_DESC') }}
      </p>
      <div class="border-b border-gray-200 dark:border-gray-700"></div>
    </div>
    
    <div class="space-y-6">
      <!-- Sidebar Navigation -->
      <div class="flex flex-row justify-stretch gap-2">
        <!-- Custom Tabs with SVG Icons -->
        <div class="flex flex-col gap-1 min-w-[200px] mr-4">
          <div
            v-for="tab in tabs"
            :key="tab.key"
            class="flex items-center gap-3 px-4 py-3 cursor-pointer rounded-lg transition-all duration-200 hover:bg-gray-50 dark:hover:bg-gray-800/50"
            :class="{
              'bg-woot-50 border-l-4 border-woot-500 text-woot-600 dark:bg-woot-900/50 dark:border-woot-400 dark:text-woot-400': tab.index === activeIndex,
              'text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-200': tab.index !== activeIndex,
            }"
            @click="activeIndex = tab.index"
          >
            <span
              :class="[
                tab.icon,
                'w-5 h-5 transition-all duration-200',
                {
                  'text-woot-600 dark:text-woot-400': tab.index === activeIndex,
                  'text-gray-500 dark:text-gray-400': tab.index !== activeIndex,
                }
              ]"
            />
            <span class="text-sm">{{ tab.name }}</span>
          </div>
        </div>

        <!-- General Tab Content -->
        <div v-show="activeIndex === 0" class="w-full">
          <div class="flex flex-row gap-4">
            <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-6">
              <!-- Step 1: Google Auth -->
              <div v-if="step === 'auth'" class="w-full mx-auto">
                <div>
                  <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.BOOKING_BOT.AUTH_LABEL') }}</label>
                  <p class="text-gray-600 dark:text-gray-400 mb-4">
                    {{ $t('AGENT_MGMT.BOOKING_BOT.AUTH_DESC') }}
                  </p>
                  <button
                    @click="connectGoogle"
                    class="inline-flex items-center space-x-3 bg-green-600 hover:bg-green-700 dark:bg-green-400 dark:hover:bg-green-500 text-white px-6 py-3 rounded-lg font-medium transition-colors"
                  >
                    <span>{{ $t('AGENT_MGMT.BOOKING_BOT.AUTH_BTN') }}</span>
                  </button>
                </div>
              </div>

              <!-- Step 2: Connected Confirmation -->
              <div v-else-if="step === 'connected'" class="py-8">
                <div class="text-center mb-8">
                  <div class="w-16 h-16 bg-green-100 dark:bg-green-800 rounded-full flex items-center justify-center mx-auto mb-4">
                    <svg class="w-8 h-8 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
                    </svg>
                  </div>
                  <h3 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-2">{{ $t('AGENT_MGMT.BOOKING_BOT.CONNECTED_HEADER') }}</h3>
                  <p class="text-gray-600 dark:text-gray-400">{{ $t('AGENT_MGMT.BOOKING_BOT.CONNECTED_DESC') }}</p>
                  <p class="mt-2 text-sm text-gray-500">{{ account?.email }}</p>
                  <button
                    class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
                    @click="createSheets"
                    :disabled="loading"
                  >
                    <span v-if="loading">{{ $t('AGENT_MGMT.BOOKING_BOT.CREATE_SHEETS_LOADING') }}</span>
                    <span v-else>{{ $t('AGENT_MGMT.BOOKING_BOT.CREATE_SHEETS_BTN') }}</span>
                  </button>
                </div>
              </div>

              <!-- Step 3: Sheet Configuration -->
              <div v-else-if="step === 'sheetConfig'">
                <div class="space-y-6">
                  <!-- Input Sheet Section - Schedule Data -->
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
                              {{ $t('AGENT_MGMT.BOOKING_BOT.INPUT_SHEET_LABEL') }}
                            </h3>
                            <p class="text-sm text-slate-600 dark:text-slate-400">
                              {{ $t('AGENT_MGMT.BOOKING_BOT.INPUT_SHEET_DESC') }}
                            </p>
                          </div>
                        </div>
                      </div>
                      <div class="flex flex-col gap-2">
                        <a 
                          :href="sheets.input" 
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

                    <!-- Schedule Column Sync Section -->
                    <div class="border-t border-blue-200 dark:border-blue-700 pt-6">
                      <div class="mb-4">
                        <h4 class="text-md font-medium text-slate-900 dark:text-slate-25 mb-2">{{ $t('AGENT_MGMT.BOOKING_BOT.SCHEDULE_CONFIGURATION') }}</h4>
                        <p class="text-sm text-blue-700 dark:text-blue-300">
                          {{ $t('AGENT_MGMT.BOOKING_BOT.SCHEDULE_CONFIGURATION_DESC') }}
                        </p>
                      </div>
                      
                      <!-- Minimum Duration Field -->
                        <div class="mb-6 flex flex-col md:flex-row md:items-start md:gap-6">
                          <div class="flex-1">
                            <label class="block text-sm font-medium mb-1 text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.BOOKING_BOT.MIN_DURATION_LABEL') }}</label>
                            <input 
                              type="number" 
                              min="0"
                              placeholder="30"
                              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                              v-model="minDuration" 
                            />
                          </div>
                          <div class="flex-1">
                            <label class="block text-sm font-medium mb-1 text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.BOOKING_BOT.INDUSTRY_TEMPLATE') }}</label>
                            <select 
                              v-model="selectedTemplate" 
                              class="w-full mb-0 p-2 text-sm border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
                            >
                              <option v-for="tpl in templates" :key="tpl.value" :value="tpl.value">{{ tpl.label }}</option>
                            </select>
                          </div>
                        </div>

                      <!-- Sync Button for Resource and Location Lists -->
                      <div class="flex justify-start">
                        <button
                          @click="syncScheduleColumns"
                          :disabled="syncingColumns"
                          class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center gap-2 h-10"
                        >
                          <svg v-if="syncingColumns" class="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                            <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" class="opacity-25"/>
                            <path fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" class="opacity-75"/>
                          </svg>
                          <svg v-else class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                          </svg>
                          {{ syncingColumns ? 'Syncing...' : $t('AGENT_MGMT.BOOKING_BOT.SYNC_BUTTON') }}
                        </button>
                      </div>
                    </div>
                  </div>

                  <!-- Output Sheet Section - Booking Results -->
                  <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-6 mb-6 border border-blue-200 dark:border-blue-800">
                    <div class="flex items-center justify-between">
                      <div class="flex items-center">
                        <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                          <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                            <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                          </svg>
                        </div>
                        <div>
                          <h4 class="font-medium text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.BOOKING_BOT.OUTPUT_SHEET_LABEL') }}</h4>
                          <p class="text-sm text-slate-600 dark:text-slate-400">{{ $t('AGENT_MGMT.BOOKING_BOT.OUTPUT_SHEET_DESC') }}</p>
                        </div>
                      </div>
                      <a 
                        :href="sheets.output" 
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
            
            <div v-if="step === 'sheetConfig'" class="w-[240px] flex flex-col gap-3">
              <div class="sticky top-4 bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-4 shadow-sm">
                <div class="flex items-center gap-3 mb-4">
                  <div class="w-10 h-10 flex-shrink-0 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">                    <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    </svg>
                  </div>
                  <div>
                    <h3 class="font-semibold text-slate-700 dark:text-slate-300">{{ $t('AGENT_MGMT.BOOKING_BOT.GENERAL_TAB') }}</h3>
                    <p class="text-sm text-slate-500 dark:text-slate-400">Configure booking settings</p>
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
                    {{ $t('AGENT_MGMT.BOOKING_BOT.SAVE_BTN') }}
                  </span>
                </Button>
              </div>
            </div>
          </div>
        </div>

        <!-- File Tab Content -->
        <div v-show="activeIndex === 1" class="w-full min-w-0">
          <FileKnowledgeSources :data="data" />
        </div>
      </div>
    </div>
  </div>
</template>
