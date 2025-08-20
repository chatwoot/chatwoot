<template>
  <div class="w-full">
    <div class="pb-4">
      <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-1">
        {{ $t('AGENT_MGMT.CSBOT.TICKET.HEADER') }}
      </h2>
      <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
        {{ $t('AGENT_MGMT.CSBOT.TICKET.HEADER_DESC') }}
      </p>
      <div class="border-b border-gray-200 dark:border-gray-700"></div>
    </div>
    <div class="space-y-6">
    <!-- Sistem Tiket Toggle -->
    <div>
      <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.CSBOT.TICKET.SYSTEM_TITLE') }}</label>
      <p class="text-sm text-gray-500 mb-2">{{ $t('AGENT_MGMT.CSBOT.TICKET.SYSTEM_DESC') }}</p>
      <label class="inline-flex items-center cursor-pointer">
        <input type="checkbox" v-model="config.ticketSystemActive" class="sr-only peer">
        <div
          class="border solid w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-green-500 relative after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full">
        </div>
      </label>
    </div>

    <!-- Kapan tiket dibuat -->
    <div v-if="config.ticketSystemActive">
      <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_WHEN') }}</label>
      <select v-model="config.ticketCreateWhen" class="w-1/2 p-2 border rounded-md">
        <option value="always">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_ALWAYS') }}</option>
        <option value="bot_fail">{{ $t('AGENT_MGMT.CSBOT.TICKET.CREATE_ON_FAIL') }}</option>
      </select>
    </div>

    <!-- Prioritas Tiket -->
    <div v-if="config.ticketSystemActive">
      <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.CSBOT.TICKET.PRIORITY_TITLE') }}</label>
      <p class="text-sm text-gray-500 mb-2">{{ $t('AGENT_MGMT.CSBOT.TICKET.PRIORITY_DESC') }}</p>

      <div v-for="(priority, index) in config.priorities" :key="index" class="flex flex-col m-0.5 px-6 py-5 overflow-hidden rounded-xl flex-grow text-n-slate-12 shadow outline-1 outline outline-n-container bg-n-solid-2 min-h-[10rem] mb-4">
        <div class="flex justify-between items-center mb-2">
          <label class="block font-medium mb-1">Prioritas</label>
          <button
            @click="removePriority(index)"
            class="border border-red-500 text-red-500 rounded px-3 py-1 hover:bg-red-50 hover:border-red-600 hover:text-red-600 transition-colors"
          >
            {{ $t('AGENT_MGMT.COMMON.REMOVE') }}
          </button>
        </div>
        <div class="mb-2">
          <input
            v-model="priority.name"
            :placeholder="$t('AGENT_MGMT.CSBOT.TICKET.PRIORITY_PLACEHOLDER')"
            class="border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-1/2 reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out"
          />
        </div>
        <div>
          <label class="block font-medium mb-1">Kondisi Prioritas</label>
          <textarea
            v-model="priority.condition"
            :placeholder="$t('AGENT_MGMT.CSBOT.TICKET.CONDITION_PLACEHOLDER')"
            class="text-sm flex flex-col gap-2 px-3 pt-3 pb-3 transition-all duration-500 ease-in-out border rounded-lg bg-n-alpha-black2 hover:border-n-slate-6 dark:hover:border-n-slate-6 border-n-weak dark:border-n-weak"
          ></textarea>
        </div>
      </div>

  <button @click="addPriority" class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700">+ {{ $t('AGENT_MGMT.CSBOT.TICKET.ADD_PRIORITY') }}</button>
    </div>

    <!-- Kategori Tiket -->
    <div v-if="config.ticketSystemActive">
      <label class="block font-medium mb-1">{{ $t('AGENT_MGMT.CSBOT.TICKET.CATEGORY_TITLE') }}</label>
      <p class="text-sm text-gray-500 mb-2">{{ $t('AGENT_MGMT.CSBOT.TICKET.CATEGORY_DESC') }}</p>

      <div v-for="(category, index) in config.categories" :key="index" class="flex flex-col m-0.5 px-6 py-5 overflow-hidden rounded-xl flex-grow text-n-slate-12 shadow outline-1 outline outline-n-container bg-n-solid-2 min-h-[10rem] mb-4">
        <div class="flex justify-between items-center mb-2">
          <label class="block font-medium mb-1">Kategori</label>
          <button
            @click="removeCategory(index)"
            class="border border-red-500 text-red-500 rounded px-3 py-1 hover:bg-red-50 hover:border-red-600 hover:text-red-600 transition-colors"
          >
            {{ $t('AGENT_MGMT.COMMON.REMOVE') }}
          </button>
        </div>
        <div class="mb-2">
          <input
            v-model="category.name"
            :placeholder="$t('AGENT_MGMT.CSBOT.TICKET.CATEGORY_PLACEHOLDER')"
            class="w-1/2 border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out"
          />
        </div>
        <div>
          <label class="block font-medium mb-1">Kondisi Kategori</label>
          <textarea
            v-model="category.condition"
            :placeholder="$t('AGENT_MGMT.CSBOT.TICKET.CONDITION_PLACEHOLDER')"
            class="text-sm flex flex-col gap-2 px-3 pt-3 pb-3 transition-all duration-500 ease-in-out border rounded-lg bg-n-alpha-black2 hover:border-n-slate-6 dark:hover:border-n-slate-6 border-n-weak dark:border-n-weak"
          ></textarea>
        </div>
      </div>

  <button @click="addCategory" class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700">+ {{ $t('AGENT_MGMT.CSBOT.TICKET.ADD_CATEGORY') }}</button>
    </div>

    <!-- Submit Button -->
    <div class="pt-6">
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
import { reactive } from 'vue'

const config = reactive({
  ticketSystemActive: false,
  ticketCreateWhen: 'always',
  priorities: [
    { name: 'Low', condition: '' },
    { name: 'Medium', condition: '' },
    { name: 'High', condition: '' },
    { name: 'Urgent', condition: '' }
  ],
  categories: [
    { name: 'Komplain', condition: '' },
    { name: 'Teknis', condition: '' },
    { name: 'Lainnya', condition: '' }
  ]
})

function addPriority() {
  config.priorities.push({ name: '', condition: '' })
}
function removePriority(index) {
  config.priorities.splice(index, 1)
}

function addCategory() {
  config.categories.push({ name: '', condition: '' })
}
function removeCategory(index) {
  config.categories.splice(index, 1)
}

function submitConfig() {
  console.log('Submitting config:', config)
  // TODO: API call integration
}
</script>
