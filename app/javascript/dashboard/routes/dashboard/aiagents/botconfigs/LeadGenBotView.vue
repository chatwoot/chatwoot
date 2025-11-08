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
    <div class="pb-4 flex-shrink-0">
      <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-1">
        {{ $t('AGENT_MGMT.LEADGENBOT.HEADER') }}
      </h2>
      <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
        {{ $t('AGENT_MGMT.LEADGENBOT.HEADER_DESC') }}
      </p>
      <div class="border-b border-gray-200 dark:border-gray-700"></div>
    </div>
    
    <div class="space-y-6">
      <!-- Sidebar Navigation -->
      <div class="flex flex-row justify-stretch gap-2">
        <!-- Custom Tabs with Icons -->
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

        <!-- Tab 0: Catalog Configuration -->
        <div v-show="activeIndex === 0" class="w-full min-w-0">
          <div class="space-y-6">
            <!-- Google Sheets Auth Flow -->
            <div v-if="catalogStep === 'auth'" class="gap-6">
              <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.LEADGENBOT.CATALOG.SHEETS_TITLE') }}</label>
              <p class="text-gray-600 dark:text-gray-400">{{ $t('AGENT_MGMT.LEADGENBOT.CATALOG.SHEETS_AUTH_DESC') }}</p>
              <button
                @click="connectGoogle"
                class="inline-flex items-center space-x-3 bg-green-600 hover:bg-green-700 dark:bg-green-400 dark:hover:bg-green-500 text-white px-6 py-3 rounded-lg font-medium transition-colors"
                :disabled="catalogLoading"
              >
                <span>{{ $t('AGENT_MGMT.BOOKING_BOT.AUTH_BTN') }}</span>
              </button>
            </div>
            
            <div v-else-if="catalogStep === 'connected'" class="py-8">
              <div class="text-center mb-8">
                <div class="w-16 h-16 bg-green-100 dark:bg-green-800 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                  </svg>
                </div>
                <h3 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-2">{{ $t('AGENT_MGMT.BOOKING_BOT.CONNECTED_HEADER') }}</h3>
                <p class="text-gray-600 dark:text-gray-400">{{ $t('AGENT_MGMT.BOOKING_BOT.CONNECTED_DESC') }}</p>
                <p class="mt-2 text-sm text-gray-500">{{ catalogAccount?.email }}</p>
                <div class="flex gap-2 center justify-center mt-4">
                  <template v-if="!leadgenAuthError">
                    <button
                      class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
                      @click="createSheets"
                      :disabled="catalogLoading"
                    >
                      <span v-if="catalogLoading">{{ $t('AGENT_MGMT.BOOKING_BOT.CREATE_SHEETS_LOADING') }}</span>
                      <span v-else>{{ $t('AGENT_MGMT.BOOKING_BOT.CREATE_SHEETS_BTN') }}</span>
                    </button>

                    <button
                      class="inline-flex items-center space-x-2 border-2 border-red-600 hover:border-red-700 dark:border-red-400 dark:hover:border-red-500 text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-500 px-4 py-2 rounded-md font-medium transition-colors bg-transparent hover:bg-red-50 dark:hover:bg-red-900/20"
                      @click="disconnectGoogle"
                      :disabled="loading"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-ban">
                        <path d="M4.929 4.929 19.07 19.071"/>
                        <circle cx="12" cy="12" r="10"/>
                      </svg>
                      <span>{{ $t('AGENT_MGMT.BOOKING_BOT.DISC_BTN') }}</span>
                    </button>
                  </template>
                  <template v-else>
                    <div class="mt-3 text-red-600 text-sm flex items-center gap-2">
                      <p class="text-sm">{{ leadgenAuthError }}</p>
                      <button
                        class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
                        @click="retryAuthentication"
                        :disabled="catalogLoading"
                      >
                        <span v-if="catalogLoading">{{ $t('AGENT_MGMT.BOOKING_BOT.RETRY_AUTH_LOADING') }}</span>
                        <span v-else>{{ $t('AGENT_MGMT.BOOKING_BOT.RETRY_AUTH_BTN') }}</span>
                      </button>
                    </div>
                  </template>
                </div>
              </div>
            </div>
            
            <div v-else-if="catalogStep === 'sheetConfig'">
              <!-- Input Sheet Section - Product Catalog -->
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
                          {{ $t('AGENT_MGMT.LEADGENBOT.CATALOG.INPUT_SHEET_TITLE') }}
                        </h3>
                        <p class="text-sm text-slate-600 dark:text-slate-400">
                          {{ $t('AGENT_MGMT.LEADGENBOT.CATALOG.INPUT_SHEET_DESC') }}
                        </p>
                      </div>
                    </div>
                  </div>
                  <div v-if="catalogSheets.input && !leadgenAuthError" class="flex flex-col gap-2">
                    <a 
                      :href="catalogSheets.input" 
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
                    <div v-if="catalogSheets.input && !leadgenAuthError">
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
                        {{ syncingColumns ? $t('AGENT_MGMT.LEADGENBOT.CATALOG.SYNC_BUTTON_LOADING') : $t('AGENT_MGMT.LEADGENBOT.CATALOG.SYNC_BUTTON') }}
                      </button>
                    </div>
                    <div v-else class="text-red-600 text-sm flex items-center gap-2">
                      <button
                        @click="retryAuthentication"
                        class="inline-flex items-center space-x-2 border-2 border-green-700 hover:border-green-700 dark:border-green-700 text-green-600 hover:text-green-700 dark:text-grey-400 dark:hover:text-grey-500 pr-4 py-2 rounded-md font-medium transition-colors bg-transparent hover:bg-grey-50 dark:hover:bg-grey-900/20"
                        :disabled="loading"
                      >
                        <span v-if="loading">{{ $t('AGENT_MGMT.BOOKING_BOT.RETRY_AUTH_LOADING') }}</span>
                        <span>{{ $t('AGENT_MGMT.BOOKING_BOT.RETRY_AUTH_BTN') }}</span>
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

              <!-- Output Sheet Section - Lead Tracking -->
              <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-6 mb-6 border border-blue-200 dark:border-blue-800">
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                      <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                      </svg>
                    </div>
                    <div>
                      <h4 class="font-medium text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.LEADGENBOT.CATALOG.OUTPUT_SHEET_TITLE') }}</h4>
                      <p class="text-sm text-slate-600 dark:text-slate-400">{{ $t('AGENT_MGMT.LEADGENBOT.CATALOG.OUTPUT_SHEET_DESC') }}</p>
                    </div>
                  </div>
                  <a 
                    v-if="catalogSheets.output && !leadgenAuthError"
                    :href="catalogSheets.output" 
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

        <!-- Tab 1: File Knowledge Sources -->
        <div v-show="activeIndex === 1" class="w-full min-w-0">
          <FileKnowledgeSources 
            :data="data" 
            context="lead_generation"
          />
        </div>

        <!-- Tab 2: QnA Knowledge Sources -->
        <div v-show="activeIndex === 2" class="w-full min-w-0">
          <QnaKnowledgeSources :data="data" />
        </div>
        
        <!-- Cart Configuration Tab -->
        <div v-show="activeIndex === 3" class="w-full">
          <div class="flex flex-row gap-4">
            <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-6">
              <div class="space-y-4">
                <div>
                  <!-- Cart Toggle -->
                  <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-4">
                    <div class="flex items-center justify-between p-4">
                      <div class="flex items-center">
                        <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="stroke-green-600 dark:stroke-white i-lucide-tag">
                            <circle cx="8" cy="21" r="1"/>
                            <circle cx="19" cy="21" r="1"/>
                            <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"/>
                          </svg> 
                        </div>
                        <div>
                          <h3 class="font-medium">{{ $t('AGENT_MGMT.LEADGENBOT.CLASSIFICATION.ENABLE_TITLE') }}</h3>
                          <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.LEADGENBOT.CLASSIFICATION.ENABLE_DESC') }}</p>
                        </div>
                      </div>
                      <label class="inline-flex items-center cursor-pointer">
                        <input type="checkbox" v-model="classificationEnabled" class="sr-only peer">
                        <div
                          class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
                        </div>
                      </label>
                    </div>
                    
                    <!-- Cart Status Info -->
                    <div class="border-t border-gray-200 dark:border-gray-700 p-4">
                      <div v-if="classificationEnabled" class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-3">
                        <div class="flex items-start">
                          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="stroke-green-600 dark:stroke-green-400 mt-0.5 mr-2 flex-shrink-0">
                            <path d="M9 12l2 2 4-4"/>
                            <circle cx="12" cy="12" r="10"/>
                          </svg>
                          <div>
                            <p class="text-sm font-medium text-green-800 dark:text-green-200">
                              {{ $t('AGENT_MGMT.LEADGENBOT.CLASSIFICATION.ENABLED_STATUS') }}
                            </p>
                            <p class="text-sm text-green-600 dark:text-green-300 mt-1">
                              {{ $t('AGENT_MGMT.LEADGENBOT.CLASSIFICATION.ENABLED_DESC_DETAIL') }}
                            </p>
                          </div>
                        </div>
                      </div>
                      
                      <div v-else class="bg-gray-50 dark:bg-gray-900/20 border border-gray-200 dark:border-gray-700 rounded-lg p-3">
                        <div class="flex items-start">
                          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="stroke-gray-500 dark:stroke-gray-400 mt-0.5 mr-2 flex-shrink-0">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="15" y1="9" x2="9" y2="15"/>
                            <line x1="9" y1="9" x2="15" y2="15"/>
                          </svg>
                          <div>
                            <p class="text-sm font-medium text-gray-700 dark:text-gray-300">
                              {{ $t('AGENT_MGMT.LEADGENBOT.CLASSIFICATION.DISABLED_STATUS') }}
                            </p>
                            <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
                              {{ $t('AGENT_MGMT.LEADGENBOT.CLASSIFICATION.DISABLED_DESC_DETAIL') }}
                            </p>
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
                  <div class="w-10 h-10 flex-shrink-0 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="i-lucide-tag w-5 h-5 text-green-600 dark:text-green-400">
                        <circle cx="8" cy="21" r="1"/>
                        <circle cx="19" cy="21" r="1"/>
                        <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"/>
                      </svg>
                  </div>
                  <div>
                    <h3 class="font-semibold text-slate-700 dark:text-slate-300">{{ $t('AGENT_MGMT.LEADGENBOT.CLASSIFICATION.HEADER') }}</h3>
                    <p class="text-sm text-slate-500 dark:text-slate-400">{{ $t('AGENT_MGMT.LEADGENBOT.CLASSIFICATION.HEADER_DESC') }}</p>
                  </div>
                </div>
                
                <Button
                  class="w-full"
                  :is-loading="isSaving"
                  :disabled="isSaving"
                  @click="() => submitClassificationConfig()"
                >
                  <span class="flex items-center gap-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                    </svg>
                    {{ $t('AGENT_MGMT.FORM_CREATE.SUBMIT') }}
                  </span>
                </Button>
              </div>
            </div>
          </div>
        </div>       
        <!-- Tab 4: Priorities -->
        <div v-show="activeIndex === 4" class="w-full">
          <PrioritiesTab 
            v-if="data"
            :data="data" 
            agent-type="lead_generation"
            :default-priorities="defaultLeadPriorities"
          />
          <div v-else class="flex items-center justify-center py-12">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-green-600"></div>
          </div>
        </div>

        <!-- Custom Numbering Content -->
        <div v-show="activeIndex === 5" class="w-full">
          <CustomNumberingTab :data="data" />
        </div>

      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, watch, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import Button from 'dashboard/components-next/button/Button.vue';
