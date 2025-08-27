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
      <!-- Sidebar Navigation (always show) -->
      <div class="flex flex-row justify-stretch gap-2">
        <!-- Custom Tabs with SVG Icons -->
        <div class="flex flex-col gap-1 min-w-[200px] mr-4">
          <div
            v-for="tab in tabs"
            :key="tab.key"
            class="flex items-center gap-3 px-4 py-3 cursor-pointer rounded-lg transition-all duration-200 hover:bg-gray-50 dark:hover:bg-gray-800/50"
            :class="{
              'bg-woot-50 border-l-4 border-woot-500 text-woot-600 dark:bg-woot-900/50 dark:border-woot-400 dark:text-woot-400': tab.index === activeTabIndex,
              'text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-200': tab.index !== activeTabIndex,
            }"
            @click="activeTabIndex = tab.index"
          >
            <span
              :class="[
                tab.icon,
                'w-5 h-5 transition-all duration-200',
                {
                  'text-woot-600 dark:text-woot-400': tab.index === activeTabIndex,
                  'text-gray-500 dark:text-gray-400': tab.index !== activeTabIndex,
                }
              ]"
            />
            <span class="text-sm">{{ tab.name }}</span>
          </div>
        </div>

        <!-- Catalog Tab -->
        <div v-show="activeTabIndex === 0" class="w-full min-w-0">
          <div class="space-y-6">
            <!-- Google Sheets Auth Flow -->
            <div v-if="catalogStep === 'auth'" class="gap-6">
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
                          {{ $t('AGENT_MGMT.SALESBOT.CATALOG.INPUT_SHEET_TITLE') }}
                        </h3>
                        <p class="text-sm text-slate-600 dark:text-slate-400">
                          {{ $t('AGENT_MGMT.SALESBOT.CATALOG.INPUT_SHEET_DESC') }}
                        </p>
                      </div>
                    </div>
                  </div>
                  <div class="flex flex-col gap-2">
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
                      {{ syncingColumns ? $t('AGENT_MGMT.SALESBOT.CATALOG.SYNC_BUTTON_LOADING') : $t('AGENT_MGMT.SALESBOT.CATALOG.SYNC_BUTTON') }}
                    </button>
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
                      <h4 class="font-medium text-slate-900 dark:text-slate-25">{{ $t('AGENT_MGMT.SALESBOT.CATALOG.OUTPUT_SHEET_TITLE') }}</h4>
                      <p class="text-sm text-slate-600 dark:text-slate-400">{{ $t('AGENT_MGMT.SALESBOT.CATALOG.OUTPUT_SHEET_DESC') }}</p>
                    </div>
                  </div>
                  <a 
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

        <!-- Shipping Tab -->
        <div v-show="activeTabIndex === 1" class="w-full min-w-0">
          <div class="space-y-6">
            <div>
              <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.METHOD_TITLE') }}</label>
              
              <!-- Kurir Toko -->
              <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-4">
                <div class="flex items-center justify-between p-4">
                  <div>
                    <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.STORE_COURIER') }}</h3>
                    <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.DESC_STORE_COURIER') }}</p>
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
                  <!-- Store Address -->
                  <div>
                    <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.STORE_ADDRESS') }}</label>
                    <input 
                      type="text" 
                      class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                      :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.STORE_ADDRESS_PLACEHOLDER')" 
                      v-model="kurirToko.alamat" 
                    />
                  </div>


                  
                  <!-- Service Area -->
                  <div>
                    <label class="block font-medium mb-3">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.SERVICE_AREA') }}</label>
                    <div class="gap-4">
                      <!-- Radius -->
                      <div class="mb-3">
                        <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.SERVICE_RADIUS') }}</label>
                        <input 
                          type="number" 
                          min="0"
                          step="0.1"
                          class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                          :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.SERVICE_RADIUS_PLACEHOLDER')" 
                          v-model="kurirToko.radius" 
                        />
                      </div>
                      <!-- Wilayah -->
                      <div>
                        <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.SERVICE_REGION') }}</label>
                        <select 
                          v-model="kurirToko.wilayah"
                          class="w-full mb-0 p-2 text-sm  border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
                        >
                          <option value="">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.SERVICE_REGION_PLACEHOLDER') }}</option>
                          <option v-for="kecamatan in kecamatanOptions" :key="kecamatan.id" :value="kecamatan.name">
                            {{ kecamatan.name }}
                          </option>
                          <option v-for="kota in kotaOptions" :key="'city-' + kota.id" :value="kota.name">
                            {{ kota.name }}
                          </option>
                        </select>
                      </div>
                    </div>
                  </div>

                  <!-- Shipping Cost -->
                  <div>
                    <label class="block font-medium mb-3">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.SHIPPING_COST') }}</label>
                    <div class="space-y-4">
                      <!-- Flat Rate -->
                      <div>
                        <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.FLAT_RATE') }}</label>
                        <div class="relative">
                          <span class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500 text-sm">Rp</span>
                          <input 
                            type="number" 
                            min="0"
                            class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !pl-8 !pr-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                            :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.FLAT_RATE_PLACEHOLDER')" 
                            v-model="kurirToko.flatRate" 
                          />
                        </div>
                      </div>

                      <!-- Cost per Distance -->
                      <div>
                        <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.COST_PER_DISTANCE') }}</label>
                        <input 
                          type="number" 
                          min="0"
                          class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                          :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.COST_PER_DISTANCE_PLACEHOLDER')" 
                          v-model="kurirToko.biayaPerJarak" 
                        />
                      </div>

                      <!-- Free Shipping Toggle -->
                      <div class="flex items-start space-x-3">
                        <label class="inline-flex items-center cursor-pointer">
                          <input type="checkbox" v-model="kurirToko.gratisOngkir" class="sr-only peer">
                          <div
                            class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
                          </div>
                        </label>
                        <div class="flex-1">
                          <label class="block text-sm font-medium">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.FREE_SHIPPING') }}</label>
                          <!-- <p class="text-xs text-gray-500 mt-1">Aktifkan gratis ongkir dengan syarat minimal belanja</p> -->
                        </div>
                      </div>

                      <!-- Minimum Purchase (show when free shipping is enabled) -->
                      <div v-if="kurirToko.gratisOngkir" class="ml-14 transition-all duration-200 ease-in-out">
                        <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.MIN_PURCHASE') }}</label>
                        <div class="relative">
                          <span class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500 text-sm">Rp</span>
                          <input 
                            type="number" 
                            min="0"
                            class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !pl-8 !pr-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                            :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.MIN_PURCHASE_PLACEHOLDER')" 
                            v-model="kurirToko.minimalBelanja" 
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Kurir Biasa -->
              <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-4">
                <div class="flex items-center justify-between p-4">
                  <div>
                    <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.REGULAR_COURIER') }}</h3>
                    <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.DESC_REGULAR_COURIER') }}</p>
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
                    
                    <!-- Provinsi -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">Provinsi</label>
                      <div class="relative">
                        <select 
                          v-model="kurirBiasa.provinsi"
                          @change="onProvinsiChange"
                          :disabled="loadingProvinsi"
                          class="w-full mb-0 p-2 text-sm  border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
                        >
                          <option value="">{{ loadingProvinsi ? 'Loading...' : 'Pilih Provinsi' }}</option>
                          <option v-for="provinsi in provinsiOptions" :key="provinsi.id" :value="provinsi.id">
                            {{ provinsi.name }}
                          </option>
                        </select>
                      </div>
                    </div>

                    <!-- Kota/Kabupaten -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">Kota/Kabupaten</label>
                      <div class="relative">
                        <select 
                          v-model="kurirBiasa.kota"
                          @change="onKotaChange"
                          :disabled="!kurirBiasa.provinsi || loadingKota"
                          class="w-full mb-0 p-2 text-sm  border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
                        >
                          <option value="">
                            {{ !kurirBiasa.provinsi ? 'Pilih provinsi terlebih dahulu' : 
                               loadingKota ? 'Loading...' : 'Pilih Kota/Kabupaten' }}
                          </option>
                          <option v-for="kota in kotaOptions" :key="kota.id" :value="kota.id">
                            {{ kota.name }}
                          </option>
                        </select>
                      </div>
                    </div>

                    <!-- Kecamatan -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">Kecamatan</label>
                      <div class="relative">
                        <select 
                          v-model="kurirBiasa.kecamatan"
                          @change="onKecamatanChange"
                          :disabled="!kurirBiasa.kota || loadingKecamatan"
                          class="w-full mb-0 p-2 text-sm  border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
                        >
                          <option value="">
                            {{ !kurirBiasa.kota ? 'Pilih kota terlebih dahulu' : 
                               loadingKecamatan ? 'Loading...' : 'Pilih Kecamatan' }}
                          </option>
                          <option v-for="kecamatan in kecamatanOptions" :key="kecamatan.id" :value="kecamatan.id">
                            {{ kecamatan.name }}
                          </option>
                        </select>
                      </div>
                    </div>

                    <!-- Kelurahan -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">Kelurahan</label>
                      <input 
                        type="text" 
                        v-model="kurirBiasa.kelurahan"
                        placeholder="Masukkan kelurahan"
                        class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                      />
                    </div>

                    <!-- Jalan/Gang -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">Jalan/Gang</label>
                      <input 
                        type="text" 
                        v-model="kurirBiasa.jalan"
                        placeholder="Masukkan jalan/gang"
                        class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                      />
                    </div>

                    <!-- Kode Pos -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">Kode Pos</label>
                      <input 
                        type="text" 
                        v-model="kurirBiasa.kodePos"
                        placeholder="Masukkan kode pos"
                        maxlength="5"
                        pattern="[0-9]{5}"
                        class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                      />
                    </div>
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
                    
                    <!-- Calculate Shipping Cost Button -->
                    <div v-if="kurirBiasa.kurir.length > 0 && kurirBiasa.kota" class="mb-4">
                      <button
                        @click="calculateShippingCosts"
                        :disabled="loadingShippingCost"
                        class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center gap-2"
                      >
                        <svg v-if="loadingShippingCost" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" class="opacity-25"/>
                          <path fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" class="opacity-75"/>
                        </svg>
                        <span>{{ loadingShippingCost ? 'Calculating...' : 'Calculate Shipping Cost' }}</span>
                      </button>
                    </div>

                    <!-- Display Shipping Costs -->
                    <div v-if="Object.keys(kurirBiasa.shippingCosts).length > 0" class="mb-4">
                      <h4 class="font-medium mb-2">Shipping Cost Estimates:</h4>
                      <div class="space-y-2">
                        <div 
                          v-for="(costs, courier) in kurirBiasa.shippingCosts" 
                          :key="courier"
                          class="border rounded-lg p-3 bg-gray-50"
                        >
                          <h5 class="font-medium text-sm mb-1">{{ courier.toUpperCase() }}</h5>
                          <div v-if="costs.length > 0" class="space-y-1">
                            <div 
                              v-for="service in costs" 
                              :key="service.service"
                              class="flex justify-between text-xs"
                            >
                              <span>{{ service.service }} ({{ service.description }})</span>
                              <span class="font-medium">Rp {{ service.cost[0].value.toLocaleString() }}</span>
                            </div>
                          </div>
                          <div v-else class="text-xs text-gray-500">No services available</div>
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
                    <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.DESC_PICKUP_STORE') }}</p>
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
                    <div class="flex gap-2 items-center">
                      <div class="flex-1">
                        <label class="block text-sm text-gray-600 mb-1">Jam Buka</label>
                        <input 
                          type="time" 
                          v-model="ambilToko.jamBuka"
                          class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                        />
                      </div>
                      <div class="pt-6 text-gray-500">-</div>
                      <div class="flex-1">
                        <label class="block text-sm text-gray-600 mb-1">Jam Tutup</label>
                        <input 
                          type="time" 
                          v-model="ambilToko.jamTutup"
                          class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                        />
                      </div>
                    </div>
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
            
            <!-- Submit Button - Only show in Shipping tab -->
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
      </div>
    </div>
  </div>
