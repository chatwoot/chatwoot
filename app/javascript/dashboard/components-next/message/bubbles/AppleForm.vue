<script setup>
import { computed, ref, onMounted } from 'vue';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';

const { contentAttributes } = useMessageContext();

const formData = computed(() => contentAttributes.value || {});
const isExpanded = ref(false);
const selectedPage = ref(0);

// Extract form configuration
const formConfig = computed(() => ({
  formId: formData.value.form_id || 'unknown',
  title: formData.value.title || 'Form',
  description: formData.value.description,
  pages: formData.value.pages || [],
  submitButton: formData.value.submit_button || { title: 'Submit' },
  cancelButton: formData.value.cancel_button || { title: 'Cancel' },
  version: formData.value.version || '1.0'
}));

// Form state
const responses = ref({});
const isSubmitting = ref(false);
const hasErrors = ref(false);
const errorMessage = ref('');

// Computed properties
const currentPage = computed(() => {
  if (!formConfig.value.pages || formConfig.value.pages.length === 0) {
    return null;
  }
  return formConfig.value.pages[selectedPage.value] || formConfig.value.pages[0];
});

const isLastPage = computed(() => {
  return selectedPage.value === (formConfig.value.pages.length - 1);
});

const isFirstPage = computed(() => {
  return selectedPage.value === 0;
});

const totalPages = computed(() => {
  return formConfig.value.pages.length;
});

const hasMultiplePages = computed(() => {
  return totalPages.value > 1;
});

// Form preview (collapsed view)
const formPreview = computed(() => {
  const preview = {
    title: formConfig.value.title,
    description: formConfig.value.description,
    fieldCount: 0,
    requiredFields: 0
  };

  formConfig.value.pages.forEach(page => {
    if (page.items) {
      preview.fieldCount += page.items.length;
      preview.requiredFields += page.items.filter(item => item.required).length;
    }
  });

  return preview;
});

// Form interaction methods
const toggleExpanded = () => {
  isExpanded.value = !isExpanded.value;
  if (isExpanded.value) {
    selectedPage.value = 0;
  }
};

const nextPage = () => {
  if (!isLastPage.value) {
    selectedPage.value++;
  }
};

const previousPage = () => {
  if (!isFirstPage.value) {
    selectedPage.value--;
  }
};

const updateResponse = (itemId, value) => {
  responses.value[itemId] = value;
};

const validateCurrentPage = () => {
  if (!currentPage.value) return true;

  const requiredFields = currentPage.value.items.filter(item => item.required);
  const missingFields = requiredFields.filter(field => {
    const response = responses.value[field.item_id];
    return !response || (typeof response === 'string' && response.trim() === '');
  });

  if (missingFields.length > 0) {
    hasErrors.value = true;
    errorMessage.value = `Please fill in all required fields: ${missingFields.map(f => f.title).join(', ')}`;
    return false;
  }

  hasErrors.value = false;
  errorMessage.value = '';
  return true;
};

const submitForm = () => {
  if (!validateCurrentPage()) {
    return;
  }

  isSubmitting.value = true;
  errorMessage.value = '';

  // In a real implementation, this would call the FormService
  setTimeout(() => {
    isSubmitting.value = false;
    isExpanded.value = false;
  }, 2000);
};

const cancelForm = () => {
  isExpanded.value = false;
  responses.value = {};
  selectedPage.value = 0;
  hasErrors.value = false;
  errorMessage.value = '';
};

// Format field value for display
const formatFieldValue = (item, value) => {
  if (!value) return '';

  switch (item.item_type) {
    case 'singleSelect':
    case 'multiSelect':
      if (Array.isArray(value)) {
        return value.map(v => {
          const option = item.options?.find(opt => opt.value === v);
          return option?.title || v;
        }).join(', ');
      } else {
        const option = item.options?.find(opt => opt.value === value);
        return option?.title || value;
      }
    case 'toggle':
      return value ? 'Yes' : 'No';
    case 'dateTime':
      return new Date(value).toLocaleDateString();
    default:
      return value.toString();
  }
};

// Get field input type
const getInputType = (item) => {
  switch (item.item_type) {
    case 'email':
      return 'email';
    case 'phone':
      return 'tel';
    case 'dateTime':
      return 'datetime-local';
    default:
      return 'text';
  }
};
</script>