import FileKnowledgeSources from '../knowledge-sources/FileKnowledgeSources.vue'
import QnaKnowledgeSources from '../knowledge-sources/QnaKnowledgeSources.vue'
import PrioritiesTab from './cs-bot-tabs/PrioritiesTab.vue'
import googleSheetsExportAPI from '../../../../api/googleSheetsExport'
import aiAgents from '../../../../api/aiAgents'
import { useAlert } from 'dashboard/composables';
import CustomNumberingTab from './cs-bot-tabs/CustomNumberingTab.vue';

const { t } = useI18n()

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
  googleSheetsAuth: {
    type: Object,
    required: true,
  },
})

const defaultLeadPriorities = [
  { 
    name: 'Tidak Tertarik', 
    condition: `- Pelanggan menolak produk setelah penjelasan
- Budget tidak cocok dan tidak bisa dinego
- Tidak responsif atau ingin mengakhiri percakapan
- Sudah punya produk serupa dan puas
- **Closing**: "Baik kak, terima kasih atas waktunya. Kalau ada yang berubah pikiran, jangan ragu kontak kami ya!"` 
  },
  { 
    name: 'Tertarik dan Butuh Follow Up', 
    condition: `- Pelanggan tertarik tapi bilang "pikir dulu", "diskusi sama yang lain"
- Belum ada budget/timeline yang jelas
- Minta dihubungi lagi nanti, butuh approval atasan/keluarga
- Tertarik tapi belum siap commit
- **Closing**: "Oke kak, kami catat dulu datanya ya. Tim admin kami akan follow up dalam 1x24 jam untuk update info terbaru!"`
  },
  { 
    name: 'Tertarik dan Mau Buat Janji', 
    condition: `- Pelanggan antusias dan mau langsung diskusi harga/detail
- Siap set jadwal meeting/konsultasi/demo
- Sudah qualified (budget, timeline, decision maker jelas)
- Menunjukkan urgency tinggi untuk segera action`
  }
];

