<script setup>
import { ref, onMounted, watch } from 'vue';
import googleSheetsExportAPI from '../../../api/googleSheetsExport';

const props = defineProps({
  data: {
    type: Object,
    default: () => ({})
  }
});

const currentView = ref('integrations'); 
const loading = ref(false);
const connectedAccount = ref(null);
const spreadsheetInfo = ref(null);
const currentStep = ref('auth');

const notification = ref(null);

const integrations = ref([
  {
    id: 'google-sheets',
    name: 'Google Sheets',
    description: 'Isi spreadsheet Anda dengan data formulir secara instan',
    icon: '/assets/images/Sheets_icon.png',
    color: 'bg-green-50 dark:bg-green-900/20',
    iconColor: 'text-green-600 dark:text-green-400',
    borderColor: 'border-green-200 dark:border-green-700',
    available: true
  },
  // {
  //   id: 'excel',
  //   name: 'Microsoft Excel',
  //   description: 'Sync data with Excel spreadsheets',
  //   icon: '/assets/images/dashboard/configuration/ic_ms_excel.svg',
  //   color: 'bg-blue-50 dark:bg-blue-900/20',
  //   iconColor: 'text-blue-600 dark:text-blue-400',
  //   borderColor: 'border-blue-200 dark:border-blue-700',
  //   available: false
  // },
  // {
  //   id: 'airtable',
  //   name: 'Airtable',
  //   description: 'Connect with Airtable databases',
  //   icon: '/assets/images/dashboard/configuration/ic_air_table.svg',
  //   color: 'bg-orange-50 dark:bg-orange-900/20',
  //   iconColor: 'text-orange-600 dark:text-orange-400',
  //   borderColor: 'border-orange-200 dark:border-orange-700',
  //   available: false
  // },
  // {
  //   id: 'notion',
  //   name: 'Notion',
  //   description: 'Sync data with Notion databases',
  //   icon: '/assets/images/dashboard/configuration/ic_notion.svg',
  //   color: 'bg-gray-50 dark:bg-gray-900/20',
  //   iconColor: 'text-gray-600 dark:text-gray-400',
  //   borderColor: 'border-gray-200 dark:border-gray-700',
  //   available: false
  // },
  // {
  //   id: 'zapier',
  //   name: 'Zapier',
  //   description: 'Connect with 5000+ apps via Zapier',
  //   icon: '/assets/images/dashboard/configuration/ic_zapier.svg',
  //   color: 'bg-purple-50 dark:bg-purple-900/20',
  //   iconColor: 'text-purple-600 dark:text-purple-400',
  //   borderColor: 'border-purple-200 dark:border-purple-700',
  //   available: false
  // },
  // {
  //   id: 'slack',
  //   name: 'Slack',
  //   description: 'Send notifications to Slack channels',
  //   icon: '/assets/images/dashboard/configuration/ic_slack.svg',
  //   color: 'bg-pink-50 dark:bg-pink-900/20',
  //   iconColor: 'text-pink-600 dark:text-pink-400',
  //   borderColor: 'border-pink-200 dark:border-pink-700',
  //   available: false
  // }
]);

const showNotification = (message, type = 'success') => {
  notification.value = { message, type };
  setTimeout(() => {
    notification.value = null;
  }, 3000);
};

const checkAuthStatus = async () => {
  try {
    loading.value = true;
    const response = await googleSheetsExportAPI.getStatus();
    
    if (response.data.authorized) {
      currentStep.value = 'connected';
      connectedAccount.value = {
        email: response.data.email,
        name: 'Connected Account'
      };
      
      if (response.data.spreadsheet_url) {
        spreadsheetInfo.value = {
          url: response.data.spreadsheet_url,
          title: response.data.title || 'Generated Spreadsheet',
          created_at: response.data.created_at || new Date().toISOString()
        };
      } else {
        spreadsheetInfo.value = null;
      }
    } else {
      currentStep.value = 'auth';
    }
  } catch (error) {
    console.error('Error checking auth status:', error);
    currentStep.value = 'auth';
    showNotification('Failed to check authorization status. Please try again.', 'error');
  } finally {
    loading.value = false;
  }
};

