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

    <!-- Prioritas Tiket - Accordion -->
    <div v-if="config.ticketSystemActive" class="border border-gray-200 dark:border-gray-700 rounded-lg">
      <button
        @click="toggleAccordion('priorities')"
        class="w-full flex items-center justify-between p-4 text-left hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
      >
        <div>
          <h3 class="font-medium">{{ $t('AGENT_MGMT.CSBOT.TICKET.PRIORITY_TITLE') }}</h3>
          <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.CSBOT.TICKET.PRIORITY_DESC') }}</p>
        </div>
        <svg
          :class="['w-5 h-5 transition-transform duration-200', accordionState.priorities ? 'rotate-180' : '']"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
        </svg>
      </button>
      
      <div
        v-show="accordionState.priorities"
        class="border-t border-gray-200 dark:border-gray-700 p-4 space-y-4"
      >
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
              @blur="validatePriorityName(index)"
              @input="validatePriorityName(index)"
              :placeholder="$t('AGENT_MGMT.CSBOT.TICKET.PRIORITY_PLACEHOLDER')"
              :class="[
                'border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block w-1/2 reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out',
                validation.priorities[index] ? 'border-red-500 focus:border-red-500' : ''
              ]"
            />
            <p v-if="validation.priorities[index]" class="text-red-500 text-xs mt-1">
              {{ validation.priorities[index] }}
            </p>
          </div>
          <div>
            <label class="block font-medium mb-1">Kondisi Prioritas</label>
            <textarea
              v-model="priority.condition"
              :placeholder="$t('AGENT_MGMT.CSBOT.TICKET.CONDITION_PLACEHOLDER')"
              class="w-full text-sm flex flex-col gap-2 px-3 pt-3 pb-3 transition-all duration-500 ease-in-out border rounded-lg bg-n-alpha-black2 hover:border-n-slate-6 dark:hover:border-n-slate-6 border-n-weak dark:border-n-weak"
            ></textarea>
          </div>
        </div>

        <button @click="addPriority" class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700">+ {{ $t('AGENT_MGMT.CSBOT.TICKET.ADD_PRIORITY') }}</button>
      </div>
    </div>

    <!-- Kategori Tiket - Accordion -->
    <div v-if="config.ticketSystemActive" class="border border-gray-200 dark:border-gray-700 rounded-lg">
      <button
        @click="toggleAccordion('categories')"
        class="w-full flex items-center justify-between p-4 text-left hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
      >
        <div>
          <h3 class="font-medium">{{ $t('AGENT_MGMT.CSBOT.TICKET.CATEGORY_TITLE') }}</h3>
          <p class="text-sm text-gray-500 mt-1">{{ $t('AGENT_MGMT.CSBOT.TICKET.CATEGORY_DESC') }}</p>
        </div>
        <svg
          :class="['w-5 h-5 transition-transform duration-200', accordionState.categories ? 'rotate-180' : '']"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
        </svg>
      </button>
      
      <div
        v-show="accordionState.categories"
        class="border-t border-gray-200 dark:border-gray-700 p-4 space-y-4"
      >
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
              @blur="validateCategoryName(index)"
              @input="validateCategoryName(index)"
              :placeholder="$t('AGENT_MGMT.CSBOT.TICKET.CATEGORY_PLACEHOLDER')"
              :class="[
                'w-1/2 border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6 disabled:border-n-weak dark:disabled:border-n-weak focus:border-n-brand dark:focus:border-n-brand block reset-base text-sm h-10 !px-3 !py-2.5 !mb-0 border rounded-lg bg-n-alpha-black2 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-n-slate-10 dark:placeholder:text-n-slate-10 disabled:cursor-not-allowed disabled:opacity-50 text-n-slate-12 transition-all duration-500 ease-in-out',
                validation.categories[index] ? 'border-red-500 focus:border-red-500' : ''
              ]"
            />
            <p v-if="validation.categories[index]" class="text-red-500 text-xs mt-1">
              {{ validation.categories[index] }}
            </p>
          </div>
          <div>
            <label class="block font-medium mb-1">Kondisi Kategori</label>
            <textarea
              v-model="category.condition"
              :placeholder="$t('AGENT_MGMT.CSBOT.TICKET.CONDITION_PLACEHOLDER')"
              class="w-full text-sm flex flex-col gap-2 px-3 pt-3 pb-3 transition-all duration-500 ease-in-out border rounded-lg bg-n-alpha-black2 hover:border-n-slate-6 dark:hover:border-n-slate-6 border-n-weak dark:border-n-weak"
            ></textarea>
          </div>
        </div>

        <button @click="addCategory" class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700">+ {{ $t('AGENT_MGMT.CSBOT.TICKET.ADD_CATEGORY') }}</button>
      </div>
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
import { useI18n } from 'vue-i18n';
const { t } = useI18n();
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

