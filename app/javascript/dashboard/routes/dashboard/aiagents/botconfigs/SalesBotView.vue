<template>
  <div class="w-full min-h-0">
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
        <div>
          <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.CATALOG.SHEETS_TITLE') }}</label>
          <input 
            type="text" 
            class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-1/2 reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
            :placeholder="$t('AGENT_MGMT.SALESBOT.CATALOG.SHEETS_PLACEHOLDER')" 
            v-model="catalogSheet" 
          />
        </div>
        <div>
          <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.SALESBOT.CATALOG.DESC_TITLE') }}</label>
          <textarea 
            class="text-sm flex flex-col gap-2 px-3 pt-3 pb-3 transition-all duration-500 ease-in-out border rounded-lg bg-n-alpha-black2 hover:border-n-slate-6 dark:hover:border-n-slate-6 border-n-weak dark:border-n-weak w-1/2" 
            rows="3" 
            :placeholder="$t('AGENT_MGMT.SALESBOT.CATALOG.DESC_PLACEHOLDER')" 
            v-model="catalogDesc"
          ></textarea>
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
                <select 
                  multiple 
                  class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-full reset-base text-sm !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out" 
                  v-model="kurirBiasa.kurir"
                >
                  <option value="JNE">JNE</option>
                  <option value="TIKI">TIKI</option>
                  <option value="POS">POS</option>
                  <option value="Sicepat">Sicepat</option>
                  <option value="Anteraja">Anteraja</option>
                </select>
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
import { ref, reactive } from 'vue';

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
const ambilToko = reactive({ alamat: '', jam: '', estimasi: '' });

function submitConfig() {
  console.log('Katalog:', catalogSheet.value, catalogDesc.value);
  console.log('Shipping:', JSON.parse(JSON.stringify({ shippingMethods, kurirToko, kurirBiasa, ambilToko })));
  // TODO: API call integration
}
</script>

<style scoped>
/* Ensure smooth transitions and proper container behavior */
.w-full {
  contain: layout style;
}

/* Prevent layout shifts during expansion */
.space-y-6 > * {
  transform-origin: top;
}

/* Ensure proper height calculations */
.border {
  min-height: fit-content;
}
</style>