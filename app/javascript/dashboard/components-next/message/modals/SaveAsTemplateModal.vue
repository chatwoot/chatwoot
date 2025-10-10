<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  messageType: {
    type: String,
    required: true,
    validator: value =>
      [
        'quick_reply',
        'list_picker',
        'time_picker',
        'form',
        'imessage_app',
        'oauth',
        'apple_pay',
      ].includes(value),
  },
  messageData: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close', 'save', 'saveAndSend']);

const { t } = useI18n();
const store = useStore();

// Form state
const templateName = ref('');
const shortCode = ref('');
const category = ref('general');
const description = ref('');
const tags = ref('');
const isValidatingShortCode = ref(false);
const shortCodeError = ref('');

// Category options - must match MessageTemplate::CATEGORIES
const categoryOptions = [
  { value: 'general', label: 'General' },
  { value: 'payment', label: 'Payment' },
  { value: 'scheduling', label: 'Scheduling' },
  { value: 'support', label: 'Support' },
  { value: 'marketing', label: 'Marketing' },
  { value: 'feedback', label: 'Feedback' },
  { value: 'notification', label: 'Notification' },
  { value: 'confirmation', label: 'Confirmation' },
  { value: 'sales', label: 'Sales' },
];

// Computed
const existingCannedResponses = computed(() => {
  return store.getters.getCannedResponses || [];
});

const isShortCodeUnique = computed(() => {
  if (!shortCode.value) return true;
  return !existingCannedResponses.value.some(
    response =>
      response.short_code.toLowerCase() === shortCode.value.toLowerCase()
  );
});

const isFormValid = computed(() => {
  return (
    templateName.value.trim().length > 0 && description.value.trim().length > 0
  );
});

// Methods
const generateTemplateName = () => {
  const typeMap = {
    quick_reply: 'Quick Reply',
    list_picker: 'List Picker',
    time_picker: 'Time Picker',
    form: 'Form',
    imessage_app: 'iMessage App',
    oauth: 'OAuth',
    apple_pay: 'Apple Pay',
  };

  const baseType = typeMap[props.messageType] || props.messageType;

  // Extract meaningful content from messageData
  let contentSuffix = '';

  switch (props.messageType) {
    case 'quick_reply':
      if (props.messageData.title) {
        contentSuffix = props.messageData.title
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .substring(0, 30);
      }
      break;
    case 'list_picker':
      if (props.messageData.title) {
        contentSuffix = props.messageData.title
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .substring(0, 30);
      }
      break;
    case 'time_picker':
      if (props.messageData.received_message?.title) {
        contentSuffix = props.messageData.received_message.title
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .substring(0, 30);
      } else if (props.messageData.receivedMessage?.title) {
        contentSuffix = props.messageData.receivedMessage.title
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .substring(0, 30);
      }
      break;
    case 'form':
      if (props.messageData.title) {
        contentSuffix = props.messageData.title
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, '_')
          .substring(0, 30);
      }
      break;
    default:
      break;
  }

  const baseName = contentSuffix
    ? `${baseType} ${contentSuffix}`
    : `${baseType} Template`;

  return baseName.replace(/\s+/g, '_').replace(/_+/g, '_').toLowerCase();
};

const generateShortCode = () => {
  const prefix = props.messageType.substring(0, 3);
  const timestamp = Date.now().toString().slice(-6);

  let baseShortCode = `${prefix}_${timestamp}`;

  // Ensure uniqueness
  let counter = 1;
  let candidateShortCode = baseShortCode;

  while (
    existingCannedResponses.value.some(
      response => response.short_code === candidateShortCode
    )
  ) {
    candidateShortCode = `${baseShortCode}_${counter}`;
    counter += 1;
  }

  return candidateShortCode;
};

const generateDescription = () => {
  const typeMap = {
    quick_reply: 'Quick reply message',
    list_picker: 'List picker with options',
    time_picker: 'Time picker for scheduling',
    form: 'Form for collecting information',
    imessage_app: 'iMessage app integration',
    oauth: 'OAuth authentication',
    apple_pay: 'Apple Pay payment request',
  };

  const baseDescription =
    typeMap[props.messageType] || 'Apple Messages template';

  // Add content-specific details
  let detailSuffix = '';

  switch (props.messageType) {
    case 'quick_reply':
      if (props.messageData.title) {
        detailSuffix = `: ${props.messageData.title}`;
      }
      break;
    case 'list_picker':
      if (props.messageData.title) {
        detailSuffix = `: ${props.messageData.title}`;
      }
      break;
    case 'time_picker':
      if (props.messageData.received_message?.title) {
        detailSuffix = `: ${props.messageData.received_message.title}`;
      } else if (props.messageData.receivedMessage?.title) {
        detailSuffix = `: ${props.messageData.receivedMessage.title}`;
      }
      break;
    case 'form':
      if (props.messageData.title) {
        detailSuffix = `: ${props.messageData.title}`;
      }
      break;
    default:
      break;
  }

  return `${baseDescription}${detailSuffix}`;
};