// Helper function to get agent ID by type
function getAgentIdByType(type) {
  const flowData = props.data?.display_flow_data;
  if (!flowData?.agents_config) return null;
  
  const agent = flowData.agents_config.find(config => config.type === type);
  return agent?.agent_id || null;
}

// Computed property to get leadgen agent ID
const leadgenAgentId = computed(() => {
  return getAgentIdByType('lead_generation');
});

// Define all 5 tabs for LeadGen Bot
const tabs = computed(() => [
  {
    key: '0',
    index: 0,
    name: 'Katalog Produk',
    icon: 'i-lucide-package',
  },
  {
    key: '1',
    index: 1,
    name: 'File',
    icon: 'i-lucide-folder',
  },
  {
    key: '2',
    index: 2,
    name: 'QnA',
    icon: 'i-lucide-help-circle',
  },
  {
    key: '3',
    index: 3,
    name: 'Klasifikasi',
    icon: 'i-lucide-tag',
  },
  {
    key: '4',
    index: 4,
    name: 'Prioritas',
    icon: 'i-lucide-star',
  },
  {
    key: '5',
    index: 5,
    name: 'Penomoran Otomatis',
    icon: 'i-lucide-notebook-tabs',
  },
])

const activeIndex = ref(0)
const loading = ref(false)
const syncingColumns = ref(false)
const notification = ref(null)