</template>

<script setup>
import Input from 'dashboard/components-next/input/Input.vue';

import { ref, reactive, watch, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n'

// Google Sheets Auth Flow for Catalog
import googleSheetsExportAPI from '../../../../api/googleSheetsExport';

const { t } = useI18n()

// Initialize and load provinces on mount
onMounted(async () => {
  loadProvinsi();
});

const catalogStep = ref('connected'); // 'auth', 'connected', 'sheetConfig'
const catalogLoading = ref(false);
const catalogAccount = ref(null); // { email: '...', name: '...' }
const catalogSheets = reactive({ input: '', output: '' });
const notification = ref(null);
const productColumns = ref('sku,name,unit_price,quantity,deskripsi');
const syncingColumns = ref(false);

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
  // lihat contoh di configuration view, itu sudah diintegrate create sheet
  setTimeout(() => {
    catalogSheets.input = 'https://docs.google.com/spreadsheets/d/input-sheet-id';
    catalogSheets.output = 'https://docs.google.com/spreadsheets/d/output-sheet-id';
    catalogLoading.value = false;
    catalogStep.value = 'sheetConfig';
  }, 1200);
}

async function syncProductColumns() {
  try {
    syncingColumns.value = true;
    showNotification(t('AGENT_MGMT.SALESBOT.CATALOG.SYNC_INFO'), 'info');
    
    // TODO: Replace with your actual API endpoint
    // const response = await fetch('/api/sheets/sync-columns', {
    //   method: 'POST',
    //   headers: {
    //     'Content-Type': 'application/json',
    //   },
    //   body: JSON.stringify({
    //     sheetUrl: catalogSheets.input
    //   })
    // });
    // const data = await response.json();
    
    // For now, simulate API response
    setTimeout(() => {
      const syncedColumns = 'product_id,product_name,price,stock,description,category';
      productColumns.value = syncedColumns;
      showNotification(t('AGENT_MGMT.SALESBOT.CATALOG.SYNC_SUCCESS'), 'success');
      syncingColumns.value = false;
    }, 2000);
    
  } catch (error) {
    console.error('Failed to sync product columns:', error);
    showNotification(t('AGENT_MGMT.SALESBOT.CATALOG.SYNC_ERROR'), 'error');
    syncingColumns.value = false;
  }
}