const handleGoogleAuth = async () => {
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
    console.error('Auth error:', error);
    showNotification('Authentication failed. Please try again.', 'error');
  } finally {
    loading.value = false;
  }
};

const openSpreadsheet = () => {
  if (spreadsheetInfo.value?.url) {
    window.open(spreadsheetInfo.value.url, '_blank');
    showNotification('Opening Google Sheets in new tab...');
  } else {
    showNotification('No spreadsheet available. Please authenticate first.', 'error');
  }
};

const disconnectAccount = async () => {
  try {
    loading.value = true;
    connectedAccount.value = null;
    spreadsheetInfo.value = null;
    currentStep.value = 'auth';
    showNotification('Account disconnected successfully.');
  } catch (error) {
    console.error('Disconnect error:', error);
    showNotification('Failed to disconnect account.', 'error');
  } finally {
    loading.value = false;
  }
};

const handleIntegrationClick = (integration) => {
  if (integration.id === 'google-sheets' && integration.available) {
    currentView.value = 'google-sheets';
  } else if (!integration.available) {
    showNotification(`${integration.name} integration is coming soon!`, 'info');
  }
};

const handleBackToIntegrations = () => {
  currentView.value = 'integrations';
  currentStep.value = 'auth';
  connectedAccount.value = null;
  spreadsheetInfo.value = null;
};

onMounted(() => {
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('code') || urlParams.has('google_auth_success') || urlParams.has('google_auth_error')) {
    currentView.value = 'google-sheets';
    const newUrl = window.location.pathname + window.location.hash;
    window.history.replaceState({}, document.title, newUrl);

    if (urlParams.has('google_auth_success')) {
      showNotification('Authentication successful! Spreadsheet has been created.', 'success');
    } else if (urlParams.has('google_auth_error')) {
      showNotification('Authentication failed. Please try again.', 'error');
    }
  }
});

watch(currentView, (newValue) => {
  if (newValue === 'google-sheets') {
    checkAuthStatus();
  }
});
</script>