<template>
  <BaseBubble>
    <!-- Collapsed Form Preview -->
    <div
      v-if="!isExpanded"
      class="apple-form-preview cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors p-4 rounded-lg border border-slate-200 dark:border-slate-600"
      @click="toggleExpanded"
    >
      <div class="flex items-start space-x-3">
        <!-- Form Icon -->
        <div class="w-10 h-10 bg-blue-500 rounded-lg flex items-center justify-center flex-shrink-0">
          <svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 24 24">
            <path d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z" />
          </svg>
        </div>

        <!-- Form Info -->
        <div class="flex-1 min-w-0">
          <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1">
            {{ formPreview.title }}
          </h3>
          <p v-if="formPreview.description" class="text-sm text-slate-600 dark:text-slate-400 mb-2 line-clamp-2">
            {{ formPreview.description }}
          </p>
          <div class="flex items-center space-x-4 text-xs text-slate-500 dark:text-slate-400">
            <span>{{ formPreview.fieldCount }} fields</span>
            <span v-if="formPreview.requiredFields > 0">{{ formPreview.requiredFields }} required</span>
            <span v-if="hasMultiplePages">{{ totalPages }} pages</span>
          </div>
        </div>

        <!-- Expand Arrow -->
        <div class="flex-shrink-0">
          <svg class="w-5 h-5 text-slate-400" fill="currentColor" viewBox="0 0 24 24">
            <path d="M7.41,8.58L12,13.17L16.59,8.58L18,10L12,16L6,10L7.41,8.58Z" />
          </svg>
        </div>
      </div>
    </div>

    <!-- Expanded Form -->
    <div
      v-else
      class="apple-form-expanded bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-600 overflow-hidden max-w-md"
    >
      <!-- Form Header -->
      <div class="form-header bg-blue-500 text-white p-4">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-lg font-semibold">{{ formConfig.title }}</h3>
            <p v-if="formConfig.description" class="text-blue-100 text-sm mt-1">
              {{ formConfig.description }}
            </p>
          </div>
          <button
            @click="cancelForm"
            class="text-blue-200 hover:text-white transition-colors"
          >
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z" />
            </svg>
          </button>
        </div>

        <!-- Progress Indicator -->
        <div v-if="hasMultiplePages" class="mt-3 flex items-center space-x-2">
          <div
            v-for="(page, index) in formConfig.pages"
            :key="page.page_id"
            :class="[
              'w-2 h-2 rounded-full transition-colors',
              index <= selectedPage ? 'bg-white' : 'bg-blue-300'
            ]"
          />
          <span class="text-blue-100 text-xs ml-2">
            Page {{ selectedPage + 1 }} of {{ totalPages }}
          </span>
        </div>
      </div>

      <!-- Form Content -->
      <div v-if="currentPage" class="form-content p-4">
        <!-- Page Title -->
        <div v-if="currentPage.title && hasMultiplePages" class="mb-4">
          <h4 class="text-lg font-medium text-slate-900 dark:text-slate-100">
            {{ currentPage.title }}
          </h4>
          <p v-if="currentPage.description" class="text-sm text-slate-600 dark:text-slate-400 mt-1">
            {{ currentPage.description }}
          </p>
        </div>

        <!-- Form Fields -->
        <div class="space-y-4">
          <div
            v-for="item in currentPage.items"
            :key="item.item_id"
            class="form-field"
          >
            <!-- Field Label -->
            <label :for="item.item_id" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
              {{ item.title }}
              <span v-if="item.required" class="text-red-500">*</span>
            </label>

            <!-- Field Description -->
            <p v-if="item.description" class="text-xs text-slate-500 dark:text-slate-400 mb-2">
              {{ item.description }}
            </p>

            <!-- Text Input -->
            <input
              v-if="['text', 'email', 'phone'].includes(item.item_type)"
              :id="item.item_id"
              :type="getInputType(item)"
              :placeholder="item.placeholder"
              :maxlength="item.max_length"
              :value="responses[item.item_id] || ''"
              @input="updateResponse(item.item_id, $event.target.value)"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-slate-700 dark:text-white"
            />

            <!-- Text Area -->
            <textarea
              v-else-if="item.item_type === 'textArea'"
              :id="item.item_id"
              :placeholder="item.placeholder"
              :maxlength="item.max_length"
              :value="responses[item.item_id] || ''"
              @input="updateResponse(item.item_id, $event.target.value)"
              rows="3"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-slate-700 dark:text-white"
            />

            <!-- Single Select -->
            <select
              v-else-if="item.item_type === 'singleSelect'"
              :id="item.item_id"
              :value="responses[item.item_id] || ''"
              @change="updateResponse(item.item_id, $event.target.value)"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-slate-700 dark:text-white"
            >
              <option value="">Select an option...</option>
              <option
                v-for="option in item.options"
                :key="option.value"
                :value="option.value"
              >
                {{ option.title }}
              </option>
            </select>

            <!-- Multi Select -->
            <div v-else-if="item.item_type === 'multiSelect'" class="space-y-2">
              <label
                v-for="option in item.options"
                :key="option.value"
                class="flex items-center space-x-2 cursor-pointer"
              >
                <input
                  type="checkbox"
                  :value="option.value"
                  :checked="(responses[item.item_id] || []).includes(option.value)"
                  @change="updateResponse(item.item_id, $event.target.checked ?
                    [...(responses[item.item_id] || []), option.value] :
                    (responses[item.item_id] || []).filter(v => v !== option.value))"
                  class="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                />
                <span class="text-sm text-slate-700 dark:text-slate-300">{{ option.title }}</span>
              </label>
            </div>

            <!-- Toggle -->
            <label
              v-else-if="item.item_type === 'toggle'"
              class="flex items-center space-x-2 cursor-pointer"
            >
              <input
                type="checkbox"
                :checked="responses[item.item_id] || false"
                @change="updateResponse(item.item_id, $event.target.checked)"
                class="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
              />
              <span class="text-sm text-slate-700 dark:text-slate-300">{{ item.title }}</span>
            </label>

            <!-- Date/Time -->
            <input
              v-else-if="item.item_type === 'dateTime'"
              :id="item.item_id"
              type="datetime-local"
              :min="item.min_date"
              :max="item.max_date"
              :value="responses[item.item_id] || ''"
              @input="updateResponse(item.item_id, $event.target.value)"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 dark:bg-slate-700 dark:text-white"
            />

            <!-- Stepper -->
            <div v-else-if="item.item_type === 'stepper'" class="flex items-center space-x-3">
              <button
                @click="updateResponse(item.item_id, Math.max((responses[item.item_id] || item.default_value || item.min_value) - (item.step || 1), item.min_value))"
                class="w-8 h-8 bg-slate-200 dark:bg-slate-600 rounded-full flex items-center justify-center"
              >
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M19,13H5V11H19V13Z" />
                </svg>
              </button>
              <span class="text-lg font-medium min-w-[3rem] text-center">
                {{ responses[item.item_id] || item.default_value || item.min_value }}
              </span>
              <button
                @click="updateResponse(item.item_id, Math.min((responses[item.item_id] || item.default_value || item.min_value) + (item.step || 1), item.max_value))"
                class="w-8 h-8 bg-slate-200 dark:bg-slate-600 rounded-full flex items-center justify-center"
              >
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M19,13H13V19H11V13H5V11H11V5H13V11H19V13Z" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        <!-- Error Message -->
        <div v-if="hasErrors" class="mt-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md">
          <p class="text-sm text-red-600 dark:text-red-400">{{ errorMessage }}</p>
        </div>
      </div>

      <!-- Form Actions -->
      <div class="form-actions p-4 bg-slate-50 dark:bg-slate-700 border-t border-slate-200 dark:border-slate-600">
        <div class="flex items-center justify-between">
          <!-- Previous Button -->
          <button
            v-if="hasMultiplePages && !isFirstPage"
            @click="previousPage"
            class="px-4 py-2 text-slate-600 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200 transition-colors"
          >
            ← Previous
          </button>
          <div v-else></div>

          <div class="flex space-x-2">
            <!-- Cancel Button -->
            <button
              @click="cancelForm"
              class="px-4 py-2 text-slate-600 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200 transition-colors"
            >
              {{ formConfig.cancelButton.title }}
            </button>

            <!-- Next/Submit Button -->
            <button
              v-if="!isLastPage"
              @click="nextPage"
              class="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 transition-colors"
            >
              Next →
            </button>
            <button
              v-else
              @click="submitForm"
              :disabled="isSubmitting"
              class="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 transition-colors disabled:opacity-50"
            >
              <span v-if="isSubmitting" class="flex items-center space-x-2">
                <div class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                <span>Submitting...</span>
              </span>
              <span v-else>{{ formConfig.submitButton.title }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>

<style lang="scss" scoped>
.apple-form-preview {
  @apply max-w-sm;
}

.apple-form-expanded {
  @apply w-full;
  max-width: 28rem;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.form-field {
  @apply relative;

  input, textarea, select {
    @apply transition-colors;
  }

  input:focus, textarea:focus, select:focus {
    @apply ring-2 ring-woot-500;
  }
}
</style>