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
        {{ $t('AGENT_MGMT.SALESBOT.HEADER') }}
      </h2>
      <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
        {{ $t('AGENT_MGMT.SALESBOT.HEADER_DESC') }}
      </p>
      <div class="border-b border-gray-200 dark:border-gray-700"></div>
    </div>

    <div class="space-y-6 pb-6">
      <!-- Tab Navigation -->
      <div>
        <woot-tabs
          :index="activeTabIndex"
          class="mb-4"
          @change="i => { activeTabIndex = i; }"
        >
          <woot-tabs-item
            v-for="(item, index) in tabs"
            :key="item"
            :index="index"
            :name="item"
            :show-badge="false"
          />
        </woot-tabs>
      </div>

      <!-- Catalog Tab -->
      <div v-if="activeTabIndex === 0" class="space-y-6">
        <!-- Google Sheets Auth Flow -->
        <div v-if="catalogStep === 'auth'">
          <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.CATALOG.SHEETS_TITLE') }}</label>
          <p class="text-gray-600 dark:text-gray-400">{{ $t('AGENT_MGMT.SALESBOT.CATALOG.SHEETS_AUTH_DESC') }}</p>
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
              <svg class="w-8 h-8 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
              </svg>
            </div>
            <h3 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-2">{{ $t('AGENT_MGMT.BOOKING_BOT.CONNECTED_HEADER') }}</h3>
            <p class="text-gray-600 dark:text-gray-400">{{ $t('AGENT_MGMT.BOOKING_BOT.CONNECTED_DESC') }}</p>
            <p class="mt-2 text-sm text-gray-500">{{ catalogAccount?.email }}</p>
            <button
              class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
              @click="createSheets"
              :disabled="catalogLoading"
            >
              <span v-if="catalogLoading">{{ $t('AGENT_MGMT.BOOKING_BOT.CREATE_SHEETS_LOADING') }}</span>
              <span v-else>{{ $t('AGENT_MGMT.BOOKING_BOT.CREATE_SHEETS_BTN') }}</span>
            </button>
          </div>
        </div>
        <div v-else-if="catalogStep === 'sheetConfig'">
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
                :href="catalogSheets.input" 
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
                :href="catalogSheets.output" 
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
          <!-- Product Info Columns Input -->
          <div class="mt-4">
            <label class="block font-medium mb-1">Product Info Columns</label>
            <input
              type="text"
              class="border-n-weak dark:border-n-weak block w-1/2 reset-base text-sm h-10 px-3 py-2.5 mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 text-n-slate-12 transition-all duration-500 ease-in-out"
              v-model="productColumns"
              placeholder="sku,name,unit_price,quantity,deskripsi"
            />
            <p class="text-xs text-gray-500 mt-1">Comma separated columns for product info.</p>
          </div>
        </div>
      </div>

      <!-- Shipping Tab -->
      <div v-else-if="activeTabIndex === 1" class="space-y-6">
        <div>
          <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.METHOD_TITLE') }}</label>
          
          <!-- Kurir Toko -->
          <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-4">
            <div class="flex items-center justify-between p-4">
              <div>
                <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.STORE_COURIER') }}</h3>
                <p class="text-sm text-gray-500 mt-1">Pengiriman menggunakan kurir toko</p>
              </div>
              <label class="inline-flex items-center cursor-pointer">
                <input type="checkbox" v-model="shippingMethods.kurirToko" class="sr-only peer">
                <div
                  class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
                </div>
              </label>
            </div>
            
            <div 
              v-if="shippingMethods.kurirToko" 
              class="border-t border-gray-200 dark:border-gray-700 p-4 space-y-4 transition-all duration-200 ease-in-out"
            >
              <div>
                <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.STORE_ADDRESS') }}</label>
                <input 
                  type="text" 
                  class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                  :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.STORE_ADDRESS_PLACEHOLDER')" 
                  v-model="kurirToko.alamat" 
                />
              </div>
              <div>
                <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.SERVICE_AREA') }}</label>
                <input 
                  type="text" 
                  class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                  :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.SERVICE_AREA_PLACEHOLDER')" 
                  v-model="kurirToko.area" 
                />
              </div>
              <div>
                <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.SHIPPING_COST') }}</label>
                <input 
                  type="text" 
                  class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                  :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.SHIPPING_COST_PLACEHOLDER')" 
                  v-model="kurirToko.biaya" 
                />
              </div>
            </div>
          </div>

          <!-- Kurir Biasa -->
          <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-4">
            <div class="flex items-center justify-between p-4">
              <div>
                <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.REGULAR_COURIER') }}</h3>
                <p class="text-sm text-gray-500 mt-1">Pengiriman menggunakan kurir pihak ketiga</p>
              </div>
              <label class="inline-flex items-center cursor-pointer">
                <input type="checkbox" v-model="shippingMethods.kurirBiasa" class="sr-only peer">
                <div
                  class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
                </div>
              </label>
            </div>
            
            <div 
              v-if="shippingMethods.kurirBiasa" 
              class="border-t border-gray-200 dark:border-gray-700 p-4 space-y-4 transition-all duration-200 ease-in-out"
            >
              <div>
                <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.ORIGIN_ADDRESS') }}</label>
                <input 
                  type="text" 
                  class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                  :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.ORIGIN_ADDRESS_PLACEHOLDER')" 
                  v-model="kurirBiasa.alamatAsal" 
                />
              </div>
              <div>
                <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.SELECT_COURIER') }}</label>
                    <div class="relative" ref="kurirDropdownRef">
                      <div
                        @click="isKurirDropdownOpen = !isKurirDropdownOpen"
                        class="w-full mb-[1rem] p-2 border rounded-lg bg-white cursor-pointer flex items-center justify-between hover:border-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent min-h-[40px]"
                        :class="{ 'border-gray-300': true }"
                      >
                        <div class="flex-1 text-left">
                          <span v-if="kurirBiasa.kurir.length === 0" class="text-gray-500">
                            {{ $t('AGENT_MGMT.FORM_CREATE.SELECT_TEMPLATES') }}
                          </span>
                          <div v-else class="flex flex-wrap gap-1">
                            <span
                              v-for="kurirId in kurirBiasa.kurir"
                              :key="kurirId"
                              class="inline-flex items-center px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full"
                            >
                              {{ kurirOptions.find(t => t.id === kurirId)?.label }}
                              <button
                                type="button"
                                @click.stop="toggleKurir(kurirId)"
                                class="ml-1 hover:text-green-600"
                              >
                                <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                  <path
                                    d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"
                                  />
                                </svg>
                              </button>
                            </span>
                          </div>
                        </div>
                        <svg
                          class="w-5 h-5 text-gray-400 transition-transform"
                          :class="{ 'rotate-180': isKurirDropdownOpen }"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                        </svg>
                      </div>
                      <div
                        v-show="isKurirDropdownOpen"
                        class="absolute z-10 w-full bottom-full mb-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-48 overflow-y-auto"
                      >
                        <div
                          v-for="kurir in kurirOptions"
                          :key="kurir.id"
                          @click="toggleKurir(kurir.id)"
                          class="flex items-center px-3 py-2 cursor-pointer hover:bg-gray-50"
                          :class="{ 'bg-blue-50': isKurirSelected(kurir.id) }"
                        >
                          <input
                            type="checkbox"
                            :checked="isKurirSelected(kurir.id)"
                            class="mr-3 text-blue-600 rounded focus:ring-blue-500"
                            @click.stop
                          >
                          <span class="flex-1">{{ kurir.label }}</span>
                          <svg
                            v-if="isKurirSelected(kurir.id)"
                            class="w-4 h-4 text-blue-600"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                          >
                            <path d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" />
                          </svg>
                        </div>
                      </div>
                    </div>
              </div>
            </div>
          </div>

          <!-- Ambil ke Toko -->
          <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-4">
            <div class="flex items-center justify-between p-4">
              <div>
                <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.PICKUP_STORE') }}</h3>
                <p class="text-sm text-gray-500 mt-1">Pelanggan mengambil langsung ke toko</p>
              </div>
              <label class="inline-flex items-center cursor-pointer">
                <input type="checkbox" v-model="shippingMethods.ambilToko" class="sr-only peer">
                <div
                  class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
                </div>
              </label>
            </div>
            
            <div 
              v-if="shippingMethods.ambilToko" 
              class="border-t border-gray-200 dark:border-gray-700 p-4 space-y-4 transition-all duration-200 ease-in-out"
            >
              <div>
                <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.BRANCH_ADDRESS') }}</label>
                <input 
                  type="text" 
                  class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                  :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.BRANCH_ADDRESS_PLACEHOLDER')" 
                  v-model="ambilToko.alamat" 
                />
              </div>
              <div>
                <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.OPERATION_HOURS') }}</label>
                <input 
                  type="text" 
                  class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                  :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.OPERATION_HOURS_PLACEHOLDER')" 
                  v-model="ambilToko.jam" 
                />
              </div>
              <div>
                <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.PICKUP_TIME') }}</label>
                <input 
                  type="text" 
                  class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                  :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.PICKUP_TIME_PLACEHOLDER')" 
                  v-model="ambilToko.estimasi" 
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Submit Button -->
      <div class="pt-6 pb-4">
        <button
          class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
          @click="submitConfig"
        >
          {{ $t('AGENT_MGMT.FORM_CREATE.SUBMIT') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, watch, onMounted } from 'vue';

// Google Sheets Auth Flow for Catalog
import googleSheetsExportAPI from '../../../../api/googleSheetsExport';

// Always show sheetConfig for layout preview
onMounted(() => {
  catalogStep.value = 'connected';
  catalogSheets.input = 'https://docs.google.com/spreadsheets/d/input-sheet-id';
  catalogSheets.output = 'https://docs.google.com/spreadsheets/d/output-sheet-id';
});

const catalogStep = ref('auth'); // 'auth', 'connected', 'sheetConfig'
const catalogLoading = ref(false);
const catalogAccount = ref(null); // { email: '...', name: '...' }
const catalogSheets = reactive({ input: '', output: '' });
const notification = ref(null);
const productColumns = ref('sku,name,unit_price,quantity,deskripsi');

function showNotification(message, type = 'success') {
  notification.value = { message, type };
  setTimeout(() => {
    notification.value = null;
  }, 3000);
}

async function connectGoogle() {
  try {
    catalogLoading.value = true;
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
    catalogLoading.value = false;
  }
}

async function checkAuthStatus() {
  try {
    catalogLoading.value = true;
    const response = await googleSheetsExportAPI.getStatus();
    if (response.data.authorized) {
      catalogStep.value = 'connected';
      catalogAccount.value = {
        email: response.data.email,
        name: 'Connected Account'
      };
      if (response.data.spreadsheet_url) {
        catalogSheets.input = response.data.spreadsheet_url;
        catalogSheets.output = response.data.spreadsheet_url_output || '';
        catalogStep.value = 'sheetConfig';
      } else {
        catalogSheets.input = '';
        catalogSheets.output = '';
      }
    } else {
      catalogStep.value = 'auth';
    }
  } catch (error) {
    showNotification('Failed to check authorization status. Please try again.', 'error');
    catalogStep.value = 'auth';
  } finally {
    catalogLoading.value = false;
  }
}

async function createSheets() {
  catalogLoading.value = true;
  // TODO: Call backend to create sheets if needed
  // For now, just simulate success
  setTimeout(() => {
    catalogSheets.input = 'https://docs.google.com/spreadsheets/d/input-sheet-id';
    catalogSheets.output = 'https://docs.google.com/spreadsheets/d/output-sheet-id';
    catalogLoading.value = false;
    catalogStep.value = 'sheetConfig';
  }, 1200);
}


const tabs = ref(['Katalog Produk', 'Pengaturan Pengiriman']);
const activeTabIndex = ref(0);
const catalogSheet = ref('');
const catalogDesc = ref('');

const shippingMethods = reactive({
  kurirToko: false,
  kurirBiasa: false,
  ambilToko: false
});

const kurirToko = reactive({ alamat: '', area: '', biaya: '' });
const kurirBiasa = reactive({ alamatAsal: '', kurir: [] });

// Multiselect dropdown for Kurir
const kurirOptions = [
  { label: 'JNE', id: 'JNE' },
  { label: 'TIKI', id: 'TIKI' },
  { label: 'POS', id: 'POS' },
  { label: 'Sicepat', id: 'Sicepat' },
  { label: 'Anteraja', id: 'Anteraja' },
];
const isKurirDropdownOpen = ref(false);
const kurirDropdownRef = ref(null);

function toggleKurir(kurirId) {
  const idx = kurirBiasa.kurir.indexOf(kurirId);
  if (idx > -1) {
    kurirBiasa.kurir.splice(idx, 1);
  } else {
    kurirBiasa.kurir.push(kurirId);
  }
}
function isKurirSelected(kurirId) {
  return kurirBiasa.kurir.includes(kurirId);
}

function handleKurirClickOutside(event) {
  if (kurirDropdownRef.value && !kurirDropdownRef.value.contains(event.target)) {
    isKurirDropdownOpen.value = false;
  }
}

watch(isKurirDropdownOpen, (isOpen) => {
  if (isOpen) {
    document.addEventListener('click', handleKurirClickOutside);
  } else {
    document.removeEventListener('click', handleKurirClickOutside);
  }
});
const ambilToko = reactive({ alamat: '', jam: '', estimasi: '' });

function submitConfig() {
  console.log('Katalog:', catalogSheet.value, catalogDesc.value);
  console.log('Shipping:', JSON.parse(JSON.stringify({ shippingMethods, kurirToko, kurirBiasa, ambilToko })));
  // TODO: API call integration
}
</script>

<style scoped>
.w-full {
  contain: layout style;
}

.space-y-6 > * {
  transform-origin: top;
}

.border {
  min-height: fit-content;
}
</style>