// Catalog step management
const catalogStep = computed(() => {
  // If authenticated but no leadgen spreadsheets yet, show 'connected' step
  if (props.googleSheetsAuth.step === 'sheetConfig') {
    const leadgenSheets = props.googleSheetsAuth.spreadsheetUrls.lead_generation;
    if (!leadgenSheets?.input && !leadgenSheets?.output) {
      return 'connected';
    }
  }
  return props.googleSheetsAuth.step;
});

const catalogLoading = computed(() => props.googleSheetsAuth.loading);
const catalogAccount = computed(() => props.googleSheetsAuth.account);
const catalogSheets = computed(() => props.googleSheetsAuth.spreadsheetUrls.lead_generation);
const isSaving = ref(false);
// Computed property for leadgen-specific auth error
const leadgenAuthError = computed(() => {
  const error = props.googleSheetsAuth.error;
  if (!error) return null;
  
  // Don't show error if it's just about missing spreadsheets
  if (error.includes('not found') || error.includes('404')) {
    return null;
  }
  
  // Show error for actual auth/permission issues
  if (error.includes('authentication') || error.includes('permission') || error.includes('unauthorized')) {
    return error;
  }
  
  return null;
});

// Watch for auth errors
watch(leadgenAuthError, (newError) => {
  if (newError) {
    showNotification(t('AGENT_MGMT.AUTH_ERROR'), 'error');
  } else {
    notification.value = null;
  }
}, { immediate: true });

function showNotification(message, type = 'success') {
  notification.value = { message, type };
  setTimeout(() => {
    notification.value = null;
  }, 3000);
}

