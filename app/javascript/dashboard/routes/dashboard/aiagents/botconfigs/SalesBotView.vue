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
          <div class="flex flex-row gap-4">
            <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-6">
              <div class="space-y-4">
                <div>
                  <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.METHOD_TITLE') }}</label>
              
              <!-- Kurir Toko -->
              <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-4">
                <div class="flex items-center justify-between p-4">
                  <div class="flex items-center">
                    <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                      <svg width="24" height="24" fill="none" viewBox="0 0 24 24"
                        xmlns="http://www.w3.org/2000/svg">
                        <path class="fill-green-600 dark:fill-white"
                          d="M3 5.25A2.25 2.25 0 0 1 5.25 3h13.5A2.25 2.25 0 0 1 21 5.25v13.5a.75.75 0 0 1-.75.75h-1v-8.25c0-.11-.012-.219-.036-.325l-.739-3.326a3 3 0 0 0-2.928-2.349H8.453A3 3 0 0 0 5.525 7.6l-.74 3.325a1.5 1.5 0 0 0-.035.325v8.25h-1a.75.75 0 0 1-.75-.75V5.25Z"
                          fill="currentColor" />
                        <path class="fill-green-600 dark:fill-white"
                          d="M8.453 6a2.25 2.25 0 0 0-2.196 1.762l-.74 3.325a.75.75 0 0 0-.017.163v9c0 .966.784 1.75 1.75 1.75h1.5a1.75 1.75 0 0 0 1.75-1.75v-.75h3v.75c0 .966.784 1.75 1.75 1.75h1.5a1.75 1.75 0 0 0 1.75-1.75v-9a.748.748 0 0 0-.018-.163l-.739-3.325A2.25 2.25 0 0 0 15.547 6H8.453Zm-.732 2.087a.75.75 0 0 1 .732-.587h7.094a.75.75 0 0 1 .732.587l.536 2.413h-9.63l.536-2.413ZM7 20.25v-.75h2v.75a.25.25 0 0 1-.25.25h-1.5a.25.25 0 0 1-.25-.25Zm10-.75v.75a.25.25 0 0 1-.25.25h-1.5a.25.25 0 0 1-.25-.25v-.75h2Zm-6.25-3h2.5a.75.75 0 0 1 0 1.5h-2.5a.75.75 0 0 1 0-1.5Zm-.745-2.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0ZM15 15a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"
                          fill="currentColor" />
                      </svg>
                    </div>
                    <div>
                      <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.STORE_COURIER') }}</h3>
                      <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.DESC_STORE_COURIER') }}</p>
                    </div>
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

                  <!-- Google Maps Integration -->
                  <div>
                    <label class="block font-medium mb-2">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.MAP_LOCATION') }}</label>
                    <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.MAP_INSTRUCTION') }}</p>
                    
                    <!-- Map Container -->
                    <div class="relative bg-gray-100 rounded-lg overflow-hidden border border-gray-200 dark:border-gray-600">
                      <div 
                        ref="mapRef"
                        class="w-full h-64"
                        style="min-height: 256px;"
                      ></div>
                      
                      <!-- Loading Overlay -->
                      <div v-if="!kurirToko.mapLoaded" class="absolute inset-0 bg-gray-100 dark:bg-gray-800 flex items-center justify-center">
                        <div class="text-center">
                          <svg class="animate-spin h-8 w-8 text-blue-600 mx-auto mb-2" fill="none" viewBox="0 0 24 24">
                            <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" class="opacity-25"/>
                            <path fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" class="opacity-75"/>
                          </svg>
                          <p class="text-sm text-gray-600 dark:text-gray-400">Loading map...</p>
                        </div>
                      </div>
                    </div>

                    <!-- Coordinates Display -->
                    <div class="grid grid-cols-2 gap-4 mt-3">
                      <div>
                        <label class="block text-xs font-medium text-gray-500 mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.LATITUDE') }}</label>
                        <input 
                          type="number" 
                          step="0.000001"
                          v-model="kurirToko.latitude"
                          class="w-full text-xs px-2 py-1 border border-gray-300 rounded bg-gray-50 text-gray-700 cursor-not-allowed"
                          readonly
                        />
                      </div>
                      <div>
                        <label class="block text-xs font-medium text-gray-500 mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.LONGITUDE') }}</label>
                        <input 
                          type="number" 
                          step="0.000001"
                          v-model="kurirToko.longitude"
                          class="w-full text-xs px-2 py-1 border border-gray-300 rounded bg-gray-50 text-gray-700 cursor-not-allowed"
                          readonly
                        />
                      </div>
                    </div>
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
                  <div class="flex items-center">
                    <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="stroke-green-600 dark:stroke-white lucide lucide-package-open-icon lucide-package-open"><path d="M12 22v-9"/><path d="M15.17 2.21a1.67 1.67 0 0 1 1.63 0L21 4.57a1.93 1.93 0 0 1 0 3.36L8.82 14.79a1.655 1.655 0 0 1-1.64 0L3 12.43a1.93 1.93 0 0 1 0-3.36z"/><path d="M20 13v3.87a2.06 2.06 0 0 1-1.11 1.83l-6 3.08a1.93 1.93 0 0 1-1.78 0l-6-3.08A2.06 2.06 0 0 1 4 16.87V13"/><path d="M21 12.43a1.93 1.93 0 0 0 0-3.36L8.83 2.2a1.64 1.64 0 0 0-1.63 0L3 4.57a1.93 1.93 0 0 0 0 3.36l12.18 6.86a1.636 1.636 0 0 0 1.63 0z"/></svg>
                    </div>
                    <div>
                      <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.REGULAR_COURIER') }}</h3>
                      <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.DESC_REGULAR_COURIER') }}</p>
                    </div>
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
                      <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.PROVINCE_LABEL') }}</label>
                      <div class="relative dropdown-container" ref="provinsiDropdownRef">
                        <div
                          class="dropdown-input w-full mb-0 p-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed cursor-pointer flex items-center justify-between"
                          :class="{ 'disabled:bg-gray-100 disabled:cursor-not-allowed': loadingProvinsi }"
                          @click="toggleProvinsiDropdown"
                        >
                          <input
                            v-model="provinsiSearchQuery"
                            :placeholder="selectedProvinsiName || (loadingProvinsi ? 'Loading...' : $t('AGENT_MGMT.SALESBOT.SHIPPING.PROVINCE_LABEL_PLACEHOLDER'))"
                            class="flex-1 bg-transparent outline-none"
                            :disabled="loadingProvinsi"
                            @input="onProvinsiSearch"
                            @click.stop
                            @focus="isProvinsiDropdownOpen = true"
                          />
                          <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                          </svg>
                        </div>
                        <div
                          v-show="isProvinsiDropdownOpen"
                          class="dropdown-menu absolute z-[9999] w-full top-full mt-1 bg-white dark:bg-slate-800 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-hidden"
                        >
                          <div class="max-h-60 overflow-y-auto scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100 dark:scrollbar-thumb-gray-600 dark:scrollbar-track-gray-800">
                            <div v-if="loadingProvinsi" class="px-3 py-2 text-sm text-gray-500">
                              Loading provinces...
                            </div>
                            <div
                              v-for="provinsi in filteredProvinsiOptions"
                              :key="provinsi.id"
                              class="dropdown-item px-3 py-2 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer text-sm"
                              @click="selectProvinsi(provinsi)"
                            >
                              {{ provinsi.name }}
                            </div>
                            <div v-if="!loadingProvinsi && filteredProvinsiOptions.length === 0" class="px-3 py-2 text-sm text-gray-500">
                              No provinces found
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Kota/Kabupaten -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.CITY_LABEL') }}</label>
                      <div class="relative dropdown-container" ref="kotaDropdownRef">
                        <div
                          class="dropdown-input w-full mb-0 p-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed cursor-pointer flex items-center justify-between"
                          :class="{ 'disabled:bg-gray-100 disabled:cursor-not-allowed': !kurirBiasa.provinsi || loadingKota }"
                          @click="toggleKotaDropdown"
                        >
                          <input
                            v-model="kotaSearchQuery"
                            :placeholder="selectedKotaName || (!kurirBiasa.provinsi ? $t('AGENT_MGMT.SALESBOT.SHIPPING.CITY_SELECT_FIRST') : loadingKota ? 'Loading...' : $t('AGENT_MGMT.SALESBOT.SHIPPING.CITY_LABEL_PLACEHOLDER'))"
                            class="flex-1 bg-transparent outline-none"
                            :disabled="!kurirBiasa.provinsi || loadingKota"
                            @input="onKotaSearch"
                            @click.stop
                            @focus="isKotaDropdownOpen = true"
                          />
                          <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                          </svg>
                        </div>
                        <div
                          v-show="isKotaDropdownOpen"
                          class="dropdown-menu absolute z-[9999] w-full top-full mt-1 bg-white dark:bg-slate-800 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-hidden"
                        >
                          <div class="max-h-60 overflow-y-auto scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100 dark:scrollbar-thumb-gray-600 dark:scrollbar-track-gray-800">
                            <div v-if="loadingKota" class="px-3 py-2 text-sm text-gray-500">
                              Loading cities...
                            </div>
                            <div
                              v-for="kota in filteredKotaOptions"
                              :key="kota.id"
                              class="dropdown-item px-3 py-2 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer text-sm"
                              @click="selectKota(kota)"
                            >
                              {{ kota.name }}
                            </div>
                            <div v-if="!loadingKota && filteredKotaOptions.length === 0 && kurirBiasa.provinsi" class="px-3 py-2 text-sm text-gray-500">
                              No cities found
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Kecamatan -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.SUBDISTRICT_LABEL') }}</label>
                      <div class="relative dropdown-container" ref="kecamatanDropdownRef">
                        <div
                          class="dropdown-input w-full mb-0 p-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed cursor-pointer flex items-center justify-between"
                          :class="{ 'disabled:bg-gray-100 disabled:cursor-not-allowed': !kurirBiasa.kota || loadingKecamatan }"
                          @click="toggleKecamatanDropdown"
                        >
                          <input
                            v-model="kecamatanSearchQuery"
                            :placeholder="selectedKecamatanName || (!kurirBiasa.kota ? $t('AGENT_MGMT.SALESBOT.SHIPPING.SUBDISTRICT_SELECT_FIRST') : loadingKecamatan ? 'Loading...' : $t('AGENT_MGMT.SALESBOT.SHIPPING.SUBDISTRICT_LABEL_PLACEHOLDER'))"
                            class="flex-1 bg-transparent outline-none"
                            :disabled="!kurirBiasa.kota || loadingKecamatan"
                            @input="onKecamatanSearch"
                            @click.stop
                            @focus="isKecamatanDropdownOpen = true"
                          />
                          <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                          </svg>
                        </div>
                        <div
                          v-show="isKecamatanDropdownOpen"
                          class="dropdown-menu absolute z-[9999] w-full top-full mt-1 bg-white dark:bg-slate-800 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-hidden"
                        >
                          <div class="max-h-60 overflow-y-auto scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100 dark:scrollbar-thumb-gray-600 dark:scrollbar-track-gray-800">
                            <div v-if="loadingKecamatan" class="px-3 py-2 text-sm text-gray-500">
                              Loading subdistricts...
                            </div>
                            <div
                              v-for="kecamatan in filteredKecamatanOptions"
                              :key="kecamatan.id"
                              class="dropdown-item px-3 py-2 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer text-sm"
                              @click="selectKecamatan(kecamatan)"
                            >
                              {{ kecamatan.name }}
                            </div>
                            <div v-if="!loadingKecamatan && filteredKecamatanOptions.length === 0 && kurirBiasa.kota" class="px-3 py-2 text-sm text-gray-500">
                              No subdistricts found
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Kelurahan -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.WARD_LABEL') }}</label>
                      <div class="relative dropdown-container" ref="kelurahanDropdownRef">
                        <div
                          class="dropdown-input w-full mb-0 p-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed cursor-pointer flex items-center justify-between"
                          :class="{ 'disabled:bg-gray-100 disabled:cursor-not-allowed': !kurirBiasa.kecamatan || loadingKelurahan }"
                          @click="toggleKelurahanDropdown"
                        >
                          <input
                            v-model="kelurahanSearchQuery"
                            :placeholder="selectedKelurahanName || (!kurirBiasa.kecamatan ? $t('AGENT_MGMT.SALESBOT.SHIPPING.WARD_SELECT_FIRST') : loadingKelurahan ? 'Loading...' : $t('AGENT_MGMT.SALESBOT.SHIPPING.WARD_LABEL_PLACEHOLDER'))"
                            class="flex-1 bg-transparent outline-none"
                            :disabled="!kurirBiasa.kecamatan || loadingKelurahan"
                            @input="onKelurahanSearch"
                            @click.stop
                            @focus="isKelurahanDropdownOpen = true"
                          />
                          <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                          </svg>
                        </div>
                        <div
                          v-show="isKelurahanDropdownOpen"
                          class="dropdown-menu absolute z-[9999] w-full top-full mt-1 bg-white dark:bg-slate-800 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-hidden"
                        >
                          <div class="max-h-60 overflow-y-auto scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100 dark:scrollbar-thumb-gray-600 dark:scrollbar-track-gray-800">
                            <div v-if="loadingKelurahan" class="px-3 py-2 text-sm text-gray-500">
                              Loading villages...
                            </div>
                            <div
                              v-for="kelurahan in filteredKelurahanOptions"
                              :key="kelurahan.id"
                              class="dropdown-item px-3 py-2 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer text-sm"
                              @click="selectKelurahan(kelurahan)"
                            >
                              {{ kelurahan.name }}
                            </div>
                            <div v-if="!loadingKelurahan && filteredKelurahanOptions.length === 0 && kurirBiasa.kecamatan" class="px-3 py-2 text-sm text-gray-500">
                              No villages found
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Jalan/Gang -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.STREET_LABEL') }}</label>
                      <input 
                        type="text" 
                        v-model="kurirBiasa.jalan"
                        :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.STREET_LABEL_PLACEHOLDER')" 
                        class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                      />
                    </div>

                    <!-- Kode Pos -->
                    <div class="mb-3">
                      <label class="block text-sm font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.ZIP_CODE_LABEL') }}</label>
                      <input 
                        type="text" 
                        v-model="kurirBiasa.kodePos"
                        :placeholder="$t('AGENT_MGMT.SALESBOT.SHIPPING.ZIP_CODE_LABEL_PLACEHOLDER')"
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
                        class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-auto !px-3 !py-2.5 !mb-4 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out cursor-pointer flex items-center justify-between min-h-[40px]"
                      >
                        <div class="flex-1 text-left">
                          <span v-if="kurirBiasa.kurir.length === 0" class="text-gray-500">
                            {{ $t('AGENT_MGMT.SALESBOT.SHIPPING.SELECT_COURIER_PLACEHOLDER') }}
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
                        class="absolute z-10 w-full top-full mt-1 bg-white dark:bg-slate-800 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-48 overflow-y-auto"
                      >
                        <div
                          v-for="kurir in kurirOptions"
                          :key="kurir.id"
                          @click="toggleKurir(kurir.id)"
                          class="flex items-center px-3 py-2 text-sm cursor-pointer hover:bg-gray-50 dark:hover:bg-slate-700 text-gray-900 dark:text-gray-100 transition-colors duration-150"
                          :class="{ 
                            'bg-blue-50 dark:bg-blue-900/50 text-blue-900 dark:text-blue-100': isKurirSelected(kurir.id),
                            'hover:bg-gray-50 dark:hover:bg-slate-700': !isKurirSelected(kurir.id)
                          }"
                        >
                          <input
                            type="checkbox"
                            :checked="isKurirSelected(kurir.id)"
                            class="mr-3 text-blue-600 dark:text-blue-400 bg-gray-100 dark:bg-gray-700 border-gray-300 dark:border-gray-600 rounded focus:ring-blue-500 dark:focus:ring-blue-400"
                            @click.stop
                          >
                          <span class="flex-1 text-sm">{{ kurir.label }}</span>
                          <svg
                            v-if="isKurirSelected(kurir.id)"
                            class="w-4 h-4 text-blue-600 dark:text-blue-400"
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
                  <div class="flex items-center">
                    <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                      <svg class="fill-green-600 dark:fill-white" width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M10.495 14.501v7.498H7.498v-7.498h2.996Zm6.76-1.5h-3.502a.75.75 0 0 0-.75.75v3.502c0 .414.336.75.75.75h3.502a.75.75 0 0 0 .75-.75v-3.502a.75.75 0 0 0-.75-.75Zm-.751 1.5v2.002h-2.001v-2.002h2ZM8.166 7.002H3.5v1.165c0 1.18.878 2.157 2.016 2.311l.157.016.16.005c1.234 0 2.245-.959 2.327-2.173l.005-.16V7.003Zm6.165 0H9.666v1.165c0 1.18.878 2.157 2.016 2.311l.157.016.16.005c1.234 0 2.245-.959 2.327-2.173l.005-.16V7.003Zm6.167 0h-4.665v1.165c0 1.18.878 2.157 2.017 2.311l.156.016.16.005c1.235 0 2.245-.959 2.327-2.173l.006-.16-.001-1.164ZM9.06 3.5H6.326L4.469 5.502h3.977L9.06 3.5Zm4.307 0H10.63l-.616 2.002h3.97L13.369 3.5Zm4.305 0h-2.734l.614 2.002h3.977L17.673 3.5ZM2.2 5.742l3.25-3.502a.75.75 0 0 1 .446-.233L6 2h12a.75.75 0 0 1 .474.169l.076.07 3.272 3.53.03.038c.102.136.148.29.148.44L22 8.168c0 .994-.379 1.9-1 2.58V21.25a.75.75 0 0 1-.649.743L20.25 22l-8.254-.001v-8.248a.75.75 0 0 0-.75-.75H6.75a.75.75 0 0 0-.75.75v8.248L3.75 22a.75.75 0 0 1-.743-.648l-.007-.102V10.748a3.818 3.818 0 0 1-.995-2.384l-.005-.197V6.29a.728.728 0 0 1 .096-.408l.05-.076.054-.065Z"/></svg>                    </div>
                    <div>
                      <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.PICKUP_STORE') }}</h3>
                      <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.DESC_PICKUP_STORE') }}</p>
                    </div>
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
              </div>
            </div>
            
            <div class="w-[240px] flex flex-col gap-3">
              <div class="sticky top-4 bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-4 shadow-sm">
                <div class="flex items-center gap-3 mb-4">
                  <div class="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#2b9966" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-truck-icon lucide-truck"><path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/><path d="M15 18H9"/><path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14"/><circle cx="17" cy="18" r="2"/><circle cx="7" cy="18" r="2"/></svg>
                  </div>
                  <div>
                    <h3 class="font-semibold text-slate-700 dark:text-slate-300">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.HEADER') }}</h3>
                    <p class="text-sm text-slate-500 dark:text-slate-400">{{ $t('AGENT_MGMT.SALESBOT.SHIPPING.HEADER_DESC') }}</p>
                  </div>
                </div>
                
                <Button
                  class="w-full"
                  :is-loading="isSaving"
                  :disabled="isSaving"
                  @click="() => submitShippingConfig()"
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

        <!-- Payment Methods Tab -->
        <div v-show="activeTabIndex === 2" class="w-full min-w-0">
          <div class="flex flex-row gap-4">
            <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-6">
              <div class="space-y-4">
                <div>
                  <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.PAYMENT.HEADER') }}</label>

                  <!-- COD -->
                  <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-4">
                    <div class="flex items-center justify-between p-4">
                      <div class="flex items-center">
                        <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="stroke-green-600 dark:stroke-white lucide lucide-circle-dollar-sign-icon lucide-circle-dollar-sign"><circle cx="12" cy="12" r="10"/><path d="M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8"/><path d="M12 18V6"/></svg> 
                        </div>
                        <div>
                          <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.PAYMENT.COD_TITLE') }}</h3>
                          <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.SALESBOT.PAYMENT.COD_DESC') }}</p>
                        </div>
                      </div>
                      <label class="inline-flex items-center cursor-pointer">
                        <input type="checkbox" v-model="paymentMethods.cod" class="sr-only peer">
                        <div
                          class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
                        </div>
                      </label>
                    </div>
                  </div>

                  <!-- Bank Transfer -->
                  <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-4">
                    <div class="flex items-center justify-between p-4">
                      <div class="flex items-center">
                        <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="stroke-green-600 dark:stroke-white lucide lucide-landmark-icon lucide-landmark"><path d="M10 18v-7"/><path d="M11.12 2.198a2 2 0 0 1 1.76.006l7.866 3.847c.476.233.31.949-.22.949H3.474c-.53 0-.695-.716-.22-.949z"/><path d="M14 18v-7"/><path d="M18 18v-7"/><path d="M3 22h18"/><path d="M6 18v-7"/></svg>
                        </div>
                        <div>
                          <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.PAYMENT.BANK_TRANSFER_TITLE') }}</h3>
                          <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.SALESBOT.PAYMENT.BANK_TRANSFER_DESC') }}</p>
                        </div>
                      </div>
                      <label class="inline-flex items-center cursor-pointer">
                        <input type="checkbox" v-model="paymentMethods.bankTransfer" class="sr-only peer">
                        <div
                          class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
                        </div>
                      </label>
                    </div>
                    
                    <div 
                      v-if="paymentMethods.bankTransfer" 
                      class="border-t border-gray-200 dark:border-gray-700 p-4 space-y-4 transition-all duration-200 ease-in-out"
                    >
                      <div class="space-y-4">
                        <div
                          v-for="(account, index) in bankAccounts"
                          :key="account.id"
                          class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-4"
                        >
                          <div class="flex items-center justify-between mb-4">
                            <h5 class="font-medium text-slate-700 dark:text-slate-300">
                              {{ $t('AGENT_MGMT.SALESBOT.PAYMENT.BANK_ACCOUNT_TITLE')}} #{{ index + 1 }}
                            </h5>
                            <Button
                              variant="ghost"
                              color="ruby"
                              icon="i-lucide-trash"
                              size="sm"
                              @click="() => deleteBankAccount(index)"
                              class="opacity-70 hover:opacity-100"
                            />
                          </div>
                          
                          <div class="grid grid-cols-1 gap-4">
                            <div>
                              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                {{ $t('AGENT_MGMT.SALESBOT.PAYMENT.BANK_NAME_LABEL') }} <span class="text-red-500">*</span>
                              </label>
                              <input
                                type="text"
                                v-model="account.bankName"
                                placeholder="e.g., Bank BCA, Bank Mandiri"
                                class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out"
                              />
                            </div>
                            <div>
                              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                {{ $t('AGENT_MGMT.SALESBOT.PAYMENT.ACCOUNT_NUMBER_LABEL') }} <span class="text-red-500">*</span>
                              </label>
                              <input
                                type="text"
                                v-model="account.accountNumber"
                                placeholder="e.g., 1234567890"
                                class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out"
                              />
                            </div>
                            <div>
                              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                {{ $t('AGENT_MGMT.SALESBOT.PAYMENT.ACCOUNT_HOLDER_LABEL') }} <span class="text-red-500">*</span>
                              </label>
                              <input
                                type="text"
                                v-model="account.accountHolder"
                                placeholder="e.g., John Doe"
                                class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out"
                              />
                            </div>
                          </div>
                        </div>
                      </div>

                      <Button 
                        class="w-full py-3 border-2 border-dashed border-slate-300 dark:border-slate-600 text-slate-500 dark:text-slate-400 hover:border-green-400 hover:text-green-600 transition-all duration-200 rounded-xl bg-transparent hover:bg-green-50 dark:hover:bg-green-900/10" 
                        variant="ghost"
                        @click="addBankAccount"
                      >
                        <span class="flex items-center gap-2">
                          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                          </svg>
                          {{ $t('AGENT_MGMT.SALESBOT.PAYMENT.ADD_BANK_ACCOUNT') }}
                        </span>
                      </Button>
                    </div>
                  </div>

                  <!-- Payment Gateway -->
                  <div class="border border-gray-200 dark:border-gray-700 rounded-lg mb-4">
                    <div class="flex items-center justify-between p-4">
                      <div class="flex items-center">
                        <div class="w-10 h-10 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center mr-3">
                          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="fill-green-600 dark:fill-white lucide lucide-credit-card-icon lucide-credit-card"><rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>
                        </div>
                        <div>
                          <h3 class="font-medium">{{ $t('AGENT_MGMT.SALESBOT.PAYMENT.BANK_TRANSFER_TITLE') }}</h3>
                          <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.SALESBOT.PAYMENT.BANK_TRANSFER_DESC') }}</p>
                        </div>
                      </div>
                      <label class="inline-flex items-center cursor-pointer">
                        <input type="checkbox" v-model="paymentMethods.paymentGateway" class="sr-only peer">
                        <div
                          class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
                        </div>
                      </label>
                    </div>
                    
                    <div 
                      v-if="paymentMethods.paymentGateway" 
                      class="border-t border-gray-200 dark:border-gray-700 p-4 space-y-4 transition-all duration-200 ease-in-out"
                    >
                      <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                          {{ $t('AGENT_MGMT.SALESBOT.PAYMENT.PROVIDER_LABEL') }} <span class="text-red-500">*</span>
                        </label>
                        <select 
                          v-model="paymentGateway.provider"
                          class="w-full mb-0 p-2 text-sm border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
                        >
                          <option value="">{{ $t('AGENT_MGMT.SALESBOT.PAYMENT.SELECT_PROVIDER') }}</option>
                          <option v-for="provider in paymentGatewayProviders" :key="provider.id" :value="provider.id">
                            {{ provider.label }}
                          </option>
                        </select>
                      </div>
                      
                      <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                          API Key <span class="text-red-500">*</span>
                        </label>
                        <input
                          type="password"
                          v-model="paymentGateway.apiKey"
                          :placeholder="$t('AGENT_MGMT.SALESBOT.PAYMENT.API_KEY_PLACEHOLDER')"
                          class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                          {{ $t('AGENT_MGMT.SALESBOT.PAYMENT.MERCHANT_CODE_LABEL') }} <span class="text-red-500">*</span>
                        </label>
                        <input
                          type="text"
                          v-model="paymentGateway.merchantCode"
                          :placeholder="$t('AGENT_MGMT.SALESBOT.PAYMENT.MERCHANT_CODE_PLACEHOLDER')"
                          class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out"
                        />
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
                      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-credit-card-icon lucide-credit-card w-5 h-5 text-green-600 dark:text-green-400"><rect width="20" height="14" x="2" y="5" rx="2"/><line x1="2" x2="22" y1="10" y2="10"/></svg>
                  </div>
                  <div>
                    <h3 class="font-semibold text-slate-700 dark:text-slate-300">{{ $t('AGENT_MGMT.SALESBOT.PAYMENT.HEADER') }}</h3>
                    <p class="text-sm text-slate-500 dark:text-slate-400">{{ $t('AGENT_MGMT.SALESBOT.PAYMENT.HEADER_DESC') }}</p>
                  </div>
                </div>
                
                <Button
                  class="w-full"
                  :is-loading="isSaving"
                  :disabled="isSaving"
                  @click="() => submitPaymentConfig()"
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
      </div>
    </div>
  </div>
