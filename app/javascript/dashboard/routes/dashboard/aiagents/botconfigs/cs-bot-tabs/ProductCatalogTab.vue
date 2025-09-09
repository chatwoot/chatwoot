<template>
  <div class="w-full space-y-6">
    <div class="flex flex-col gap-4">
      <div>
        <h3 class="font-medium text-lg mb-2">Product Catalog</h3>
        <p class="text-sm text-gray-500 mb-4">Configure your product catalog settings for the CS Bot.</p>
        
        <div class="space-y-4">
          <!-- Google Sheets URL -->
          <div>
            <label class="block font-medium mb-1">Google Sheets URL</label>
            <input
              v-model="catalogConfig.sheetsUrl"
              type="url"
              placeholder="https://docs.google.com/spreadsheets/d/..."
              class="w-full border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out"
            />
          </div>

          <!-- Column Description -->
          <div>
            <label class="block font-medium mb-1">Column Description (Optional)</label>
            <textarea
              v-model="catalogConfig.columnDescription"
              placeholder="Example: Name, Price, Stock, etc"
              class="w-full text-sm flex flex-col gap-2 px-3 pt-3 pb-3 transition-all duration-500 ease-in-out border rounded-lg bg-n-alpha-black2 hover:border-n-slate-6 dark:hover:border-n-slate-6 border-n-weak dark:border-n-weak resize-none"
              rows="3"
            ></textarea>
          </div>

          <!-- Auto Sync Settings -->
          <div>
            <label class="block font-medium mb-1">Auto Sync</label>
            <p class="text-sm text-gray-500 mb-2">Automatically sync catalog data from Google Sheets</p>
            <label class="inline-flex items-center cursor-pointer">
              <input type="checkbox" v-model="catalogConfig.autoSync" class="sr-only peer">
              <div
                class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
              </div>
            </label>
          </div>

          <!-- Sync Interval (if auto sync is enabled) -->
          <div v-if="catalogConfig.autoSync">
            <label class="block font-medium mb-1">Sync Interval</label>
            <select v-model="catalogConfig.syncInterval" class="w-1/2 p-2 border rounded-md">
              <option value="hourly">Every Hour</option>
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
            </select>
          </div>

          <!-- Test Connection Button -->
          <div>
            <button
              @click="testConnection"
              :disabled="!catalogConfig.sheetsUrl || isTestingConnection"
              class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              <span v-if="isTestingConnection">Testing...</span>
              <span v-else>Test Connection</span>
            </button>
          </div>

          <!-- Save Button -->
          <div class="pt-4">
            <button
              @click="saveCatalog"
              :disabled="isSaving"
              class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
            >
              <span v-if="isSaving">Saving...</span>
              <span v-else>Simpan</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useAlert } from 'dashboard/composables'

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
})

const catalogConfig = reactive({
  sheetsUrl: '',
  columnDescription: '',
  autoSync: false,
  syncInterval: 'daily'
})

const isTestingConnection = ref(false)
const isSaving = ref(false)

async function testConnection() {
  if (!catalogConfig.sheetsUrl) {
    useAlert('Please enter Google Sheets URL first')
    return
  }

  try {
    isTestingConnection.value = true
    // TODO: Implement actual connection test
    await new Promise(resolve => setTimeout(resolve, 2000)) // Simulate API call
    useAlert('Connection successful!')
  } catch (error) {
    useAlert('Connection failed. Please check your URL.')
  } finally {
    isTestingConnection.value = false
  }
}

async function saveCatalog() {
  try {
    isSaving.value = true
    // TODO: API call to save catalog configuration
    await new Promise(resolve => setTimeout(resolve, 1000))
    useAlert('Berhasil simpan catalog settings')
  } catch (e) {
    useAlert('Gagal simpan catalog settings')
  } finally {
    isSaving.value = false
  }
}
</script>