<template>
  <div class="w-full">
    <div
      v-if="notification"
      :class="[
        'fixed top-4 right-4 z-50 px-6 py-4 rounded-lg shadow-lg transition-all duration-300',
        notification.type === 'success' ? 'bg-green-500 text-white' :
        notification.type === 'error' ? 'bg-red-500 text-white' :
        notification.type === 'info' ? 'bg-blue-500 text-white' :
        'bg-gray-500 text-white'
      ]"
    >
      <div class="flex items-center space-x-2">
        <svg v-if="notification.type === 'success'" class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
        </svg>
        <svg v-else-if="notification.type === 'error'" class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 01-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
        </svg>
        <svg v-else class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 101 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
        </svg>
        <span>{{ notification.message }}</span>
      </div>
    </div>

    <div v-if="currentView === 'integrations'" class="space-y-6">
      <div class="border-b border-gray-200 dark:border-gray-700 pb-4">
        <h2 class="text-3xl font-bold text-slate-900 dark:text-slate-25 mb-2">
          Integrasi Data Manajemen
        </h2>
        <div class="flex items-center space-x-2 text-gray-600 dark:text-gray-400">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
          </svg>
          <span>{{ integrations.length }} Integrations</span>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="integration in integrations"
          :key="integration.id"
          @click="handleIntegrationClick(integration)"
          :class="[
            'relative p-6 rounded-lg border-2 transition-all duration-200 cursor-pointer',
            integration.color,
            integration.borderColor,
            integration.available 
              ? 'hover:shadow-lg hover:scale-105 hover:border-opacity-80'
              : 'opacity-60 hover:opacity-80'
          ]"
        >
          <div v-if="integration.available" class="absolute top-3 right-3">
            <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
              Tersedia
            </span>
          </div>
          
          <div v-else class="absolute top-3 right-3">
            <span
              class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium
                    bg-gray-100 text-gray-600
                    dark:bg-gray-800 dark:text-gray-400 dark:border dark:border-gray-600"
            >
              Coming Soon
            </span>
          </div>

          <div :class="['text-4xl mb-4', integration.iconColor]">
            <img :src="integration.icon" alt="" class="w-12 h-12 object-contain" />
          </div>

          <h3 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-2">
            {{ integration.name }}
          </h3>
          <p class="text-gray-600 dark:text-gray-400 text-sm leading-relaxed">
            {{ integration.description }}
          </p>

          <div class="absolute bottom-4 right-4">
            <svg class="w-5 h-5 text-gray-400 dark:text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
            </svg>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="currentView === 'google-sheets'" class="w-full max-w-4xl mx-auto">
      <div class="flex items-center mb-8">
        <button
          @click="handleBackToIntegrations"
          class="flex items-center space-x-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200 transition-colors"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
          </svg>
          <span>Back</span>
        </button>
      </div>

      <div class="dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="bg-green-50 dark:bg-green-900/20 px-8 py-6 border-b border-green-200 dark:border-green-700">
          <div class="flex items-center space-x-4">
            <div class="w-12 h-12 bg-green-100 dark:bg-green-800 rounded-lg flex items-center justify-center">
              <svg class="w-8 h-8 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 24 24">
                <path d="M19,3H5C3.9,3 3,3.9 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5C21,4.1 20.1,3 19,3M19,19H5V5H19V19Z"/>
                <path d="M7,7H9V9H7V7M11,7H13V9H11V7M15,7H17V9H15V7M7,11H9V13H7V11M11,11H13V13H11V11M15,11H17V13H15V11M7,15H9V17H7V15M11,15H13V17H11V15M15,15H17V17H15V15Z"/>
              </svg>
            </div>
            <div>
              <h2 class="text-2xl font-bold text-slate-900 dark:text-slate-25">Google Sheets</h2>
            </div>
          </div>
        </div>

        <div class="p-8 dark:bg-gray-800 rounded-lg">
          <div v-if="loading" class="text-center py-12">
            <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-green-600 dark:border-green-400"></div>
            <p class="mt-4 text-gray-600 dark:text-gray-400">Processing...</p>
          </div>

          <div v-else-if="currentStep === 'auth'" class="text-center py-8">
            <div class="bg-gray-50 dark:bg-gray-700 dark:border dark:border-gray-600 rounded-lg p-6 mb-6">
              <div class="flex items-center justify-center space-x-4 mb-4">
                <div class="flex items-center space-x-2">
                  <svg class="w-6 h-6 text-blue-600 dark:text-blue-400" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                  </svg>
                  <span class="text-lg font-medium text-slate-900 dark:text-slate-25">AI Agent</span>
                </div>
                <span class="text-2xl text-gray-400 dark:text-gray-500">+</span>
                <div class="flex items-center space-x-2">
                  <svg class="w-6 h-6 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M19,3H5C3.9,3 3,3.9 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5C21,4.1 20.1,3 19,3M19,19H5V5H19V19Z"/>
                  </svg>
                  <span class="text-lg font-medium text-slate-900 dark:text-slate-25">Google Sheets</span>
                </div>
              </div>
            </div>

            <p class="text-gray-600 dark:text-gray-400 mb-6 max-w-2xl mx-auto">
              Autentikasi dengan Google untuk membuat spreadsheet otomatis yang berisi data dari AI Agent Anda. 
              Setelah autentikasi berhasil, sistem akan langsung membuat spreadsheet baru di akun Google Anda.
            </p>

            <div class="space-y-4">
              <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-25">Autentikasi</h3>
              <button
                @click="handleGoogleAuth"
                class="inline-flex items-center space-x-3 bg-green-600 hover:bg-green-700 dark:bg-green-400 dark:hover:bg-green-500 text-white px-6 py-3 rounded-lg font-medium transition-colors"
              >
                <span>Mulai Autentikasi dengan Google</span>
              </button>
              <p class="text-sm text-gray-500 dark:text-gray-400">
                Setelah autentikasi, spreadsheet akan otomatis dibuat di akun Google Anda
              </p>
            </div>
          </div>

          <div v-else-if="currentStep === 'connected'" class="py-8">
            <div class="text-center mb-8">
              <div class="w-16 h-16 bg-green-100 dark:bg-green-800 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg class="w-8 h-8 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
                </svg>
              </div>
              <h3 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-2">Berhasil Terhubung!</h3>
              <p class="text-gray-600 dark:text-gray-400">Akun Google Anda telah terhubung dan spreadsheet telah dibuat.</p>
            </div>

            <div class="bg-gray-50 dark:bg-gray-700 dark:border dark:border-gray-600 rounded-lg p-6 mb-6">
              <div class="flex items-center space-x-4">
                <div class="w-12 h-12 bg-green-100 dark:bg-green-800 rounded-full flex items-center justify-center">
                  <svg class="w-6 h-6 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
                  </svg>
                </div>
                <div class="flex-1">
                  <p class="font-medium text-slate-900 dark:text-slate-25">{{ connectedAccount?.email }}</p>
                  <p class="text-sm text-gray-600 dark:text-gray-400">Akun terkoneksi</p>
                </div>
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                  Connected
                </span>
              </div>
            </div>

            <div v-if="spreadsheetInfo" class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-6 mb-6 border border-blue-200 dark:border-blue-700">
              <div class="flex items-start space-x-4">
                <div class="w-12 h-12 bg-blue-100 dark:bg-blue-800 rounded-lg flex items-center justify-center flex-shrink-0">
                  <svg class="w-6 h-6 text-blue-600 dark:text-blue-400" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M19,3H5C3.9,3 3,3.9 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5C21,4.1 20.1,3 19,3M19,19H5V5H19V19Z"/>
                    <path d="M7,7H9V9H7V7M11,7H13V9H11V7M15,7H17V9H15V7M7,11H9V13H7V11M11,11H13V13H11V11M15,11H17V13H15V11M7,15H9V17H7V15M11,15H13V17H11V15M15,15H17V17H15V15Z"/>
                  </svg>
                </div>
                <div class="flex-1">
                  <h4 class="font-medium text-slate-900 dark:text-slate-25 mb-1">{{ spreadsheetInfo.title }}</h4>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mb-2">
                    Spreadsheet berhasil dibuat dan siap digunakan
                  </p>
                  <p class="text-xs text-gray-500 dark:text-gray-500">
                    Dibuat: {{ new Date(spreadsheetInfo.created_at).toLocaleString('id-ID') }}
                  </p>
                </div>
                <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                  Ready
                </span>
              </div>
            </div>
            <div v-else class="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-6 mb-6 text-center border border-yellow-200 dark:border-yellow-700">
              <p class="text-yellow-700 dark:text-yellow-300">
                Akun terhubung, tetapi spreadsheet belum dibuat. Ini terjadi karena booking masih kosong.
              </p>
              <button
                @click="handleGoogleAuth"
                class="mt-4 inline-flex items-center space-x-2 bg-yellow-600 hover:bg-yellow-700 dark:bg-yellow-700 dark:hover:bg-yellow-600 text-white px-4 py-2 rounded-lg font-medium transition-colors"
              >
                <span>Coba Autentikasi Ulang & Buat Spreadsheet</span>
              </button>
            </div>

            <div class="space-y-4">
              <button
                @click="openSpreadsheet"
                :disabled="!spreadsheetInfo?.url"
                :class="[
                  'w-full flex items-center justify-center space-x-2 px-6 py-3 rounded-lg font-medium transition-colors',
                  spreadsheetInfo?.url ? 'bg-blue-600 hover:bg-blue-700 dark:bg-blue-700 dark:hover:bg-blue-600 text-white' : 'bg-gray-300 dark:bg-gray-600 text-gray-500 dark:text-gray-400 cursor-not-allowed'
                ]"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>
                </svg>
                <span>Buka Google Sheets</span>
              </button>
              
              <button
                @click="disconnectAccount"
                class="w-full px-6 py-2 border border-red-300 dark:border-red-600 text-red-700 dark:text-red-400 rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
              >
                Putuskan Koneksi
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>