</template>

<script setup>
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import provinsiJson from '../wilayah/provinsi/provinsi.json';

import { ref, reactive, watch, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n'

// Google Sheets Auth Flow for Catalog
import googleSheetsExportAPI from '../../../../api/googleSheetsExport';

const { t } = useI18n()

// Initialize and load provinces on mount
onMounted(async () => {
  console.log('Component mounted');
  // loadProvinsi();
  
  // Pre-load Google Maps API but don't initialize map yet
  try {
    await loadGoogleMaps();
    console.log('Google Maps API pre-loaded successfully');
  } catch (error) {
    console.error('Failed to pre-load Google Maps API:', error);
    // Try alternative loading method
    console.log('Attempting alternative Google Maps loading...');
    setTimeout(async () => {
      try {
        // Check if Google is now available
        if (window.google && window.google.maps && window.google.maps.Map) {
          console.log('Google Maps available after retry');
        } else {
          console.log('Google Maps still not available, will retry on map initialization');
        }
      } catch (retryError) {
        console.error('Retry loading also failed:', retryError);
      }
    }, 2000);
  }
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
    showNotification(t('AGENT_MGMT.SALESBOT.PAYMENTSALESBOT.CATALOG.SYNC_INFO'), 'info');
    
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
  {
    key: '2',
    index: 2,
    name: t('AGENT_MGMT.SALESBOT.PAYMENT.HEADER'),
    icon: 'i-lucide-credit-card',
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
  latitude: -6.2088, // Default to Jakarta
  longitude: 106.8456,
  mapLoaded: false,
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
const kelurahanOptions = ref([]);
const loadingKelurahan = ref(false);
// Load kelurahan/desa from JSON based on selected province, kabupaten/kota, and kecamatan
const 
loadKelurahan = async (provinceId, kabupatenId, kecamatanId) => {
  loadingKelurahan.value = true;
  try {
    const kelurahanModule = await import(
      `../wilayah/kelurahan_desa/keldesa-${provinceId}-${kabupatenId}-${kecamatanId}.json`
    );
    const kelurahanJson = kelurahanModule.default || kelurahanModule;
    kelurahanOptions.value = Object.entries(kelurahanJson).map(([id, name]) => ({ id, name }));
  } catch (error) {
    console.error('Failed to load kelurahan JSON:', error);
    showNotification('Failed to load kelurahan data', 'error');
    kelurahanOptions.value = [];
  } finally {
    loadingKelurahan.value = false;
  }
};
const loadingProvinsi = ref(false);
const loadingKota = ref(false);
const loadingKecamatan = ref(false);
const loadingShippingCost = ref(false);

// Search functionality for dropdowns
const provinsiSearchQuery = ref('');
const kotaSearchQuery = ref('');
const kecamatanSearchQuery = ref('');
const isProvinsiDropdownOpen = ref(false);
const isKotaDropdownOpen = ref(false);
const isKecamatanDropdownOpen = ref(false);
const provinsiDropdownRef = ref(null);
const kotaDropdownRef = ref(null);
const kecamatanDropdownRef = ref(null);
const kelurahanSearchQuery = ref('');
const isKelurahanDropdownOpen = ref(false);
const kelurahanDropdownRef = ref(null);

// Computed properties for filtered options
const filteredProvinsiOptions = computed(() => {
  if (!provinsiSearchQuery.value) {
    return provinsiOptions.value;
  }
  return provinsiOptions.value.filter(provinsi => 
    provinsi.name.toLowerCase().includes(provinsiSearchQuery.value.toLowerCase())
  );
});

const filteredKotaOptions = computed(() => {
  if (!kotaSearchQuery.value) {
    return kotaOptions.value;
  }
  return kotaOptions.value.filter(kota => 
    kota.name.toLowerCase().includes(kotaSearchQuery.value.toLowerCase())
  );
});

const filteredKecamatanOptions = computed(() => {
  if (!kecamatanSearchQuery.value) {
    return kecamatanOptions.value;
  }
  return kecamatanOptions.value.filter(kecamatan => 
    kecamatan.name.toLowerCase().includes(kecamatanSearchQuery.value.toLowerCase())
  );
});

const filteredKelurahanOptions = computed(() => {
  if (!kelurahanSearchQuery.value) {
    return kelurahanOptions.value;
  }
  return kelurahanOptions.value.filter(kelurahan => 
    kelurahan.name.toLowerCase().includes(kelurahanSearchQuery.value.toLowerCase())
  );
});

// Computed properties for selected names
const selectedProvinsiName = computed(() => {
  const selected = provinsiOptions.value.find(p => p.id === kurirBiasa.provinsi);
  return selected ? selected.name : '';
});

const selectedKotaName = computed(() => {
  const selected = kotaOptions.value.find(k => k.id === kurirBiasa.kota);
  return selected ? selected.name : '';
});

const selectedKecamatanName = computed(() => {
  const selected = kecamatanOptions.value.find(k => k.id === kurirBiasa.kecamatan);
  return selected ? selected.name : '';
});

const selectedKelurahanName = computed(() => {
  const selected = kelurahanOptions.value.find(k => k.id === kurirBiasa.kelurahan);
  return selected ? selected.name : '';
});


// RajaOngkir API Headers
const getRajaOngkirHeaders = () => ({
  'key': RAJA_ONGKIR_API_KEY,
  'content-type': 'application/x-www-form-urlencoded'
});

// Load provinces from RajaOngkir
const loadProvinsi = async () => {
  loadingProvinsi.value = true;
  try {
    // Use provinsi.json as the source
    provinsiOptions.value = Object.entries(provinsiJson).map(([id, name]) => ({ id, name }));
  } catch (error) {
    console.error('Failed to load provinces from provinsi.json:', error);
    showNotification('Failed to load provinces data', 'error');
    provinsiOptions.value = [];
  } finally {
    loadingProvinsi.value = false;
    
  }
};

// Load cities/regencies from RajaOngkir based on selected province
const loadKota = async (provinceId) => {
  loadingKota.value = true;
  try {
    // Dynamically import kabupaten/kota JSON based on provinceId
    const kabupatenModule = await import(
      `../wilayah/kabupaten_kota/kab-${provinceId}.json`
    );
    const kabupatenJson = kabupatenModule.default || kabupatenModule;
    kotaOptions.value = Object.entries(kabupatenJson).map(([id, name]) => ({ id, name }));
  } catch (error) {
    console.error('Failed to load kabupaten/kota JSON:', error);
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
const loadKecamatan = async (provinceId, kabupatenId) => {
  loadingKecamatan.value = true;
  try {
    // Dynamically import kecamatan JSON based on provinceId and kabupatenId
    const kecamatanModule = await import(
      `../wilayah/kecamatan/kec-${provinceId}-${kabupatenId}.json`
    );
    const kecamatanJson = kecamatanModule.default || kecamatanModule;
    kecamatanOptions.value = Object.entries(kecamatanJson).map(([id, name]) => ({ id, name }));
  } catch (error) {
    console.error('Failed to load kecamatan JSON:', error);
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
    // Load kecamatan using province and kabupaten/kota id
    await loadKecamatan(kurirBiasa.provinsi, kurirBiasa.kota);
  }
}

function onKecamatanChange() {
  kelurahanOptions.value = [];
  kurirBiasa.kelurahan = ''; // Reset kelurahan selection
  if (kurirBiasa.kecamatan) {
    loadKelurahan(kurirBiasa.provinsi, kurirBiasa.kota, kurirBiasa.kecamatan);
  }
  console.log('Kecamatan changed:', kurirBiasa.kecamatan);
}

// Search dropdown functions
function toggleProvinsiDropdown() {
  if (!loadingProvinsi.value) {
    isProvinsiDropdownOpen.value = !isProvinsiDropdownOpen.value;
  }
}

function toggleKotaDropdown() {
  if (!loadingKota.value && kurirBiasa.provinsi) {
    isKotaDropdownOpen.value = !isKotaDropdownOpen.value;
  }
}

function toggleKecamatanDropdown() {
  if (!loadingKecamatan.value && kurirBiasa.kota) {
    isKecamatanDropdownOpen.value = !isKecamatanDropdownOpen.value;
  }
}

function toggleKelurahanDropdown() {
  if (!loadingKelurahan.value && kurirBiasa.kecamatan) {
    isKelurahanDropdownOpen.value = !isKelurahanDropdownOpen.value;
  }
}

function onProvinsiSearch() {
  isProvinsiDropdownOpen.value = true;
}

function onKotaSearch() {
  if (kurirBiasa.provinsi) {
    isKotaDropdownOpen.value = true;
  }
}

function onKecamatanSearch() {
  if (kurirBiasa.kota) {
    isKecamatanDropdownOpen.value = true;
  }
}

function onKelurahanSearch() {
  if (kurirBiasa.kecamatan) {
    isKelurahanDropdownOpen.value = true;
  }
}

function selectKota(kota) {
  kurirBiasa.kota = kota.id;
  kotaSearchQuery.value = '';
  isKotaDropdownOpen.value = false;
  onKotaChange();
}

function selectKecamatan(kecamatan) {
  kurirBiasa.kecamatan = kecamatan.id;
  kecamatanSearchQuery.value = '';
  isKecamatanDropdownOpen.value = false;
  onKecamatanChange();
}

function selectKelurahan(kelurahan) {
  kurirBiasa.kelurahan = kelurahan.id;
  kelurahanSearchQuery.value = '';
  isKelurahanDropdownOpen.value = false;
}

// Click outside handlers
function handleProvinsiClickOutside(event) {
  if (provinsiDropdownRef.value && !provinsiDropdownRef.value.contains(event.target)) {
    isProvinsiDropdownOpen.value = false;
  }
}

function handleKotaClickOutside(event) {
  if (kotaDropdownRef.value && !kotaDropdownRef.value.contains(event.target)) {
    isKotaDropdownOpen.value = false;
  }
}

function handleKecamatanClickOutside(event) {
  if (kecamatanDropdownRef.value && !kecamatanDropdownRef.value.contains(event.target)) {
    isKecamatanDropdownOpen.value = false;
  }
}

function handleKelurahanClickOutside(event) {
  if (kelurahanDropdownRef.value && !kelurahanDropdownRef.value.contains(event.target)) {
    isKelurahanDropdownOpen.value = false;
  }
}

function selectProvinsi(provinsi) {
  kurirBiasa.provinsi = provinsi.id;
  provinsiSearchQuery.value = '';
  isProvinsiDropdownOpen.value = false;
  // Reset city/kabupaten and kecamatan selections
  kurirBiasa.kota = '';
  kurirBiasa.kecamatan = '';
  kotaOptions.value = [];
  kecamatanOptions.value = [];
  // Load cities/kabupaten for selected province
  loadKota(provinsi.id);
};

// Watch for dropdown open states to add/remove event listeners
watch(isProvinsiDropdownOpen, (isOpen) => {
  if (isOpen) {
    document.addEventListener('click', handleProvinsiClickOutside);
  } else {
    document.removeEventListener('click', handleProvinsiClickOutside);
  }
});

watch(isKotaDropdownOpen, (isOpen) => {
  if (isOpen) {
    document.addEventListener('click', handleKotaClickOutside);
  } else {
    document.removeEventListener('click', handleKotaClickOutside);
  }
});

watch(isKecamatanDropdownOpen, (isOpen) => {
  if (isOpen) {
    document.addEventListener('click', handleKecamatanClickOutside);
  } else {
    document.removeEventListener('click', handleKecamatanClickOutside);
  }
});

watch(isKelurahanDropdownOpen, (isOpen) => {
  if (isOpen) {
    document.addEventListener('click', handleKelurahanClickOutside);
  } else {
    document.removeEventListener('click', handleKelurahanClickOutside);
  }
});

// Reset search queries when selections change
watch(() => kurirBiasa.provinsi, () => {
  provinsiSearchQuery.value = '';
});

watch(() => kurirBiasa.kota, () => {
  kotaSearchQuery.value = '';
});

watch(() => kurirBiasa.kecamatan, () => {
  kecamatanSearchQuery.value = '';
});

watch(() => kurirBiasa.kelurahan, () => {
  kelurahanSearchQuery.value = '';
});


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

// Google Maps Integration
const mapRef = ref(null);
const mapInstance = ref(null);
const markerInstance = ref(null);
const geocoderInstance = ref(null);
const mapLoadingTimeout = ref(null);

// Google Maps API Integration
// NOTE: Replace with your actual Google Maps API key
const GOOGLE_MAPS_API_KEY = '';

// Validate API key
const validateApiKey = () => {
  if (!GOOGLE_MAPS_API_KEY || GOOGLE_MAPS_API_KEY === 'YOUR_GOOGLE_MAPS_API_KEY') {
    console.error('Google Maps API key is missing or not configured');
    return false;
  }
  return true;
};

// Load Google Maps API
const loadGoogleMaps = () => {
  return new Promise((resolve, reject) => {
    // Validate API key first
    if (!validateApiKey()) {
      reject(new Error('Google Maps API key is not configured'));
      return;
    }

    // Check if Google Maps is already loaded
    if (window.google && window.google.maps && window.google.maps.Map) {
      // console.log('Google Maps already loaded');
      resolve(window.google); // Return the full google object
      return;
    }

    // Check if script is already loading
    const existingScript = document.querySelector('script[src*="maps.googleapis.com"]');
    if (existingScript) {
      // console.log('Google Maps script already exists, waiting for load...');
      const checkGoogleMaps = () => {
        if (window.google && window.google.maps && window.google.maps.Map) {
          resolve(window.google); // Return the full google object
        } else {
          setTimeout(checkGoogleMaps, 100);
        }
      };
      checkGoogleMaps();
      return;
    }

    // console.log('Loading Google Maps API with key:', GOOGLE_MAPS_API_KEY.substring(0, 10) + '...');
    
    // Create a unique callback name to avoid conflicts
    const callbackName = `initGoogleMaps_${Date.now()}`;
    
    window[callbackName] = () => {
      // console.log('Google Maps API callback triggered');
      if (window.google && window.google.maps && window.google.maps.Map) {
        // console.log('Google Maps API loaded successfully');
        resolve(window.google); // Return the full google object
      } else {
        console.error('Google Maps API callback triggered but objects not available');
        console.error('window.google:', window.google);
        console.error('window.google.maps:', window.google?.maps);
        console.error('window.google.maps.Map:', window.google?.maps?.Map);
        reject(new Error('Google Maps API loaded but objects not available'));
      }
      delete window[callbackName];
    };

    const script = document.createElement('script');
    script.src = `https://maps.googleapis.com/maps/api/js?key=${GOOGLE_MAPS_API_KEY}&libraries=geometry,places&callback=${callbackName}`;
    script.async = true;
    script.defer = true;
    script.onerror = (error) => {
      console.error('Failed to load Google Maps script:', error);
      console.error('API Key used:', GOOGLE_MAPS_API_KEY.substring(0, 10) + '...');
      delete window[callbackName];
      reject(new Error('Failed to load Google Maps script - please check your API key'));
    };
    
    console.log('Appending script to head:', script.src);
    document.head.appendChild(script);
  });
};

// Initialize Google Maps
const initializeMap = async () => {
  // console.log('initializeMap called');
  // console.log('mapRef.value:', mapRef.value);
  // console.log('kurirToko.mapLoaded:', kurirToko.mapLoaded);
  
  if (!mapRef.value) {
    console.error('Map reference not found');
    return;
  }
  
  if (kurirToko.mapLoaded) {
    // console.log('Map already loaded');
    return;
  }

  try {
    // console.log('Loading Google Maps...');
    const google = await loadGoogleMaps();
    
    // console.log('Google Maps loaded, google object:', google);
    // console.log('google.maps:', google.maps);
    // console.log('google.maps.Map:', google.maps?.Map);
    
    if (!google || !google.maps) {
      console.error('Google object or google.maps is missing');
      console.error('Available google properties:', google ? Object.keys(google) : 'none');
      throw new Error('Google Maps API not properly loaded - missing maps object');
    }
    
    if (!google.maps.Map) {
      console.error('google.maps.Map is missing');
      console.error('Available google.maps properties:', Object.keys(google.maps));
      throw new Error('Google Maps API not properly loaded - missing Map constructor');
    }
    
    // Initialize map
    mapInstance.value = new google.maps.Map(mapRef.value, {
      zoom: 15,
      center: { lat: kurirToko.latitude, lng: kurirToko.longitude },
      mapTypeControl: true,
      streetViewControl: false,
      fullscreenControl: false,
    });

    console.log('Map instance created:', mapInstance.value);

    // Initialize marker
    markerInstance.value = new google.maps.Marker({
      position: { lat: kurirToko.latitude, lng: kurirToko.longitude },
      map: mapInstance.value,
      draggable: true,
      title: 'Store Location'
    });

    console.log('Marker created:', markerInstance.value);

    // Initialize geocoder
    geocoderInstance.value = new google.maps.Geocoder();

    console.log('Geocoder created:', geocoderInstance.value);

    // Add marker drag listener
    markerInstance.value.addListener('dragend', (event) => {
      const lat = event.latLng.lat();
      const lng = event.latLng.lng();
      kurirToko.latitude = lat;
      kurirToko.longitude = lng;
      
      // Reverse geocode to update address
      reverseGeocode(lat, lng);
    });

    kurirToko.mapLoaded = true;
    console.log('Google Maps initialized successfully');
  } catch (error) {
    console.error('Error initializing Google Maps:', error);
    console.error('Error details:', {
      message: error.message,
      stack: error.stack,
      window_google: window.google,
      google_maps: window.google?.maps,
      google_maps_Map: window.google?.maps?.Map,
      google_maps_keys: window.google?.maps ? Object.keys(window.google.maps) : 'no maps object'
    });
    showNotification('Failed to load map. Please check your API key and internet connection.', 'error');
  }
};

// Geocode address to coordinates
const geocodeAddress = async (address) => {
  if (!geocoderInstance.value || !address.trim()) return;

  try {
    const response = await new Promise((resolve, reject) => {
      geocoderInstance.value.geocode({ address }, (results, status) => {
        if (status === 'OK' && results[0]) {
          resolve(results[0]);
        } else {
          reject(new Error(`Geocoding failed: ${status}`));
        }
      });
    });

    const location = response.geometry.location;
    const lat = location.lat();
    const lng = location.lng();

    // Update coordinates
    kurirToko.latitude = lat;
    kurirToko.longitude = lng;

    // Update map center and marker position
    if (mapInstance.value && markerInstance.value) {
      const newPosition = { lat, lng };
      mapInstance.value.setCenter(newPosition);
      markerInstance.value.setPosition(newPosition);
    }

  } catch (error) {
    console.error('Geocoding error:', error);
    showNotification('Could not find the address on the map', 'error');
  }
};

// Reverse geocode coordinates to address
const reverseGeocode = async (lat, lng) => {
  if (!geocoderInstance.value) return;

  try {
    const response = await new Promise((resolve, reject) => {
      geocoderInstance.value.geocode(
        { location: { lat, lng } },
        (results, status) => {
          if (status === 'OK' && results[0]) {
            resolve(results[0]);
          } else {
            reject(new Error(`Reverse geocoding failed: ${status}`));
          }
        }
      );
    });

    // Update address field with the formatted address
    kurirToko.alamat = response.formatted_address;
  } catch (error) {
    console.error('Reverse geocoding error:', error);
  }
};

// Watch for address changes to trigger geocoding
let geocodingTimeout = null;
watch(() => kurirToko.alamat, (newAddress) => {
  if (!newAddress || !kurirToko.mapLoaded) return;
  
  // Debounce geocoding requests
  clearTimeout(geocodingTimeout);
  geocodingTimeout = setTimeout(() => {
    geocodeAddress(newAddress);
  }, 1000);
});

// Initialize map when component is mounted and Kurir Toko is enabled
watch(() => shippingMethods.kurirToko, (enabled) => {
  if (enabled && !kurirToko.mapLoaded) {
    // Wait for DOM update and then initialize map
    setTimeout(async () => {
      console.log('Attempting to initialize map after DOM update');
      
      // Try direct access to Google Maps first
      if (window.google && window.google.maps && window.google.maps.Map) {
        console.log('Google Maps already available, initializing directly...');
        await initializeMap();
      } else {
        console.log('Google Maps not available, loading first...');
        try {
          await loadGoogleMaps();
          await initializeMap();
        } catch (error) {
          console.error('Failed to load Google Maps on toggle:', error);
          showNotification('Failed to load map. Please refresh the page and try again.', 'error');
        }
      }
    }, 200);
  }
});

// Also watch for mapRef availability
watch(mapRef, (newMapRef) => {
  console.log('mapRef changed:', newMapRef);
  if (newMapRef && shippingMethods.kurirToko && !kurirToko.mapLoaded) {
    setTimeout(async () => {
      console.log('Attempting to initialize map after mapRef available');
      
      // Ensure Google Maps is loaded
      if (window.google && window.google.maps && window.google.maps.Map) {
        await initializeMap();
      } else {
        console.log('Google Maps not ready, loading...');
        try {
          await loadGoogleMaps();
          await initializeMap();
        } catch (error) {
          console.error('Failed to load Google Maps via mapRef watcher:', error);
        }
      }
    }, 100);
  }
});

// Payment Methods
const paymentMethods = reactive({
  cod: false,
  bankTransfer: false,
  paymentGateway: false
});

// Bank Transfer Accounts
const bankAccounts = ref([]);
const isSaving = ref(false);

function addBankAccount() {
  bankAccounts.value.push({
    id: Date.now(), // temporary ID
    bankName: '',
    accountNumber: '',
    accountHolder: ''
  });
}

function deleteBankAccount(index) {
  bankAccounts.value.splice(index, 1);
}

// Payment Gateway
const paymentGateway = reactive({
  provider: 'duitku',
  apiKey: '',
  merchantCode: ''
});

const paymentGatewayProviders = [
  { label: 'Duitku', id: 'duitku' }
];



function submitShippingConfig() {
  try {
    isSaving.value = true;
    console.log('Shipping:', JSON.parse(JSON.stringify({ shippingMethods, kurirToko, kurirBiasa, ambilToko })));
    
    const shippingData = {
      kurirToko: shippingMethods.kurirToko ? {
        alamat: kurirToko.alamat,
        radius: kurirToko.radius,
        wilayah: kurirToko.wilayah,
        flatRate: kurirToko.flatRate,
        biayaPerJarak: kurirToko.biayaPerJarak,
        gratisOngkir: kurirToko.gratisOngkir,
        minimalBelanja: kurirToko.gratisOngkir ? kurirToko.minimalBelanja : null,
        coordinates: {
          latitude: kurirToko.latitude,
          longitude: kurirToko.longitude
        }      
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
    
    // TODO: API call integration
    
    setTimeout(() => {
      showNotification('Shipping configuration saved successfully', 'success');
      isSaving.value = false;
    }, 1000);
  } catch (error) {
    console.error('Save error:', error);
    showNotification('Failed to save shipping configuration', 'error');
    isSaving.value = false;
  }
}

function submitPaymentConfig() {
  try {
    isSaving.value = true;
    
    console.log('Payment Methods:', JSON.parse(JSON.stringify({ paymentMethods, bankAccounts: bankAccounts.value, paymentGateway })));
    
    const paymentData = {
      cod: paymentMethods.cod,
      bankTransfer: paymentMethods.bankTransfer ? {
        accounts: bankAccounts.value.filter(account => 
          account.bankName && account.accountNumber && account.accountHolder
        )
      } : null,
      paymentGateway: paymentMethods.paymentGateway ? {
        provider: paymentGateway.provider,
        apiKey: paymentGateway.apiKey,
        merchantCode: paymentGateway.merchantCode
      } : null
    };
    
    console.log('Processed Payment Data:', paymentData);
    // TODO: API call integration
    
    setTimeout(() => {
      showNotification('Payment configuration saved successfully', 'success');
      isSaving.value = false;
    }, 1000);
  } catch (error) {
    console.error('Save error:', error);
    showNotification('Failed to save payment configuration', 'error');
    isSaving.value = false;
  }
}
</script>

<style scoped>
/* Enhanced dropdown styling with proper scrolling */
.dropdown-container {
  position: relative;
}

.dropdown-input {
  transition: all 0.2s ease-in-out;
  position: relative;
  z-index: 2;
}

.dropdown-input:focus {
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.dropdown-menu {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  transition: all 0.15s ease-in-out;
  transform-origin: top;
  border: 1px solid rgba(209, 213, 219, 1);
}

.dropdown-item {
  transition: background-color 0.15s ease-in-out;
  border-bottom: 1px solid rgba(243, 244, 246, 1);
}

.dropdown-item:last-child {
  border-bottom: none;
}

.dropdown-item:hover {
  transform: translateX(2px);
}

/* Custom scrollbar styling */
.scrollbar-thin {
  scrollbar-width: thin;
}

.scrollbar-thumb-gray-300::-webkit-scrollbar-thumb {
  background-color: rgb(209 213 219);
  border-radius: 9999px;
}

.scrollbar-track-gray-100::-webkit-scrollbar-track {
  background-color: rgb(243 244 246);
  border-radius: 9999px;
}

.scrollbar-thin::-webkit-scrollbar {
  width: 6px;
}

.scrollbar-thin::-webkit-scrollbar-track {
  background: rgb(243 244 246);
  border-radius: 9999px;
}

.scrollbar-thin::-webkit-scrollbar-thumb {
  background: rgb(209 213 219);
  border-radius: 9999px;
}

.scrollbar-thin::-webkit-scrollbar-thumb:hover {
  background: rgb(156 163 175);
}

/* Dark mode scrollbar */
.dark .scrollbar-thumb-gray-600::-webkit-scrollbar-thumb {
  background-color: rgb(75 85 99);
}

.dark .scrollbar-track-gray-800::-webkit-scrollbar-track {
  background-color: rgb(31 41 55);
}

.dark .scrollbar-thin::-webkit-scrollbar-track {
  background: rgb(31 41 55);
}

.dark .scrollbar-thin::-webkit-scrollbar-thumb {
  background: rgb(75 85 99);
}

.dark .scrollbar-thin::-webkit-scrollbar-thumb:hover {
  background: rgb(107 114 128);
}

/* Dark mode dropdown adjustments */
.dark .dropdown-menu {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.3), 0 4px 6px -2px rgba(0, 0, 0, 0.2);
  border-color: rgb(75 85 99);
}

.dark .dropdown-item {
  border-bottom-color: rgb(55 65 81);
}

/* Ensure dropdown appears above other elements */
.dropdown-menu {
  z-index: 9999 !important;
}

/* Fix for dropdown positioning in containers with overflow */
.dropdown-container:has(.dropdown-menu[style*="display: block"]) {
  z-index: 9999;
}
</style>