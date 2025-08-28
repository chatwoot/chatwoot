<template>
  <div class="flex flex-row gap-4">
    <div class="flex-1 min-w-0 flex flex-col justify-stretch gap-4">
      <div class="space-y-4">
        <div
          v-for="(category, index) in categories"
          :key="index"
          class="bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl p-6 hover:shadow-md transition-all duration-200 hover:border-slate-300 dark:hover:border-slate-600"
        >
          <div class="flex items-start justify-between mb-4">
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full"></div>
              <h3 class="text-sm font-medium text-slate-700 dark:text-slate-300">
                Category #{{ index + 1 }}
              </h3>
            </div>
            <Button
              variant="ghost"
              color="ruby"
              icon="i-lucide-trash"
              size="sm"
              :disabled="false"
              @click="() => removeCategory(index)"
              class="opacity-70 hover:opacity-100"
            />
          </div>
          
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">
                {{ $t('AGENT_MGMT.CSBOT.TICKET.CATEGORY_PLACEHOLDER') }}
                <span class="text-red-500">*</span>
              </label>
              <input
                v-model="category.name"
                @blur="validateCategoryName(index)"
                @input="validateCategoryName(index)"
                :placeholder="$t('AGENT_MGMT.CSBOT.TICKET.CATEGORY_PLACEHOLDER')"
                :class="[
                  'w-full px-3 py-2.5 text-sm rounded-lg border transition-all duration-200',
                  'bg-slate-50 dark:bg-slate-900/50',
                  'focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500',
                  'hover:border-slate-300 dark:hover:border-slate-600',
                  validation.categories[index] 
                    ? 'border-red-300 focus:border-red-500 focus:ring-red-500/20' 
                    : 'border-slate-200 dark:border-slate-700',
                  'placeholder:text-slate-400 dark:placeholder:text-slate-500'
                ]"
              />
              <p v-if="validation.categories[index]" class="text-red-500 text-xs">
                {{ validation.categories[index] }}
              </p>
            </div>
            
            <div class="space-y-2">
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300">
                Kondisi Kategori
              </label>
              <textarea
                v-model="category.condition"
                :placeholder="$t('AGENT_MGMT.CSBOT.TICKET.CONDITION_PLACEHOLDER')"
                class="w-full px-3 py-2.5 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900/50 hover:border-slate-300 dark:hover:border-slate-600 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all duration-200 resize-none placeholder:text-slate-400 dark:placeholder:text-slate-500"
                rows="3"
              ></textarea>
            </div>
          </div>
        </div>
      </div>

      <Button 
        id="btnAddCategory" 
        class="w-full py-3 border-2 border-dashed border-slate-300 dark:border-slate-600 text-slate-500 dark:text-slate-400 hover:border-green-400 hover:text-green-600 transition-all duration-200 rounded-xl bg-transparent hover:bg-green-50 dark:hover:bg-green-900/10" 
        variant="ghost"
        @click="addCategory"
      >
        <span class="flex items-center gap-2">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
          </svg>
          {{ $t('AGENT_MGMT.CSBOT.TICKET.ADD_CATEGORY') }}
        </span>
      </Button>
    </div>
    
    <div class="w-[240px] flex flex-col gap-3">
      <div class="sticky top-4 bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 p-4 shadow-sm">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
            <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
            </svg>
          </div>
          <div>
            <h3 class="font-semibold text-slate-700 dark:text-slate-300">Categories</h3>
            <p class="text-sm text-slate-500 dark:text-slate-400">{{ categories.length }} items</p>
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
            Simpan
          </span>
        </Button>

      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAlert } from 'dashboard/composables'
import Button from 'dashboard/components-next/button/Button.vue'

const { t } = useI18n()

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
})

const categories = reactive([
  { name: 'Komplain', condition: '' },
  { name: 'Teknis', condition: '' },
  { name: 'Lainnya', condition: '' }
])

const validation = reactive({
  categories: {}
})

const isSaving = ref(false)

function validateCategoryName(index) {
  const name = categories[index]?.name?.trim()
  if (!name) {
    validation.categories[index] = t('AGENT_MGMT.CSBOT.TICKET.ERROR')
    return false
  }
  
  const duplicateIndex = categories.findIndex((c, i) => 
    i !== index && c.name?.trim().toLowerCase() === name.toLowerCase()
  )
  if (duplicateIndex !== -1) {
    validation.categories[index] = t('AGENT_MGMT.CSBOT.TICKET.DUPE_ERROR')
    return false
  }
  
  delete validation.categories[index]
  return true
}

function addCategory() {
  categories.push({ name: '', condition: '' })
}

function removeCategory(index) {
  categories.splice(index, 1)
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

async function save() {
  try {
    isSaving.value = true
    
    // Validate all categories
    let isValid = true
    categories.forEach((_, index) => {
      if (!validateCategoryName(index)) {
        isValid = false
      }
    })
    
    if (!isValid) {
      useAlert('Please fix validation errors')
      return
    }

    // TODO: API call to save categories
    await new Promise(resolve => setTimeout(resolve, 1000))
    useAlert('Berhasil simpan categories')
  } catch (e) {
    useAlert('Gagal simpan categories')
  } finally {
    isSaving.value = false
  }
}
</script>
