<template>
  <div class="flex flex-row gap-4">
    <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-6">
      <div class="space-y-4">
        <h3 class="text-lg font-semibold text-slate-700 dark:text-slate-300 mb-4">
          {{ $t('AGENT_MGMT.CSBOT.TICKET.GENERAL_SETTINGS') }}
        </h3>
        
        <!-- Sistem Tiket Toggle -->
        <div class="mb-6">
          <label class="block font-medium mb-2">{{ $t('AGENT_MGMT.CSBOT.TICKET.SYSTEM_TITLE') }}</label>
          <p class="text-sm text-gray-500 mb-3">{{ $t('AGENT_MGMT.CSBOT.TICKET.SYSTEM_DESC') }}</p>
          <label class="inline-flex items-center cursor-pointer">
            <input type="checkbox" v-model="config.ticketSystemActive" class="sr-only peer">
            <div
              class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
            </div>
            <span class="ml-3 text-sm text-slate-700 dark:text-slate-300">
              {{ config.ticketSystemActive ? $t('AGENT_MGMT.CSBOT.TICKET.ACTIVE') : $t('AGENT_MGMT.CSBOT.TICKET.INACTIVE') }}
            </span>
          </label>
        </div>

        <!-- Kapan tiket dibuat -->
        <div v-if="config.ticketSystemActive" class="mb-6">
          <label class="block font-medium mb-2">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_WHEN') }}</label>
          <p class="text-sm text-gray-500 mb-3">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_WHEN_DESC') }}</p>
          <select 
            v-model="config.ticketCreateWhen" 
            class="w-full max-w-md px-3 py-2.5 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900/50 hover:border-slate-300 dark:hover:border-slate-600 focus:ring-2 focus:ring-green-500/20 focus:border-green-500 transition-all duration-200"
          >
            <option value="always">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_ALWAYS') }}</option>
            <option value="bot_fail">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_ON_FAIL') }}</option>
          </select>
        </div>
      </div>
    </div>
    
    <div class="w-[240px] flex flex-col gap-3">
      <div class="sticky top-4 bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-4 shadow-sm">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
            <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
            </svg>
          </div>
          <div>
            <h3 class="font-semibold text-slate-700 dark:text-slate-300">{{ $t('AGENT_MGMT.CSBOT.TICKET.GENERAL_SETTINGS') }}</h3>
            <p class="text-sm text-slate-500 dark:text-slate-400">{{ $t('AGENT_MGMT.CSBOT.TICKET.SYSTEM_SETTINGS') }}</p>
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
            {{ $t('AGENT_MGMT.CSBOT.TICKET.SAVE_BUTTON') }}
          </span>
        </Button>

      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAlert } from 'dashboard/composables'
import Button from 'dashboard/components-next/button/Button.vue'

const { t } = useI18n()

const props = defineProps({
  config: {
    type: Object,
    required: true,
  },
})

const isSaving = ref(false)

async function save() {
  try {
    isSaving.value = true
    
    // TODO: API call to save general settings
    await new Promise(resolve => setTimeout(resolve, 1000))
    useAlert(t('AGENT_MGMT.CSBOT.TICKET.SAVE_SUCCESS'))
  } catch (e) {
    useAlert(t('AGENT_MGMT.CSBOT.TICKET.SAVE_ERROR'))
  } finally {
    isSaving.value = false
  }
}
</script>