const tabs = computed(() => [
  {
    key: '0',
    index: 0,
    name: t('AGENT_MGMT.SALESBOT.CATALOG.HEADER'),
    icon: 'i-lucide-package',
  },
  {
    key: '1',
    index: 1,
    name: t('AGENT_MGMT.SALESBOT.SHIPPING.HEADER'),
    icon: 'i-lucide-truck',
  },
])
const activeTabIndex = ref(0);
const catalogSheet = ref('');
const catalogDesc = ref('');

const shippingMethods = reactive({
  kurirToko: false,
  kurirBiasa: false,
  ambilToko: false
});

const kurirToko = reactive({ 
  alamat: '', 
  radius: '', 
  wilayah: '', 
  flatRate: '',
  biayaPerJarak: '',
  gratisOngkir: false,
  minimalBelanja: ''
});
const kurirBiasa = reactive({ 
  provinsi: '', 
  kota: '', 
  kecamatan: '',
  kelurahan: '', 
  jalan: '', 
  kodePos: '',
  kurir: [],
  shippingCosts: {}
});

// RajaOngkir API Configuration
const RAJA_ONGKIR_API_KEY = 'YOUR_RAJAONGKIR_API_KEY'; // Replace with your actual API key
const RAJA_ONGKIR_BASE_URL = 'https://api.rajaongkir.com/starter'; // Use 'pro' for pro account