const detectCategory = () => {
  const messageType = props.messageType;
  const dataStr = JSON.stringify(props.messageData).toLowerCase();

  if (
    messageType === 'time_picker' ||
    dataStr.includes('appointment') ||
    dataStr.includes('schedule')
  ) {
    return 'scheduling';
  }
  if (
    messageType === 'apple_pay' ||
    dataStr.includes('payment') ||
    dataStr.includes('pay')
  ) {
    return 'payment';
  }
  if (
    messageType === 'quick_reply' &&
    (dataStr.includes('help') || dataStr.includes('support'))
  ) {
    return 'support';
  }
  if (
    dataStr.includes('buy') ||
    dataStr.includes('purchase') ||
    dataStr.includes('order')
  ) {
    return 'sales';
  }

  return 'general';
};

const initializeFormFields = () => {
  templateName.value = generateTemplateName();
  shortCode.value = generateShortCode();
  description.value = generateDescription();
  category.value = detectCategory();
  tags.value = '';
  shortCodeError.value = '';
};

const validateShortCode = () => {
  if (!shortCode.value.trim()) {
    shortCodeError.value = 'Short code is required';
    return false;
  }

  if (!isShortCodeUnique.value) {
    shortCodeError.value = 'Short code already exists';
    return false;
  }

  shortCodeError.value = '';
  return true;
};

const handleSave = async () => {
  if (!isFormValid.value) {
    useAlert('Please fill in all required fields');
    return;
  }

  try {
    const payload = {
      messageType: props.messageType,
      messageData: props.messageData,
      templateName: templateName.value.trim(),
      category: category.value,
      description: description.value.trim(),
      tags: tags.value
        .split(',')
        .map(tag => tag.trim())
        .filter(tag => tag.length > 0),
    };

    const template = await store.dispatch(
      'messageTemplates/createFromAppleMessage',
      payload
    );

    useAlert('Template saved successfully');
    emit('save', template);
    handleClose();
  } catch (error) {
    console.error('Failed to save template:', error);
    useAlert(
      error.response?.data?.details || 'Failed to save template',
      'error'
    );
  }
};

const handleSaveAndSend = async () => {
  if (!isFormValid.value) {
    useAlert('Please fill in all required fields');
    return;
  }

  try {
    const payload = {
      messageType: props.messageType,
      messageData: props.messageData,
      templateName: templateName.value.trim(),
      category: category.value,
      description: description.value.trim(),
      tags: tags.value
        .split(',')
        .map(tag => tag.trim())
        .filter(tag => tag.length > 0),
    };

    const template = await store.dispatch(
      'messageTemplates/createFromAppleMessage',
      payload
    );

    useAlert('Template saved successfully');
    emit('saveAndSend', { template, messageData: props.messageData });
    handleClose();
  } catch (error) {
    console.error('Failed to save template:', error);
    useAlert(
      error.response?.data?.details || 'Failed to save template',
      'error'
    );
  }
};

const handleClose = () => {
  emit('close');
};

// Watch props.show to initialize form
watch(
  () => props.show,
  newShow => {
    if (newShow) {
      initializeFormFields();
    }
  },
  { immediate: true }
);

// Watch shortCode for validation
watch(shortCode, () => {
  validateShortCode();
});

// Load canned responses on mount
onMounted(async () => {
  try {
    await store.dispatch('getCannedResponse');
  } catch (error) {
    console.error('Failed to load canned responses:', error);
  }
});
</script>

