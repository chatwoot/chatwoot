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
       <!-- Improved Google Spreadsheets Links Section -->
      <div class="space-y-3 mb-4">
        <!-- Input Sheet -->
        <div class="relative p-6 rounded-lg border-2 transition-all duration-200 cursor-pointer dark:bg-green-900/20 border-green-200 dark:border-green-700 hover:shadow-lg flex items-center justify-between mb-2">
          <div class="flex items-center space-x-3">
            <div class="flex-shrink-0">
              <div class="w-8 h-8 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
                <svg class="w-4 h-4 text-blue-600 dark:text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                </svg>
              </div>
            </div>
            <div>
              <label class="font-medium text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.BOOKING_BOT.INPUT_SHEET_LABEL') }}</label>
              <p class="text-sm text-slate-600 dark:text-slate-400">{{ $t('AGENT_MGMT.BOOKING_BOT.INPUT_SHEET_DESC') }}</p>
            </div>
          </div>
          <a 
            :href="sheets.input" 
            target="_blank" 
            class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-900/30 hover:bg-green-100 dark:hover:bg-green-900/50 rounded-lg transition-colors"
          >
            <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>
            </svg>
            {{ $t('AGENT_MGMT.BOOKING_BOT.OPEN_SHEET_BTN') }}
          </a>
        </div>

        <!-- Output Sheet -->
        <div class="relative p-6 rounded-lg border-2 transition-all duration-200 cursor-pointer dark:bg-green-900/20 border-green-200 dark:border-green-700 hover:shadow-lg flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <div class="flex-shrink-0">
              <div class="w-8 h-8 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center">
                <svg class="w-4 h-4 text-blue-600 dark:text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                </svg>
              </div>
            </div>
            <div>
              <label class="font-medium text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.BOOKING_BOT.OUTPUT_SHEET_LABEL') }}</label>
              <p class="text-sm text-slate-600 dark:text-slate-400">{{ $t('AGENT_MGMT.BOOKING_BOT.OUTPUT_SHEET_DESC') }}</p>
            </div>
          </div>
          <a 
            :href="sheets.output" 
            target="_blank" 
            class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-900/30 hover:bg-green-100 dark:hover:bg-green-900/50 rounded-lg transition-colors"
          >
            <svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>
            </svg>
            {{ $t('AGENT_MGMT.BOOKING_BOT.OPEN_SHEET_BTN') }}
          </a>
        </div>
      </div>
      <div class="flex flex-col gap-4">
        <div>
          <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.BOOKING_BOT.TEMPLATE_LABEL') }}</label>
          <select v-model="selectedTemplate" class="w-1/2 p-2 border rounded-md">
            <option v-for="tpl in templates" :key="tpl.value" :value="tpl.value">{{ tpl.label }}</option>
          </select>
        </div>
        <!-- <div class="flex gap-4">
          <div class="flex-1">
            <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.BOOKING_BOT.RESOURCE_LABEL') }}</label>
            <input
              type="text"
              class="w-full p-2 border rounded-md"
              :placeholder="$t('AGENT_MGMT.BOOKING_BOT.RESOURCE_PLACEHOLDER')"
            />
          </div>
          <div class="flex-1">
            <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.BOOKING_BOT.LOCATION_LABEL') }}</label>
            <input
              type="text"
              class="w-full p-2 border rounded-md"
              :placeholder="$t('AGENT_MGMT.BOOKING_BOT.LOCATION_PLACEHOLDER')"
            />
          </div>
        </div> -->
        <div class="w-1/4">
          <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.BOOKING_BOT.MIN_DURATION_LABEL') }}</label>
          <input
            v-model="minDuration"
            type="number"
            min="0"
            class="p-2 border rounded-md"
          />
        </div>
      </div>
      <div class="pt-6">
        <button
          class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
          @click="() => { /* TODO: handle save */ }"
        >
          {{ $t('AGENT_MGMT.BOOKING_BOT.SAVE_BTN') }}
        </button>
      </div>
    </div>
  </div>
</template>