async function connectGoogle() {
  try {
    props.googleSheetsAuth.loading = true;
    const response = await googleSheetsExportAPI.getAuthorizationUrl();
    if (response.data.authorization_url) {
      showNotification('Opening Google authentication...', 'info');
      window.location.href = response.data.authorization_url;
    } else {
      showNotification('Failed to get authorization URL', 'error');
    }
  } catch (error) {
    showNotification('Authentication failed', 'error');
  } finally {
    props.googleSheetsAuth.loading = false;
  }
}

function retryAuthentication() {
  connectGoogle();
}

function disconnectGoogle() {
  googleSheetsExportAPI.disconnectAccount()
    .then(() => {
      props.googleSheetsAuth.step = 'auth';
      props.googleSheetsAuth.account = null;
      props.googleSheetsAuth.spreadsheetUrls.lead_generation = { input: null, output: null };
      props.googleSheetsAuth.error = null;
      showNotification('Disconnected successfully', 'success');
    })
    .catch((error) => {
      console.error('Disconnect failed:', error);
      showNotification('Failed to disconnect', 'error');
    });
}

async function createSheets() {
  props.googleSheetsAuth.loading = true;
  try {
    const flowData = props.data.display_flow_data;
    const payload = {
      account_id: parseInt(flowData.account_id, 10),
      agent_id: leadgenAgentId.value,
      type: 'lead_generation',
    };

    const response = await googleSheetsExportAPI.createSpreadsheet(payload);

    props.googleSheetsAuth.spreadsheetUrls.lead_generation.input = response.data.input_spreadsheet_url;
    props.googleSheetsAuth.spreadsheetUrls.lead_generation.output = response.data.output_spreadsheet_url;
    props.googleSheetsAuth.step = 'sheetConfig';
    showNotification('Sheets created successfully!', 'success');
  } catch (error) {
    console.error('Create sheets error:', error);
    showNotification('Failed to create sheets', 'error');
  } finally {
    props.googleSheetsAuth.loading = false;
  }
}

// Helper function to split text into chunks
function splitTextIntoChunks(text, maxChunkSize = 19000) {
  const chunks = [];
  let currentChunk = '';
  const lines = text.split('\n');
  
  for (const line of lines) {
    if (currentChunk.length + line.length + 1 > maxChunkSize) {
      if (currentChunk.trim()) {
        chunks.push(currentChunk.trim());
        currentChunk = line;
      } else {
        chunks.push(line.substring(0, maxChunkSize - 100) + '...[truncated]');
        currentChunk = '';
      }
    } else {
      currentChunk += (currentChunk ? '\n' : '') + line;
    }
  }
  
  if (currentChunk.trim()) {
    chunks.push(currentChunk.trim());
  }
  
  return chunks;
}