<template>
  <div
    v-if="show"
    class="fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-80 flex items-center justify-center p-4"
  >
    <div
      class="bg-white dark:bg-slate-800 rounded-lg max-w-2xl w-full max-h-full overflow-hidden flex flex-col shadow-2xl border-4 border-woot-500 dark:border-woot-400"
    >
      <!-- Header -->
      <div
        class="flex items-center justify-between p-6 border-b border-slate-200 dark:border-slate-600"
      >
        <div>
          <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-100">
            Save as Template
          </h2>
          <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">
            Save this {{ messageType.replace('_', ' ') }} configuration as a
            reusable template
          </p>
        </div>
        <button
          class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
          @click="handleClose"
        >
          <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
            <path
              d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z"
            />
          </svg>
        </button>
      </div>

      <!-- Form Content -->
      <div class="flex-1 overflow-y-auto p-6">
        <div class="space-y-4">
          <!-- Template Name -->
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              Template Name
              <span class="text-red-500">*</span>
            </label>
            <input
              v-model="templateName"
              type="text"
              placeholder="Enter a descriptive template name"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
              :class="{
                'border-red-500': templateName.trim().length === 0,
              }"
            />
            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
              A clear, descriptive name for your template
            </p>
          </div>

          <!-- Short Code -->
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              Short Code
              <span class="text-red-500">*</span>
            </label>
            <input
              v-model="shortCode"
              type="text"
              placeholder="Enter a unique short code"
              class="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
              :class="{
                'border-red-500': shortCodeError,
                'border-slate-300 dark:border-slate-600': !shortCodeError,
              }"
            />
            <p
              v-if="shortCodeError"
              class="text-xs text-red-500 dark:text-red-400 mt-1"
            >
              {{ shortCodeError }}
            </p>
            <p
              v-else-if="isShortCodeUnique && shortCode.trim().length > 0"
              class="text-xs text-green-600 dark:text-green-400 mt-1"
            >
              Short code is available
            </p>
            <p v-else class="text-xs text-slate-500 dark:text-slate-400 mt-1">
              A unique identifier to quickly find this template
            </p>
          </div>

          <!-- Category -->
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              Category
            </label>
            <select
              v-model="category"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
            >
              <option
                v-for="option in categoryOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Organize templates by category for easier discovery
            </p>
          </div>

          <!-- Description -->
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              Description
              <span class="text-red-500">*</span>
            </label>
            <textarea
              v-model="description"
              rows="3"
              placeholder="Describe what this template does and when to use it"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white resize-none"
              :class="{
                'border-red-500': description.trim().length === 0,
              }"
            />
            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Help team members understand when to use this template
            </p>
          </div>

          <!-- Tags -->
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              Tags (optional)
            </label>
            <input
              v-model="tags"
              type="text"
              placeholder="e.g., appointment, booking, urgent (comma-separated)"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
            />
            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Add tags to improve searchability (separate with commas)
            </p>
          </div>

          <!-- Preview Box -->
          <div
            class="bg-slate-50 dark:bg-slate-700 rounded-lg p-4 border border-slate-200 dark:border-slate-600"
          >
            <h4
              class="text-sm font-semibold text-slate-900 dark:text-slate-100 mb-2"
            >
              Template Preview
            </h4>
            <div class="space-y-2 text-sm">
              <div class="flex">
                <span class="text-slate-600 dark:text-slate-400 w-24">Type:</span>
                <span class="text-slate-900 dark:text-slate-100 font-medium">
                  {{ messageType.replace('_', ' ').toUpperCase() }}
                </span>
              </div>
              <div class="flex">
                <span class="text-slate-600 dark:text-slate-400 w-24">Code:</span>
                <span class="text-slate-900 dark:text-slate-100 font-mono">
                  {{ shortCode || '(not set)' }}
                </span>
              </div>
              <div class="flex">
                <span class="text-slate-600 dark:text-slate-400 w-24">Category:</span>
                <span class="text-slate-900 dark:text-slate-100 capitalize">
                  {{ category }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer Actions -->
      <div
        class="flex items-center justify-end space-x-3 p-6 border-t border-slate-200 dark:border-slate-600"
      >
        <button
          class="px-4 py-2 text-slate-600 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200 transition-colors"
          @click="handleClose"
        >
          Cancel
        </button>
        <button
          :disabled="!isFormValid"
          class="px-4 py-2 bg-slate-500 text-white rounded-md hover:bg-slate-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          @click="handleSave"
        >
          Save Template
        </button>
        <button
          :disabled="!isFormValid"
          class="px-4 py-2 bg-woot-500 text-white rounded-md hover:bg-woot-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          @click="handleSaveAndSend"
        >
          Save & Send
        </button>
      </div>
    </div>
  </div>
</template>