// Location data from RajaOngkir API
const provinsiOptions = ref([]);
const kotaOptions = ref([]);
const kecamatanOptions = ref([]);
const loadingProvinsi = ref(false);
const loadingKota = ref(false);
const loadingKecamatan = ref(false);
const loadingShippingCost = ref(false);

// RajaOngkir API Headers
const getRajaOngkirHeaders = () => ({
  'key': RAJA_ONGKIR_API_KEY,
  'content-type': 'application/x-www-form-urlencoded'
});

// Load provinces from RajaOngkir
const loadProvinsi = async () => {
  try {
    loadingProvinsi.value = true;
    const response = await fetch(`${RAJA_ONGKIR_BASE_URL}/province`, {
      method: 'GET',
      headers: getRajaOngkirHeaders()
    });
    const data = await response.json();
    
    if (data.rajaongkir.status.code === 200) {
      provinsiOptions.value = data.rajaongkir.results.map(item => ({
        id: item.province_id,
        name: item.province
      }));
    } else {
      throw new Error(data.rajaongkir.status.description);
    }
  } catch (error) {
    console.error('Failed to load provinces:', error);
    showNotification('Failed to load provinces data', 'error');
    provinsiOptions.value = [
      { id: '1', name: 'Bali' },
      { id: '2', name: 'Bangka Belitung' },
      { id: '3', name: 'Banten' },
      { id: '4', name: 'Bengkulu' },
      { id: '5', name: 'DI Yogyakarta' },
      { id: '6', name: 'DKI Jakarta' },
      { id: '7', name: 'Gorontalo' },
      { id: '8', name: 'Jambi' },
      { id: '9', name: 'Jawa Barat' },
      { id: '10', name: 'Jawa Tengah' },
      { id: '11', name: 'Jawa Timur' },
      { id: '12', name: 'Kalimantan Barat' },
      { id: '13', name: 'Kalimantan Selatan' },
      { id: '14', name: 'Kalimantan Tengah' },
      { id: '15', name: 'Kalimantan Timur' },
      { id: '16', name: 'Kalimantan Utara' },
      { id: '17', name: 'Kepulauan Riau' },
      { id: '18', name: 'Lampung' },
      { id: '19', name: 'Maluku' },
      { id: '20', name: 'Maluku Utara' },
      { id: '21', name: 'Nanggroe Aceh Darussalam (NAD)' },
      { id: '22', name: 'Nusa Tenggara Barat' },
      { id: '23', name: 'Nusa Tenggara Timur' },
      { id: '24', name: 'Papua' },
      { id: '25', name: 'Papua Barat' },
      { id: '26', name: 'Riau' },
      { id: '27', name: 'Sulawesi Barat' },
      { id: '28', name: 'Sulawesi Selatan' },
      { id: '29', name: 'Sulawesi Tengah' },
      { id: '30', name: 'Sulawesi Tenggara' },
      { id: '31', name: 'Sulawesi Utara' },
      { id: '32', name: 'Sumatera Barat' },
      { id: '33', name: 'Sumatera Selatan' },
      { id: '34', name: 'Sumatera Utara' }
    ];
  } finally {
    loadingProvinsi.value = false;
  }
};