async function syncProductColumns() {
  try {
    syncingColumns.value = true;
    showNotification(t('AGENT_MGMT.LEADGENBOT.CATALOG.SYNC_INFO'), 'info');
    
    const flowData = props.data.display_flow_data;
    const payload = {
      account_id: parseInt(flowData.account_id, 10),
      agent_id: leadgenAgentId.value,
      type: 'lead_generation',
    };
    
    const syncDataResponse = await googleSheetsExportAPI.syncSpreadsheet(payload);
    
    // Get existing knowledge sources
    let knowledgeSources = [];
    try {
      const knowledgeResponse = await aiAgents.getKnowledgeSources(props.data.id);
      knowledgeSources = knowledgeResponse.data?.knowledge_source_texts || [];
    } catch (error) {
      knowledgeSources = [];
    }
    
    // Find and delete all knowledge sources with tab = 4 (product catalog for leadgen)
    let existingKnowledgeTab4 = knowledgeSources.filter(k => k.tab === 4);
    
    for (const knowledge of existingKnowledgeTab4) {
      try {
        await aiAgents.deleteKnowledgeText(props.data.id, knowledge.id);
      } catch (error) {
        console.warn('Failed to delete existing knowledge:', error);
      }
    }
    
    // Split content into chunks
    const rawData = syncDataResponse.data.data;
    const chunks = splitTextIntoChunks(rawData, 19000);
    
    console.log(`Splitting product data into ${chunks.length} chunks`);
    
    // Create knowledge sources for each chunk
    for (let i = 0; i < chunks.length; i++) {
      const chunkText = chunks.length > 1 
        ? `[Product Catalog - Part ${i + 1}/${chunks.length}]\n\n${chunks[i]}`
        : chunks[i];
      
      try {
        const createRequest = {
          id: null,
          tab: 4,
          text: chunkText,
        };
        await aiAgents.addKnowledgeText(props.data.id, createRequest);
        
        if (i < chunks.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 500));
        }
      } catch (error) {
        console.error(`Failed to create knowledge chunk ${i + 1}:`, error);
        showNotification(`Failed to save chunk ${i + 1}`, 'error');
      }
    }
    
    const message = chunks.length > 1 
      ? `${t('AGENT_MGMT.LEADGENBOT.CATALOG.SYNC_SUCCESS')} (${chunks.length} chunks)`
      : t('AGENT_MGMT.LEADGENBOT.CATALOG.SYNC_SUCCESS');
    
    showNotification(message, 'success');
  } catch (error) {
    console.error('Sync error:', error);
    showNotification(t('AGENT_MGMT.LEADGENBOT.CATALOG.SYNC_ERROR'), 'error');
  } finally {
    syncingColumns.value = false;
  }
}
const classificationEnabled = ref(false);
// Submit Cart Configuration
async function submitClassificationConfig() {
  if (isSaving.value) return;

  try {
    isSaving.value = true;

    // Save to backend
    let flowData = props.data.display_flow_data;
    const agentIndex = flowData.enabled_agents.indexOf('lead_generation');
    
    if (agentIndex === -1) {
      useAlert(t('AGENT_MGMT.WEBSITE_SETTINGS.AGENT_NOT_FOUND'))
      return;
    }

    // Initialize configurations if not exists
    if (!flowData.agents_config[agentIndex].configurations) {
      flowData.agents_config[agentIndex].configurations = {};
    }
    
    // Update cart configuration
    flowData.agents_config[agentIndex].configurations.classification_enabled = classificationEnabled.value;

    const payload = {
      flow_data: flowData,
    };

    await aiAgents.updateAgent(props.data.id, payload);

    // Update local props data to maintain state after update
    updateLocalPropsData('classification_enabled', classificationEnabled.value);

    useAlert(t('AGENT_MGMT.WEBSITE_SETTINGS.SAVE_SUCCESS'));
  } catch (error) {
    useAlert(t('AGENT_MGMT.WEBSITE_SETTINGS.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
}
// Function to update local props data after successful save
function updateLocalPropsData(configType, configData) {
  try {
    const flowData = props.data.display_flow_data;
    const agentIndex = flowData.enabled_agents.indexOf('lead_generation');
    if (agentIndex === -1) return;
    
    // Initialize configurations if not exists
    if (!flowData.agents_config[agentIndex].configurations) {
      flowData.agents_config[agentIndex].configurations = {};
    }
    
    // Update the specific configuration
    flowData.agents_config[agentIndex].configurations[configType] = configData;
    
  } catch (error) {
  }
}
function loadSavedConfiguration() {
  try {
    const flowData = props.data?.display_flow_data;
    if (!flowData) {
      console.log('No flow data available');
      return;
    }
    
    const agentIndex = flowData.enabled_agents?.indexOf('lead_generation');
    
    if (agentIndex === -1) {
      console.log('Lead generation agent not found');
      return;
    }
    
    const config = flowData.agents_config?.[agentIndex]?.configurations;
    
    if (!config) {
      console.log('No configuration found');
      return;
    }

    // Load Classification Configuration
    if (config.classification_enabled !== undefined) {
      classificationEnabled.value = config.classification_enabled;
      console.log('Loaded classification_enabled:', classificationEnabled.value);
    } else {
      console.log('classification_enabled not found in config');
    }
    
  } catch (error) {
    console.error('Error loading configuration:', error);
  }
}

onMounted(async() => {
  loadSavedConfiguration();
});

watch(
  () => props.data,
  (newData) => {
    if (newData && newData.display_flow_data) {
      loadSavedConfiguration();
    }
  },
  { immediate: true, deep: true }
);
</script>

<style scoped>
.custom-tab {
  transition: all 0.2s ease-in-out;
}

.custom-tab:hover {
  background-color: #f8fafc;
}

.custom-tab.active {
  background-color: #f0f9ff;
  border-left: 4px solid #3b82f6;
}
</style>