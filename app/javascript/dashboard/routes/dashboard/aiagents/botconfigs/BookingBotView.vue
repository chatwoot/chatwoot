<script setup>
import { ref, reactive, onMounted } from 'vue';
import googleSheetsExportAPI from '../../../../api/googleSheetsExport';

// Wizard step: 'auth', 'connected', 'sheetConfig'
const step = ref('auth');
const loading = ref(false);
const account = ref(null); // { email: '...', name: '...' }
const sheets = reactive({ input: '', output: '' });
const notification = ref(null);

import { useI18n } from 'vue-i18n';
const { t } = useI18n();

const templates = [
  { label: t('AGENT_MGMT.BOOKING_BOT.TEMPLATE_OPTIONS.KLINIK'), value: 'klinik' },
  { label: t('AGENT_MGMT.BOOKING_BOT.TEMPLATE_OPTIONS.LAPANGAN'), value: 'lapangan' },
];
const selectedTemplate = ref(templates[0].value);
const minDuration = ref('');

// New fields for resource and location columns
const resourceColumn = ref(['resource','resource2','resource3']);
const locationColumn = ref(['location']);
const syncingColumns = ref(false);

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
  try {
    loading.value = true;
    const response = await googleSheetsExportAPI.getStatus();
    if (response.data.authorized) {
      step.value = 'connected';
      account.value = {
        email: response.data.email,
        name: 'Connected Account'
      };
      if (response.data.spreadsheet_url) {
        sheets.input = response.data.spreadsheet_url;
        sheets.output = response.data.spreadsheet_url_output || '';
        step.value = 'sheetConfig';
      } else {
        sheets.input = '';
        sheets.output = '';
      }
    } else {
      step.value = 'auth';
    }
  } catch (error) {
    showNotification('Failed to check authorization status. Please try again.', 'error');
    step.value = 'auth';
  } finally {
    loading.value = false;
  }
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
    // const response = await fetch('/api/sheets/sync-schedule-columns', {
    //   method: 'POST',
    //   headers: {
    //     'Content-Type': 'application/json',
    //   },
    //   body: JSON.stringify({
    //     sheetUrl: sheets.input
    //   })
    // });
    // const data = await response.json();
    
    // For now, simulate API response
    setTimeout(() => {
      const syncedResourceColumns = ['doctor_name', 'nurse_name', 'specialist'];
      const syncedLocationColumns = ['clinic_location', 'room_number', 'building'];
      resourceColumn.value = syncedResourceColumns;
      locationColumn.value = syncedLocationColumns;
      showNotification('Schedule columns synced successfully!', 'success');
      syncingColumns.value = false;
    }, 2000);
    
  } catch (error) {
    console.error('Failed to sync schedule columns:', error);
    showNotification('Failed to sync schedule columns', 'error');
    syncingColumns.value = false;
  }
}

// TEMPORARY
onMounted(() => {
  // Skip Google connect, go straight to sheetConfig for now
  step.value = 'connected';
});

async function createSheets() {
  loading.value = true;
  // TODO: Call backend to create sheets if needed
  // For now, just simulate success
  setTimeout(() => {
    sheets.input = 'https://docs.google.com/spreadsheets/d/input-sheet-id';
    sheets.output = 'https://docs.google.com/spreadsheets/d/output-sheet-id';
    loading.value = false;
    step.value = 'sheetConfig';
  }, 1200);
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
    <!-- Step 1: Google Auth -->
    <div v-if="step === 'auth'" class="w-full mx-auto">
      <div class="pb-4">
        <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-1">
          {{ $t('AGENT_MGMT.CSBOT.TICKET.HEADER') }}
        </h2>
        <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
          {{ $t('AGENT_MGMT.CSBOT.TICKET.HEADER_DESC') }}
        </p>
        <div class="border-b border-gray-200 dark:border-gray-700"></div>
      </div>
      <div >
        <label class="block font-medium ">{{ $t('AGENT_MGMT.BOOKING_BOT.AUTH_LABEL') }}</label>
        <p class="text-gray-600 dark:text-gray-400">
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

    <!-- Step 2: Konfirmasi Koneksi -->
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

    <!-- Step 3: Konfigurasi Sheets -->
    <div v-else-if="step === 'sheetConfig'">
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
              <div class="mb-6 flex flex-col md:flex-row md:items-end md:gap-6">
                <div class="flex-1">
                  <label class="block text-sm font-medium mb-1 text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.BOOKING_BOT.MIN_DURATION_LABEL') }}</label>
                  <input 
                    type="number" 
                    min="0"
                    placeholder="30"
                    class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                    :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.COST_PER_DISTANCE_PLACEHOLDER')" 
                    v-model="minDuration" 
                  />
                </div>
                <div class="flex-1">
                  <label class="block text-sm font-medium mb-1 text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.BOOKING_BOT.INDUSTRY_TEMPLATE') }}</label>
                  <select 
                    v-model="selectedTemplate" 
                    class="w-full mb-0 p-2 text-sm  border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
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

        <!-- Additional Configuration -->
        <!-- <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
          <div class="mb-4">
            <h4 class="text-md font-medium text-slate-900 dark:text-slate-25 mb-2">Industry Template</h4>
            <p class="text-sm text-slate-600 dark:text-slate-400">{{ $t('AGENT_MGMT.BOOKING_BOT.TEMPLATE_LABEL') }}</p>
          </div>
          <select 
            v-model="selectedTemplate" 
            class="w-full md:w-1/3 p-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-slate-25"
          >
            <option v-for="tpl in templates" :key="tpl.value" :value="tpl.value">{{ tpl.label }}</option>
          </select>
        </div> -->

        <!-- Save Button -->
        <div class="pt-6 pb-4">
          <button
            class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 transition-colors"
            @click="() => { /* TODO: handle save */ }"
          >
            {{ $t('AGENT_MGMT.BOOKING_BOT.SAVE_BTN') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>