// Load cities/regencies from RajaOngkir based on selected province
const loadKota = async (provinceId) => {
  try {
    loadingKota.value = true;
    const response = await fetch(`${RAJA_ONGKIR_BASE_URL}/city?province=${provinceId}`, {
      method: 'GET',
      headers: getRajaOngkirHeaders()
    });
    const data = await response.json();
    
    if (data.rajaongkir.status.code === 200) {
      kotaOptions.value = data.rajaongkir.results.map(item => ({
        id: item.city_id,
        name: `${item.type} ${item.city_name}`,
        postal_code: item.postal_code
      }));
    } else {
      throw new Error(data.rajaongkir.status.description);
    }
  } catch (error) {
    console.error('Failed to load cities:', error);
    showNotification('Failed to load cities data', 'error');
    kotaOptions.value = [];
  } finally {
    loadingKota.value = false;
  }
};

// Calculate shipping cost using RajaOngkir
const calculateShippingCost = async (origin, destination, weight, courier) => {
  try {
    loadingShippingCost.value = true;
    const formData = new FormData();
    formData.append('origin', origin);
    formData.append('destination', destination);
    formData.append('weight', weight);
    formData.append('courier', courier.toLowerCase());

    const response = await fetch(`${RAJA_ONGKIR_BASE_URL}/cost`, {
      method: 'POST',
      headers: {
        'key': RAJA_ONGKIR_API_KEY
      },
      body: formData
    });
    
    const data = await response.json();
    
    if (data.rajaongkir.status.code === 200) {
      return data.rajaongkir.results[0]?.costs || [];
    } else {
      throw new Error(data.rajaongkir.status.description);
    }
  } catch (error) {
    console.error('Failed to calculate shipping cost:', error);
    showNotification('Failed to calculate shipping cost', 'error');
    return [];
  } finally {
    loadingShippingCost.value = false;
  }
};

// Load districts from RajaOngkir based on selected city/regency  
const loadKecamatan = async (regencyId) => {
  try {
    loadingKecamatan.value = true;
    // dummy kecamatan
    kecamatanOptions.value = [
      { id: '1', name: 'Kecamatan 1' },
      { id: '2', name: 'Kecamatan 2' },
      { id: '3', name: 'Kecamatan 3' },
    ];
  } catch (error) {
    console.error('Failed to load districts:', error);
    showNotification('Failed to load districts data', 'error');
    kecamatanOptions.value = [];
  } finally {
    loadingKecamatan.value = false;
  }
};

