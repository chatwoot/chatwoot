<script setup>
import { ref, reactive, onMounted, computed } from 'vue';
import googleSheetsExportAPI from '../../../../api/googleSheetsExport';
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
    name: t('AGENT_MGMT.RESTAURANT_BOT.GENERAL_TAB'),
    icon: 'i-lucide-settings',
  },
  {
    key: '1',
    index: 1,
    name: t('AGENT_MGMT.RESTAURANT_BOT.ORDERS_COSTS_TAB'),
    icon: 'i-lucide-calculator',
  },
]);

// General Tab - Google Sheets Integration (similar to BookingBot)
const step = ref('auth');
const loading = ref(false);
const account = ref(null);
const sheets = reactive({ input: '', output: '' });
const notification = ref(null);
const menuBookLink = ref('');

// Orders & Costs Tab
const orderSettings = reactive({
  minTimeBeforeOrder: 30, // minutes
  minOrderTotal: 50000, // Rp
  taxEnabled: false,
  taxPercent: 10,
  serviceChargeEnabled: false,
  serviceChargePercent: 5,
});

// Save state
const isSaving = ref(false);
async function checkAuthStatus() {
  // useAlert(t('IN RESTAURANT...'));
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
        const payload = {
          account_id: parseInt(flowData.account_id, 10),
          agent_id: String(props.data.id),
          type: 'restaurant',
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
      agent_id: String(props.data.id),
      type: 'restaurant',
    };
    // console.log(payload);
    const response = await googleSheetsExportAPI.createSpreadsheet(payload);
    // console.log(response)
    sheets.output = response.data.output_spreadsheet_url;
    step.value = 'sheetConfig';
    showNotification('Output sheet created successfully!', 'success');
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to create sheet:', error);
    showNotification(
      'Failed to create sheet. Please try again.',
      'error'
    );
  } finally {
    loading.value = false;
  }
}
async function save() {
  if (isSaving.value) return; // Prevent multiple calls
  const configData = {
    menuBookLink: menuBookLink.value,
    orderSettings: { ...orderSettings }
  };
  let tax = 0;
  if (orderSettings.taxEnabled){
    tax = orderSettings.taxPercent
  }
  let serviceCharge = 0;
  if (orderSettings.serviceChargeEnabled){
    serviceCharge = orderSettings.serviceChargePercent
  }
  try {
    isSaving.value = true;
    // Hardcoded payload, exactly as you had it
    let flowData = props.data.display_flow_data;
    // console.log(flowData)
    const agentsConfig = flowData.agents_config;
    // const agent_index = agentsConfig.findIndex(agent => agent.type === "restaurant");
    const agent_index = 0;

    flowData.agents_config[agent_index].configurations.tax = tax;
    flowData.agents_config[agent_index].configurations.service_charge = serviceCharge;
    flowData.agents_config[agent_index].configurations.url_menu = configData.menuBookLink;
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
    
//     // TODO: API call to save both menu book link and order settings
//     const configData = {
//       menuBookLink: menuBookLink.value,
//       orderSettings: { ...orderSettings }
//     };
    
//     await new Promise(resolve => setTimeout(resolve, 1000));
//     useAlert(t('AGENT_MGMT.RESTAURANT_BOT.SAVE_SUCCESS'));
//   } catch (e) {
//     useAlert(t('AGENT_MGMT.RESTAURANT_BOT.SAVE_ERROR'));
//     console.error('Save error:', e);
//   } finally {
//     isSaving.value = false;
//   }
// }

// Legacy function for backward compatibility
function saveOrderSettings() {
  save();
}

onMounted(async () => {
  // eslint-disable-next-line no-use-before-define
  await checkAuthStatus();
});
</script>

<template>
  <div class="w-full min-h-0">
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
        {{ $t('AGENT_MGMT.RESTAURANT_BOT.HEADER') }}
      </h2>
      <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
        {{ $t('AGENT_MGMT.RESTAURANT_BOT.HEADER_DESC') }}
      </p>
      <div class="border-b border-gray-200 dark:border-gray-700"></div>
    </div>
    
    <div class="space-y-6 pb-6">
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
          <!-- Step 1: Google Auth -->
          <div v-if="step === 'auth'" class="w-full mx-auto">
            <div>
              <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.RESTAURANT_BOT.AUTH_LABEL') }}</label>
              <p class="text-gray-600 dark:text-gray-400 mb-4">
                {{ $t('AGENT_MGMT.RESTAURANT_BOT.AUTH_DESC') }}
              </p>
              <button
                @click="connectGoogle"
                class="inline-flex items-center space-x-3 bg-green-600 hover:bg-green-700 dark:bg-green-400 dark:hover:bg-green-500 text-white px-6 py-3 rounded-lg font-medium transition-colors"
              >
                <span>{{ $t('AGENT_MGMT.RESTAURANT_BOT.AUTH_BTN') }}</span>
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
              <h3 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-2">{{ $t('AGENT_MGMT.RESTAURANT_BOT.CONNECTED_HEADER') }}</h3>
              <p class="text-gray-600 dark:text-gray-400">{{ $t('AGENT_MGMT.RESTAURANT_BOT.CONNECTED_DESC') }}</p>
              <p class="mt-2 text-sm text-gray-500">{{ account?.email }}</p>
              <button
                class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
                @click="createSheets"
                :disabled="loading"
              >
                <span v-if="loading">{{ $t('AGENT_MGMT.RESTAURANT_BOT.CREATE_SHEETS_LOADING') }}</span>
                <span v-else>{{ $t('AGENT_MGMT.RESTAURANT_BOT.CREATE_SHEETS_BTN') }}</span>
              </button>
            </div>
          </div>

          <!-- Step 3: Sheet Configuration -->
          <div v-else-if="step === 'sheetConfig'">
            <div class="space-y-6">
              <!-- Input Sheet Section - Restaurant Data -->
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
                          {{ $t('AGENT_MGMT.RESTAURANT_BOT.INPUT_SHEET_TITLE') }}
                        </h3>
                        <p class="text-sm text-slate-600 dark:text-slate-400">
                          {{ $t('AGENT_MGMT.RESTAURANT_BOT.INPUT_SHEET_DESC') }}
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
                      {{ $t('AGENT_MGMT.RESTAURANT_BOT.OPEN_SHEET_BTN') }}
                    </a>
                  </div>
                </div>

                <div class="border-t border-blue-200 dark:border-blue-700 pt-6">
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

              <!-- Output Sheet Section - Order Results -->
              <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-6 mb-6 border border-blue-200 dark:border-blue-800">
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                      <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                      </svg>
                    </div>
                    <div>
                      <h4 class="font-medium text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.RESTAURANT_BOT.OUTPUT_SHEET_TITLE') }}</h4>
                      <p class="text-sm text-slate-600 dark:text-slate-400">{{ $t('AGENT_MGMT.RESTAURANT_BOT.OUTPUT_SHEET_DESC') }}</p>
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
                    {{ $t('AGENT_MGMT.RESTAURANT_BOT.OPEN_SHEET_BTN') }}
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Orders & Costs Tab Content -->
        <div v-show="activeIndex === 1" class="w-full">
          <div class="flex flex-row gap-4">
            <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-6">
              <div class="space-y-4">
                
                <!-- Digital Menu Book Link -->
                <div class="mb-6">
                  <label class="block font-medium mb-2">{{ $t('AGENT_MGMT.RESTAURANT_BOT.MENU_BOOK_TITLE') }}</label>
                  <p class="text-sm text-gray-500 mb-3">{{ $t('AGENT_MGMT.RESTAURANT_BOT.MENU_BOOK_DESC') }}</p>
                  <input
                    type="text"
                    v-model="menuBookLink"
                    class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                    :placeholder="$t('AGENT_MGMT.RESTAURANT_BOT.MENU_BOOK_PLACEHOLDER')"
                  />
                </div>

                <!-- Minimum Time Before Order -->
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    {{ $t('AGENT_MGMT.RESTAURANT_BOT.MIN_TIME_LABEL') }}
                  </label>
                  <input
                    type="number"
                    v-model="orderSettings.minTimeBeforeOrder"
                    min="0"
                    class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                    placeholder="30"
                  />
                  <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{{ $t('AGENT_MGMT.RESTAURANT_BOT.MIN_TIME_DESC') }}</p>
                </div>

                <!-- Minimum Order Total -->
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    {{ $t('AGENT_MGMT.RESTAURANT_BOT.MIN_ORDER_TOTAL_LABEL') }}
                  </label>
                  <div class="relative">
                    <span class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500 text-sm">Rp</span>
                    <input
                      type="number"
                      v-model="orderSettings.minOrderTotal"
                      min="0"
                      class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !pl-8 !pr-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                      :placeholder="$t('AGENT_MGMT.RESTAURANT_BOT.MIN_ORDER_TOTAL_PLACEHOLDER')"
                    />
                  </div>
                  <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">{{ $t('AGENT_MGMT.RESTAURANT_BOT.MIN_ORDER_TOTAL_DESC') }}</p>
                </div>

                <!-- Tax Settings -->
                <div>
                  <div class="flex items-center justify-between mb-3">
                    <div>
                      <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ $t('AGENT_MGMT.RESTAURANT_BOT.TAX_LABEL') }}</h4>
                      <p class="text-xs text-gray-500 dark:text-gray-400">{{ $t('AGENT_MGMT.RESTAURANT_BOT.TAX_DESC') }}</p>
                    </div>
                    <label class="inline-flex items-center cursor-pointer">
                      <input type="checkbox" v-model="orderSettings.taxEnabled" class="sr-only peer">
                      <div class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full"></div>
                    </label>
                  </div>
                  
                  <div v-if="orderSettings.taxEnabled" class="ml-4 transition-all duration-200 ease-in-out">
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{{ $t('AGENT_MGMT.RESTAURANT_BOT.TAX_PERCENT_LABEL') }}</label>
                    <div class="flex items-center gap-2 max-w-xs">
                      <input
                        type="number"
                        v-model="orderSettings.taxPercent"
                        min="0"
                        max="100"
                        step="0.1"
                        class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                      />
                    </div>
                  </div>
                </div>

                <!-- Service Charge Settings -->
                <div>
                  <div class="flex items-center justify-between mb-3">
                    <div>
                      <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ $t('AGENT_MGMT.RESTAURANT_BOT.SERVICE_CHARGE_LABEL') }}</h4>
                      <p class="text-xs text-gray-500 dark:text-gray-400">{{ $t('AGENT_MGMT.RESTAURANT_BOT.SERVICE_CHARGE_DESC') }}</p>
                    </div>
                    <label class="inline-flex items-center cursor-pointer">
                      <input type="checkbox" v-model="orderSettings.serviceChargeEnabled" class="sr-only peer">
                      <div class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full"></div>
                    </label>
                  </div>
                  
                  <div v-if="orderSettings.serviceChargeEnabled" class="ml-4 transition-all duration-200 ease-in-out">
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{{ $t('AGENT_MGMT.RESTAURANT_BOT.SERVICE_CHARGE_PERCENT_LABEL') }}</label>
                    <div class="flex items-center gap-2 max-w-xs">
                      <input
                        type="number"
                        v-model="orderSettings.serviceChargePercent"
                        min="0"
                        max="100"
                        step="0.1"
                        class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            <div class="w-[240px] flex flex-col gap-3">
              <div class="sticky top-4 bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-4 shadow-sm">
                <div class="flex items-center gap-3 mb-4">
                  <div class="w-10 h-10 flex-shrink-0 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                    <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"></path>
                    </svg>
                  </div>
                  <div>
                    <h3 class="font-semibold text-slate-700 dark:text-slate-300">{{ $t('AGENT_MGMT.RESTAURANT_BOT.ORDERS_COSTS_SETTINGS') }}</h3>
                    <p class="text-sm text-slate-500 dark:text-slate-400">Configure order and pricing settings</p>
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
                    {{ $t('AGENT_MGMT.RESTAURANT_BOT.SAVE_BTN') }}
                  </span>
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>