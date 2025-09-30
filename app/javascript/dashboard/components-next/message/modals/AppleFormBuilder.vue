<script>
import { ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import AppleForm from '../bubbles/AppleForm.vue';

export default {
  components: {
    AppleForm,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    mspId: {
      type: String,
      required: true,
    },
    conversationId: {
      type: String,
      required: true,
    },
  },
  emits: ['close', 'create'],
  setup(props, { emit }) {
    const { t } = useI18n();

    // Form builder state
    const formData = ref({
      title: '',
      description: '',
      pages: []
    });

    const activeTab = ref('builder'); // 'builder', 'preview', 'templates'
    const selectedTemplate = ref(null);
    const currentPageIndex = ref(0);
    const showAddFieldModal = ref(false);
    const selectedFieldType = ref('text');

    // Field types configuration
    const fieldTypes = ref([
      { value: 'text', label: 'Text Input', icon: '📝', description: 'Single line text input' },
      { value: 'textArea', label: 'Text Area', icon: '📄', description: 'Multi-line text input' },
      { value: 'email', label: 'Email', icon: '📧', description: 'Email address input' },
      { value: 'phone', label: 'Phone', icon: '📱', description: 'Phone number input' },
      { value: 'singleSelect', label: 'Single Choice', icon: '🔘', description: 'Select one option' },
      { value: 'multiSelect', label: 'Multiple Choice', icon: '☑️', description: 'Select multiple options' },
      { value: 'dateTime', label: 'Date & Time', icon: '📅', description: 'Date and time picker' },
      { value: 'toggle', label: 'Toggle', icon: '🔄', description: 'Yes/No toggle switch' },
      { value: 'stepper', label: 'Number Stepper', icon: '🔢', description: 'Number input with +/- buttons' },
      { value: 'richLink', label: 'Rich Link', icon: '🔗', description: 'Clickable link with preview' },
    ]);

    // Form templates
    const formTemplates = ref([
      {
        id: 'contact',
        name: 'Contact Form',
        description: 'Basic contact information form',
        icon: '👤',
        fields: ['name', 'email', 'phone', 'message']
      },
      {
        id: 'feedback',
        name: 'Feedback Form',
        description: 'Customer feedback and rating form',
        icon: '⭐',
        fields: ['rating', 'comments', 'recommend']
      },
      {
        id: 'appointment',
        name: 'Appointment Booking',
        description: 'Schedule appointments and meetings',
        icon: '📅',
        fields: ['name', 'date', 'service', 'notes']
      },
      {
        id: 'survey',
        name: 'Survey Form',
        description: 'Multi-page customer survey',
        icon: '📊',
        fields: ['demographics', 'preferences', 'satisfaction']
      },
      {
        id: 'order',
        name: 'Order Form',
        description: 'Product ordering and billing',
        icon: '🛒',
        fields: ['product', 'quantity', 'billing', 'terms']
      }
    ]);

    // New field data
    const newField = ref({
      item_id: '',
      item_type: 'text',
      title: '',
      description: '',
      required: false,
      placeholder: '',
      options: [{ value: '', title: '' }],
      min_value: 1,
      max_value: 10,
      max_length: null,
      url: '',
      default_value: ''
    });

    // Computed properties
    const currentPage = computed(() => {
      if (!formData.value.pages || formData.value.pages.length === 0) {
        return null;
      }
      return formData.value.pages[currentPageIndex.value];
    });

    const canCreateForm = computed(() => {
      return formData.value.title.trim().length > 0 &&
             formData.value.pages.length > 0 &&
             formData.value.pages.some(page => page.items && page.items.length > 0);
    });

    const formPreview = computed(() => {
      return {
        form_id: `form_${Date.now()}`,
        title: formData.value.title,
        description: formData.value.description,
        pages: formData.value.pages,
        version: '1.0',
        submit_button: { title: 'Submit' },
        cancel_button: { title: 'Cancel' }
      };
    });

    const totalFields = computed(() => {
      return formData.value.pages.reduce((total, page) => {
        return total + (page.items ? page.items.length : 0);
      }, 0);
    });

    // Methods
    const initializeForm = () => {
      formData.value = {
        title: '',
        description: '',
        pages: []
      };
      currentPageIndex.value = 0;
      activeTab.value = 'builder';
      selectedTemplate.value = null;
    };

    const addNewPage = () => {
      const pageNumber = formData.value.pages.length + 1;
      const newPage = {
        page_id: `page_${pageNumber}`,
        title: `Page ${pageNumber}`,
        description: '',
        items: []
      };

      formData.value.pages.push(newPage);
      currentPageIndex.value = formData.value.pages.length - 1;
    };

    const removePage = (index) => {
      if (formData.value.pages.length > 1) {
        formData.value.pages.splice(index, 1);
        if (currentPageIndex.value >= formData.value.pages.length) {
          currentPageIndex.value = formData.value.pages.length - 1;
        }
      }
    };

    const openAddFieldModal = () => {
      resetNewField();
      showAddFieldModal.value = true;
    };

    const resetNewField = () => {
      newField.value = {
        item_id: '',
        item_type: 'text',
        title: '',
        description: '',
        required: false,
        placeholder: '',
        options: [{ value: '', title: '' }],
        min_value: 1,
        max_value: 10,
        max_length: null,
        url: '',
        default_value: ''
      };
    };

    const addFieldToCurrentPage = () => {
      if (!currentPage.value) return;

      // Generate item_id if not provided
      if (!newField.value.item_id) {
        const fieldCount = currentPage.value.items.length;
        newField.value.item_id = `field_${currentPageIndex.value + 1}_${fieldCount + 1}`;
      }

      // Clean up field data based on type
      const fieldData = { ...newField.value };

      // Remove unused properties based on field type
      if (!['singleSelect', 'multiSelect'].includes(fieldData.item_type)) {
        delete fieldData.options;
      }

      if (fieldData.item_type !== 'stepper') {
        delete fieldData.min_value;
        delete fieldData.max_value;
      }

      if (!['text', 'textArea', 'email'].includes(fieldData.item_type)) {
        delete fieldData.max_length;
      }

      if (fieldData.item_type !== 'richLink') {
        delete fieldData.url;
      }

      // Filter out options with empty values
      if (fieldData.options) {
        fieldData.options = fieldData.options.filter(opt => opt.value && opt.title);
      }

      currentPage.value.items.push(fieldData);
      showAddFieldModal.value = false;
      resetNewField();
    };

    const removeField = (fieldIndex) => {
      if (currentPage.value && currentPage.value.items) {
        currentPage.value.items.splice(fieldIndex, 1);
      }
    };

    const addOption = () => {
      newField.value.options.push({ value: '', title: '' });
    };

    const removeOption = (index) => {
      if (newField.value.options.length > 1) {
        newField.value.options.splice(index, 1);
      }
    };

    const loadTemplate = (templateId) => {
      // This would typically load from the FormBuilderService templates

      switch (templateId) {
        case 'contact':
          formData.value = {
            title: 'Contact Form',
            description: 'We\'d love to hear from you',
            pages: [{
              page_id: 'page_1',
              title: 'Contact Information',
              description: 'Please provide your contact details',
              items: [
                { item_id: 'full_name', item_type: 'text', title: 'Full Name', required: true, placeholder: 'Enter your full name' },
                { item_id: 'email', item_type: 'email', title: 'Email Address', required: true, placeholder: 'your.email@example.com' },
                { item_id: 'phone', item_type: 'phone', title: 'Phone Number', required: false, placeholder: '+1 (555) 123-4567' },
                {
                  item_id: 'preferred_contact',
                  item_type: 'singleSelect',
                  title: 'Preferred Contact Method',
                  required: true,
                  options: [
                    { value: 'email', title: 'Email' },
                    { value: 'phone', title: 'Phone Call' },
                    { value: 'text', title: 'Text Message' }
                  ]
                }
              ]
            }]
          };
          break;
        case 'feedback':
          formData.value = {
            title: 'Customer Feedback',
            description: 'Your opinion matters to us',
            pages: [{
              page_id: 'page_1',
              title: 'Feedback',
              description: 'Help us improve our service',
              items: [
                {
                  item_id: 'rating',
                  item_type: 'singleSelect',
                  title: 'Overall Rating',
                  required: true,
                  options: [
                    { value: '5', title: '5 ★★★★★' },
                    { value: '4', title: '4 ★★★★' },
                    { value: '3', title: '3 ★★★' },
                    { value: '2', title: '2 ★★' },
                    { value: '1', title: '1 ★' }
                  ]
                },
                { item_id: 'comments', item_type: 'textArea', title: 'Comments', required: false, placeholder: 'Tell us about your experience...', max_length: 500 },
                { item_id: 'recommend', item_type: 'toggle', title: 'Would you recommend us to others?', required: false, default_value: true }
              ]
            }]
          };
          break;
        default:
          // Unknown template - using default empty form
      }

      currentPageIndex.value = 0;
      activeTab.value = 'builder';
    };

    const createForm = () => {
      if (!canCreateForm.value) return;

      const formConfig = formPreview.value;

      emit('create', {
        content_type: 'apple_form',
        content_attributes: formConfig
      });

      emit('close');
      initializeForm();
    };

    const closeModal = () => {
      emit('close');
      initializeForm();
    };

    // Initialize with one page when modal opens
    watch(() => props.show, (newShow) => {
      if (newShow) {
        nextTick(() => {
          if (formData.value.pages.length === 0) {
            addNewPage();
          }
        });
      }
    });

    return {
      formData,
      activeTab,
      selectedTemplate,
      currentPageIndex,
      showAddFieldModal,
      selectedFieldType,
      fieldTypes,
      formTemplates,
      newField,
      currentPage,
      canCreateForm,
      formPreview,
      totalFields,
      initializeForm,
      addNewPage,
      removePage,
      openAddFieldModal,
      resetNewField,
      addFieldToCurrentPage,
      removeField,
      addOption,
      removeOption,
      loadTemplate,
      createForm,
      closeModal,
      t
    };
  }
};
</script>

<template>
  <div v-if="show" class="fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-50 flex items-center justify-center p-4">
    <div class="bg-white dark:bg-slate-800 rounded-lg max-w-4xl w-full max-h-full overflow-hidden flex flex-col">
      <!-- Modal Header -->
      <div class="flex items-center justify-between p-6 border-b border-slate-200 dark:border-slate-600">
        <div>
          <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-100">
            Create Apple Form Message
          </h2>
          <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">
            Build interactive forms for Apple Messages
          </p>
        </div>
        <button
          @click="closeModal"
          class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
        >
          <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
            <path d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z" />
          </svg>
        </button>
      </div>

      <!-- Tab Navigation -->
      <div class="flex border-b border-slate-200 dark:border-slate-600">
        <button
          :class="['px-6 py-3 text-sm font-medium border-b-2 transition-colors',
                   activeTab === 'templates' ? 'border-woot-500 text-woot-600 dark:text-woot-400' : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300']"
          @click="activeTab = 'templates'"
        >
          📋 Templates
        </button>
        <button
          :class="['px-6 py-3 text-sm font-medium border-b-2 transition-colors',
                   activeTab === 'builder' ? 'border-woot-500 text-woot-600 dark:text-woot-400' : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300']"
          @click="activeTab = 'builder'"
        >
          🔧 Builder
        </button>
        <button
          :class="['px-6 py-3 text-sm font-medium border-b-2 transition-colors',
                   activeTab === 'preview' ? 'border-woot-500 text-woot-600 dark:text-woot-400' : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300']"
          @click="activeTab = 'preview'"
        >
          👁️ Preview
        </button>
      </div>

      <!-- Tab Content -->
      <div class="flex-1 overflow-y-auto">
        <!-- Templates Tab -->
        <div v-if="activeTab === 'templates'" class="p-6">
          <h3 class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4">
            Choose a Template
          </h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <button
              v-for="template in formTemplates"
              :key="template.id"
              @click="loadTemplate(template.id)"
              class="text-left p-4 border-2 border-slate-200 dark:border-slate-600 rounded-lg hover:border-woot-500 dark:hover:border-woot-400 transition-colors"
            >
              <div class="flex items-center space-x-3">
                <div class="text-2xl">{{ template.icon }}</div>
                <div>
                  <h4 class="font-medium text-slate-900 dark:text-slate-100">{{ template.name }}</h4>
                  <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">{{ template.description }}</p>
                  <div class="flex flex-wrap gap-1 mt-2">
                    <span
                      v-for="field in template.fields.slice(0, 3)"
                      :key="field"
                      class="px-2 py-1 text-xs bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400 rounded"
                    >
                      {{ field }}
                    </span>
                    <span v-if="template.fields.length > 3" class="px-2 py-1 text-xs text-slate-500 dark:text-slate-400">
                      +{{ template.fields.length - 3 }} more
                    </span>
                  </div>
                </div>
              </div>
            </button>
          </div>
        </div>

        <!-- Builder Tab -->
        <div v-else-if="activeTab === 'builder'" class="flex h-full">
          <!-- Form Configuration -->
          <div class="w-1/2 p-6 border-r border-slate-200 dark:border-slate-600">
            <!-- Form Basic Info -->
            <div class="mb-6">
              <h3 class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4">Form Details</h3>
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Form Title *
                  </label>
                  <input
                    v-model="formData.title"
                    type="text"
                    placeholder="Enter form title"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Description
                  </label>
                  <textarea
                    v-model="formData.description"
                    rows="2"
                    placeholder="Optional form description"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                  />
                </div>
              </div>
            </div>

            <!-- Pages Management -->
            <div class="mb-6">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-medium text-slate-900 dark:text-slate-100">Pages</h3>
                <button
                  @click="addNewPage"
                  class="px-3 py-1 bg-blue-500 text-white text-sm rounded-md hover:bg-blue-600 transition-colors"
                >
                  + Add Page
                </button>
              </div>

              <div class="space-y-2">
                <div
                  v-for="(page, index) in formData.pages"
                  :key="page.page_id"
                  :class="['flex items-center justify-between p-3 rounded-lg border cursor-pointer transition-colors',
                           index === currentPageIndex ? 'border-woot-500 bg-woot-50 dark:bg-woot-900/20' : 'border-slate-200 dark:border-slate-600 hover:border-slate-300']"
                  @click="currentPageIndex = index"
                >
                  <div class="flex-1">
                    <input
                      v-model="page.title"
                      @click.stop
                      class="font-medium text-slate-900 dark:text-slate-100 bg-transparent border-none p-0 focus:outline-none"
                    />
                    <p class="text-sm text-slate-600 dark:text-slate-400">
                      {{ page.items ? page.items.length : 0 }} fields
                    </p>
                  </div>
                  <button
                    v-if="formData.pages.length > 1"
                    @click.stop="removePage(index)"
                    class="text-red-500 hover:text-red-700 transition-colors ml-2"
                  >
                    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>

            <!-- Current Page Fields -->
            <div v-if="currentPage">
              <div class="flex items-center justify-between mb-4">
                <h4 class="text-md font-medium text-slate-900 dark:text-slate-100">
                  Fields - {{ currentPage.title }}
                </h4>
                <button
                  @click="openAddFieldModal"
                  class="px-3 py-1 bg-green-500 text-white text-sm rounded-md hover:bg-green-600 transition-colors"
                >
                  + Add Field
                </button>
              </div>

              <div class="space-y-2">
                <div
                  v-for="(field, index) in currentPage.items"
                  :key="field.item_id"
                  class="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-700 rounded-lg"
                >
                  <div>
                    <div class="font-medium text-slate-900 dark:text-slate-100">{{ field.title }}</div>
                    <div class="text-sm text-slate-600 dark:text-slate-400">
                      {{ fieldTypes.find(t => t.value === field.item_type)?.label || field.item_type }}
                      <span v-if="field.required" class="text-red-500 ml-1">*</span>
                    </div>
                  </div>
                  <button
                    @click="removeField(index)"
                    class="text-red-500 hover:text-red-700 transition-colors"
                  >
                    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Page Configuration -->
          <div class="w-1/2 p-6">
            <div v-if="currentPage">
              <h3 class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4">
                Page Configuration
              </h3>
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Page Title
                  </label>
                  <input
                    v-model="currentPage.title"
                    type="text"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Page Description
                  </label>
                  <textarea
                    v-model="currentPage.description"
                    rows="2"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Preview Tab -->
        <div v-else-if="activeTab === 'preview'" class="p-6">
          <h3 class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4">
            Form Preview
          </h3>
          <div class="flex justify-center">
            <AppleForm :content-attributes="formPreview" />
          </div>
        </div>
      </div>

      <!-- Modal Footer -->
      <div class="flex items-center justify-between p-6 border-t border-slate-200 dark:border-slate-600">
        <div class="text-sm text-slate-600 dark:text-slate-400">
          {{ formData.pages.length }} pages, {{ totalFields }} fields
        </div>
        <div class="flex space-x-3">
          <button
            @click="closeModal"
            class="px-4 py-2 text-slate-600 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200 transition-colors"
          >
            Cancel
          </button>
          <button
            @click="createForm"
            :disabled="!canCreateForm"
            class="px-4 py-2 bg-woot-500 text-white rounded-md hover:bg-woot-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Create Form Message
          </button>
        </div>
      </div>
    </div>

    <!-- Add Field Modal -->
    <div v-if="showAddFieldModal" class="fixed inset-0 z-60 overflow-y-auto bg-black bg-opacity-50 flex items-center justify-center p-4">
      <div class="bg-white dark:bg-slate-800 rounded-lg max-w-2xl w-full max-h-full overflow-hidden">
        <div class="p-6">
          <h3 class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4">Add Form Field</h3>

          <!-- Field Type Selection -->
          <div class="mb-4">
            <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Field Type</label>
            <div class="grid grid-cols-2 gap-2">
              <button
                v-for="fieldType in fieldTypes"
                :key="fieldType.value"
                @click="newField.item_type = fieldType.value"
                :class="['text-left p-3 border-2 rounded-lg transition-colors',
                         newField.item_type === fieldType.value ? 'border-woot-500 bg-woot-50 dark:bg-woot-900/20' : 'border-slate-200 dark:border-slate-600 hover:border-slate-300']"
              >
                <div class="flex items-center space-x-2">
                  <span class="text-lg">{{ fieldType.icon }}</span>
                  <div>
                    <div class="font-medium text-slate-900 dark:text-slate-100 text-sm">{{ fieldType.label }}</div>
                    <div class="text-xs text-slate-600 dark:text-slate-400">{{ fieldType.description }}</div>
                  </div>
                </div>
              </button>
            </div>
          </div>

          <!-- Basic Field Configuration -->
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Field Title *</label>
              <input
                v-model="newField.title"
                type="text"
                placeholder="Enter field title"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Field ID</label>
              <input
                v-model="newField.item_id"
                type="text"
                placeholder="Auto-generated if empty"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Description</label>
              <input
                v-model="newField.description"
                type="text"
                placeholder="Optional field description"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
              />
            </div>

            <div class="flex items-center space-x-2">
              <input
                v-model="newField.required"
                type="checkbox"
                class="rounded border-slate-300 text-woot-600 focus:ring-woot-500"
              />
              <label class="text-sm text-slate-700 dark:text-slate-300">Required field</label>
            </div>

            <!-- Field-specific configuration -->
            <!-- Text fields -->
            <div v-if="['text', 'textArea', 'email', 'phone'].includes(newField.item_type)" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Placeholder</label>
                <input
                  v-model="newField.placeholder"
                  type="text"
                  placeholder="Placeholder text"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                />
              </div>
              <div v-if="['text', 'textArea'].includes(newField.item_type)">
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Max Length</label>
                <input
                  v-model="newField.max_length"
                  type="number"
                  placeholder="Maximum character limit"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                />
              </div>
            </div>

            <!-- Select fields -->
            <div v-if="['singleSelect', 'multiSelect'].includes(newField.item_type)" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Options</label>
                <div class="space-y-2">
                  <div
                    v-for="(option, index) in newField.options"
                    :key="index"
                    class="flex items-center space-x-2"
                  >
                    <input
                      v-model="option.value"
                      type="text"
                      placeholder="Option value"
                      class="flex-1 px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                    />
                    <input
                      v-model="option.title"
                      type="text"
                      placeholder="Option label"
                      class="flex-1 px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                    />
                    <button
                      @click="removeOption(index)"
                      class="text-red-500 hover:text-red-700 transition-colors"
                    >
                      <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z" />
                      </svg>
                    </button>
                  </div>
                  <button
                    @click="addOption"
                    class="w-full py-2 border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-md text-slate-600 dark:text-slate-400 hover:border-slate-400 dark:hover:border-slate-500 transition-colors"
                  >
                    + Add Option
                  </button>
                </div>
              </div>
            </div>

            <!-- Stepper fields -->
            <div v-if="newField.item_type === 'stepper'" class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Min Value</label>
                <input
                  v-model.number="newField.min_value"
                  type="number"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Max Value</label>
                <input
                  v-model.number="newField.max_value"
                  type="number"
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                />
              </div>
            </div>

            <!-- Rich Link fields -->
            <div v-if="newField.item_type === 'richLink'">
              <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">URL</label>
              <input
                v-model="newField.url"
                type="url"
                placeholder="https://example.com"
                class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
              />
            </div>
          </div>

          <div class="flex justify-end space-x-3 mt-6">
            <button
              @click="showAddFieldModal = false"
              class="px-4 py-2 text-slate-600 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200 transition-colors"
            >
              Cancel
            </button>
            <button
              @click="addFieldToCurrentPage"
              :disabled="!newField.title"
              class="px-4 py-2 bg-woot-500 text-white rounded-md hover:bg-woot-600 transition-colors disabled:opacity-50"
            >
              Add Field
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>