async function onProvinsiChange() {
  kurirBiasa.kota = '';
  kurirBiasa.kecamatan = '';
  kurirBiasa.kodePos = '';
  kotaOptions.value = [];
  kecamatanOptions.value = [];
  
  if (kurirBiasa.provinsi) {
    await loadKota(kurirBiasa.provinsi);
  }
}

async function onKotaChange() {
  kurirBiasa.kecamatan = '';
  kurirBiasa.kodePos = '';
  kecamatanOptions.value = [];
  
  // Auto-fill postal code from RajaOngkir city data
  if (kurirBiasa.kota) {
    const selectedKota = kotaOptions.value.find(kota => kota.id === kurirBiasa.kota);
    if (selectedKota && selectedKota.postal_code) {
      kurirBiasa.kodePos = selectedKota.postal_code;
    }
    await loadKecamatan(kurirBiasa.kota);
  }
}

function onKecamatanChange() {
  // add postal code refinement here if needed
  console.log('Kecamatan changed:', kurirBiasa.kecamatan);
}

// Calculate shipping costs for selected couriers
async function calculateShippingCosts() {
  if (!kurirBiasa.kota || kurirBiasa.kurir.length === 0) {
    showNotification('Please select destination city and courier services', 'error');
    return;
  }
  
  const weight = 1000; // Default 1kg, configurable
  const origin = '501'; // Default origin city ID (Yogyakarta), configurable based on store location
  
  showNotification('Calculating shipping costs...', 'info');
  
  kurirBiasa.shippingCosts = {};
  
  for (const courier of kurirBiasa.kurir) {
    try {
      const costs = await calculateShippingCost(origin, kurirBiasa.kota, weight, courier);
      kurirBiasa.shippingCosts[courier] = costs;
    } catch (error) {
      console.error(`Failed to get costs for ${courier}:`, error);
      kurirBiasa.shippingCosts[courier] = [];
    }
  }
  
  console.log('Shipping Costs:', kurirBiasa.shippingCosts);
  showNotification('Shipping costs calculated successfully', 'success');
}

// RajaOngkir supported couriers (Starter account)
const kurirOptions = [
  { label: 'JNE', id: 'jne' },
  { label: 'POS Indonesia', id: 'pos' },
  { label: 'TIKI', id: 'tiki' }
];
// For Pro account, you can add more:
// { label: 'Wahana', id: 'wahana' },
// { label: 'SiCepat', id: 'sicepat' },
// { label: 'J&T', id: 'jnt' },
// { label: 'Ninja Xpress', id: 'ninja' },
// { label: 'Lion Parcel', id: 'lion' },
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
const ambilToko = reactive({ 
  alamat: '', 
  jamBuka: '09:00', 
  jamTutup: '17:00', 
  estimasi: '' 
});



function submitConfig() {
  console.log('Katalog:', catalogSheet.value, catalogDesc.value);
  console.log('Shipping:', JSON.parse(JSON.stringify({ shippingMethods, kurirToko, kurirBiasa, ambilToko })));
  
  // You can process the data here
  const shippingData = {
    kurirToko: shippingMethods.kurirToko ? {
      alamat: kurirToko.alamat,
      radius: kurirToko.radius,
      wilayah: kurirToko.wilayah,
      flatRate: kurirToko.flatRate,
      biayaPerJarak: kurirToko.biayaPerJarak,
      gratisOngkir: kurirToko.gratisOngkir,
      minimalBelanja: kurirToko.gratisOngkir ? kurirToko.minimalBelanja : null
    } : null,
    kurirBiasa: shippingMethods.kurirBiasa ? {
      alamat: {
        provinsi: kurirBiasa.provinsi,
        kota: kurirBiasa.kota,
        kecamatan: kurirBiasa.kecamatan,
        kelurahan: kurirBiasa.kelurahan,
        jalan: kurirBiasa.jalan,
        kodePos: kurirBiasa.kodePos
      },
      kurir: kurirBiasa.kurir
    } : null,
    ambilToko: shippingMethods.ambilToko ? {
      alamat: ambilToko.alamat,
      jamOperasional: `${ambilToko.jamBuka} - ${ambilToko.jamTutup}`,
      estimasi: ambilToko.estimasi
    } : null
  };
  
  console.log('Processed Shipping Data:', shippingData);
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