const accordionState = reactive({
  priorities: false,
  categories: false
})

const validation = reactive({
  priorities: {},
  categories: {}
})

function toggleAccordion(section) {
  accordionState[section] = !accordionState[section]
}

function validatePriorityName(index) {
  const name = config.priorities[index]?.name?.trim()
  if (!name) {
    validation.priorities[index] = t('AGENT_MGMT.CSBOT.TICKET.ERROR')
    return false
  }
  
  // Check for duplicate names
  const duplicateIndex = config.priorities.findIndex((p, i) => 
    i !== index && p.name?.trim().toLowerCase() === name.toLowerCase()
  )
  if (duplicateIndex !== -1) {
    validation.priorities[index] = t('AGENT_MGMT.CSBOT.TICKET.DUPE_ERROR')
    return false
  }
  
  delete validation.priorities[index]
  return true
}

function validateCategoryName(index) {
  const name = config.categories[index]?.name?.trim()
  if (!name) {
    validation.categories[index] = t('AGENT_MGMT.CSBOT.TICKET.ERROR')
    return false
  }
  
  // Check for duplicate names
  const duplicateIndex = config.categories.findIndex((c, i) => 
    i !== index && c.name?.trim().toLowerCase() === name.toLowerCase()
  )
  if (duplicateIndex !== -1) {
    validation.categories[index] = t('AGENT_MGMT.CSBOT.TICKET.DUPE_ERROR')
    return false
  }
  
  delete validation.categories[index]
  return true
}

function validateAllFields() {
  let isValid = true
  
  // Validate all priorities
  config.priorities.forEach((_, index) => {
    if (!validatePriorityName(index)) {
      isValid = false
    }
  })
  
  // Validate all categories
  config.categories.forEach((_, index) => {
    if (!validateCategoryName(index)) {
      isValid = false
    }
  })
  
  return isValid
}

function addPriority() {
  const newIndex = config.priorities.length
  config.priorities.push({ name: '', condition: '' })
  // Auto-expand accordion when adding new item
  accordionState.priorities = true
}

function removePriority(index) {
  config.priorities.splice(index, 1)
  // Clean up validation for removed item and reindex
  delete validation.priorities[index]
  const newValidation = {}
  Object.keys(validation.priorities).forEach(key => {
    const keyIndex = parseInt(key)
    if (keyIndex > index) {
      newValidation[keyIndex - 1] = validation.priorities[keyIndex]
    } else if (keyIndex < index) {
      newValidation[keyIndex] = validation.priorities[keyIndex]
    }
  })
  validation.priorities = newValidation
}

function addCategory() {
  const newIndex = config.categories.length
  config.categories.push({ name: '', condition: '' })
  // Auto-expand accordion when adding new item
  accordionState.categories = true
}

function removeCategory(index) {
  config.categories.splice(index, 1)
  // Clean up validation for removed item and reindex
  delete validation.categories[index]
  const newValidation = {}
  Object.keys(validation.categories).forEach(key => {
    const keyIndex = parseInt(key)
    if (keyIndex > index) {
      newValidation[keyIndex - 1] = validation.categories[keyIndex]
    } else if (keyIndex < index) {
      newValidation[keyIndex] = validation.categories[keyIndex]
    }
  })
  validation.categories = newValidation
}

function submitConfig() {
  if (!validateAllFields()) {
    // Auto-expand sections with validation errors
    const hasValidationErrors = Object.keys(validation.priorities).length > 0 || 
                              Object.keys(validation.categories).length > 0
    if (hasValidationErrors) {
      if (Object.keys(validation.priorities).length > 0) {
        accordionState.priorities = true
      }
      if (Object.keys(validation.categories).length > 0) {
        accordionState.categories = true
      }
      return
    }
  }
  
  console.log('Submitting config:', config)
  // TODO: API call integration
}
</script>