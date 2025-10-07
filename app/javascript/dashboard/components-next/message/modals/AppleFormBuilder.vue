<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'create']);

const { t } = useI18n();

// Form builder state
const formData = ref({
  title: '',
  description: '',
  pages: [],
});

const activeTab = ref('builder'); // 'builder', 'preview', 'templates'
const selectedTemplate = ref(null);
const currentPageIndex = ref(0);
const showAddFieldModal = ref(false);

// Field types configuration
const fieldTypes = ref([
  {
    value: 'text',
    label: t('CONVERSATION.APPLE_FORM.FIELD_TYPES.TEXT'),
    icon: '📝',
    description: t('CONVERSATION.APPLE_FORM.FIELD_DESCRIPTIONS.TEXT'),
  },
  {
    value: 'textArea',
    label: t('CONVERSATION.APPLE_FORM.FIELD_TYPES.TEXT_AREA'),
    icon: '📄',
    description: t('CONVERSATION.APPLE_FORM.FIELD_DESCRIPTIONS.TEXT_AREA'),
  },
  {
    value: 'email',
    label: t('CONVERSATION.APPLE_FORM.FIELD_TYPES.EMAIL'),
    icon: '📧',
    description: t('CONVERSATION.APPLE_FORM.FIELD_DESCRIPTIONS.EMAIL'),
  },
  {
    value: 'phone',
    label: t('CONVERSATION.APPLE_FORM.FIELD_TYPES.PHONE'),
    icon: '📱',
    description: t('CONVERSATION.APPLE_FORM.FIELD_DESCRIPTIONS.PHONE'),
  },
  {
    value: 'singleSelect',
    label: t('CONVERSATION.APPLE_FORM.FIELD_TYPES.SINGLE_CHOICE'),
    icon: '🔘',
    description: t('CONVERSATION.APPLE_FORM.FIELD_DESCRIPTIONS.SINGLE_CHOICE'),
  },
  {
    value: 'multiSelect',
    label: t('CONVERSATION.APPLE_FORM.FIELD_TYPES.MULTIPLE_CHOICE'),
    icon: '☑️',
    description: t(
      'CONVERSATION.APPLE_FORM.FIELD_DESCRIPTIONS.MULTIPLE_CHOICE'
    ),
  },
  {
    value: 'dateTime',
    label: t('CONVERSATION.APPLE_FORM.FIELD_TYPES.DATE_TIME'),
    icon: '📅',
    description: t('CONVERSATION.APPLE_FORM.FIELD_DESCRIPTIONS.DATE_TIME'),
  },
  {
    value: 'toggle',
    label: t('CONVERSATION.APPLE_FORM.FIELD_TYPES.TOGGLE'),
    icon: '🔄',
    description: t('CONVERSATION.APPLE_FORM.FIELD_DESCRIPTIONS.TOGGLE'),
  },
  {
    value: 'stepper',
    label: t('CONVERSATION.APPLE_FORM.FIELD_TYPES.STEPPER'),
    icon: '🔢',
    description: t('CONVERSATION.APPLE_FORM.FIELD_DESCRIPTIONS.STEPPER'),
  },
  {
    value: 'richLink',
    label: t('CONVERSATION.APPLE_FORM.FIELD_TYPES.RICH_LINK'),
    icon: '🔗',
    description: t('CONVERSATION.APPLE_FORM.FIELD_DESCRIPTIONS.RICH_LINK'),
  },
]);

// Form templates
const formTemplates = ref([
  {
    id: 'contact',
    name: t('CONVERSATION.APPLE_FORM.TEMPLATES.CONTACT.NAME'),
    description: t('CONVERSATION.APPLE_FORM.TEMPLATES.CONTACT.DESCRIPTION'),
    icon: '👤',
    fields: ['name', 'email', 'phone', 'message'],
  },
  {
    id: 'feedback',
    name: t('CONVERSATION.APPLE_FORM.TEMPLATES.FEEDBACK.NAME'),
    description: t('CONVERSATION.APPLE_FORM.TEMPLATES.FEEDBACK.DESCRIPTION'),
    icon: '⭐',
    fields: ['rating', 'comments', 'recommend'],
  },
  {
    id: 'appointment',
    name: t('CONVERSATION.APPLE_FORM.TEMPLATES.APPOINTMENT.NAME'),
    description: t('CONVERSATION.APPLE_FORM.TEMPLATES.APPOINTMENT.DESCRIPTION'),
    icon: '📅',
    fields: ['name', 'date', 'service', 'notes'],
  },
  {
    id: 'survey',
    name: t('CONVERSATION.APPLE_FORM.TEMPLATES.SURVEY.NAME'),
    description: t('CONVERSATION.APPLE_FORM.TEMPLATES.SURVEY.DESCRIPTION'),
    icon: '📊',
    fields: ['demographics', 'preferences', 'satisfaction'],
  },
  {
    id: 'order',
    name: t('CONVERSATION.APPLE_FORM.TEMPLATES.ORDER.NAME'),
    description: t('CONVERSATION.APPLE_FORM.TEMPLATES.ORDER.DESCRIPTION'),
    icon: '🛒',
    fields: ['product', 'quantity', 'billing', 'terms'],
  },
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
  default_value: '',
  keyboard_type: 'default',
  text_content_type: '',
});

// Computed properties
const currentPage = computed(() => {
  if (!formData.value.pages || formData.value.pages.length === 0) {
    return null;
  }
  return formData.value.pages[currentPageIndex.value];
});

const canCreateForm = computed(() => {
  return (
    formData.value.title.trim().length > 0 &&
    formData.value.pages.length > 0 &&
    formData.value.pages.some(page => page.items && page.items.length > 0)
  );
});

const totalFields = computed(() => {
  return formData.value.pages.reduce((total, page) => {
    return total + (page.items ? page.items.length : 0);
  }, 0);
});

// Methods
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
    default_value: '',
    keyboard_type: 'default',
    text_content_type: '',
  };
};

const initializeForm = () => {
  formData.value = {
    title: '',
    description: '',
    pages: [],
  };
  currentPageIndex.value = 0;
  activeTab.value = 'builder';
  selectedTemplate.value = null;
};

const addNewPage = () => {
  const pageNumber = formData.value.pages.length + 1;
  const newPage = {
    page_id: `page_${pageNumber}`,
    title: `${t('CONVERSATION.APPLE_FORM.PAGE_LABEL')} ${pageNumber}`,
    description: '',
    items: [],
  };

  formData.value.pages.push(newPage);
  currentPageIndex.value = formData.value.pages.length - 1;
};

const removePage = index => {
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

const addFieldToCurrentPage = () => {
  if (!currentPage.value) return;

  if (!newField.value.item_id) {
    const fieldCount = currentPage.value.items.length;
    newField.value.item_id = `field_${currentPageIndex.value + 1}_${fieldCount + 1}`;
  }

  const fieldData = { ...newField.value };

  if (!['singleSelect', 'multiSelect'].includes(fieldData.item_type)) {
    delete fieldData.options;
  }

  if (fieldData.item_type !== 'stepper') {
    delete fieldData.min_value;
    delete fieldData.max_value;
  }

  if (!['text', 'textArea', 'email', 'phone'].includes(fieldData.item_type)) {
    delete fieldData.max_length;
    delete fieldData.keyboard_type;
    delete fieldData.text_content_type;
  }

  if (fieldData.item_type !== 'richLink') {
    delete fieldData.url;
  }

  if (!fieldData.keyboard_type || fieldData.keyboard_type === 'default') {
    delete fieldData.keyboard_type;
  }
  if (!fieldData.text_content_type) {
    delete fieldData.text_content_type;
  }

  if (fieldData.options) {
    fieldData.options = fieldData.options.filter(opt => opt.value && opt.title);
  }

  currentPage.value.items.push(fieldData);
  showAddFieldModal.value = false;
  resetNewField();
};

const removeField = fieldIndex => {
  if (currentPage.value && currentPage.value.items) {
    currentPage.value.items.splice(fieldIndex, 1);
  }
};

const addOption = () => {
  newField.value.options.push({ value: '', title: '' });
};

const removeOption = index => {
  if (newField.value.options.length > 1) {
    newField.value.options.splice(index, 1);
  }
};

const loadTemplate = templateId => {
  switch (templateId) {
    case 'contact':
      formData.value = {
        title: t('CONVERSATION.APPLE_FORM.TEMPLATES.CONTACT.FORM_TITLE'),
        description: t('CONVERSATION.APPLE_FORM.TEMPLATES.CONTACT.FORM_DESC'),
        pages: [
          {
            page_id: 'page_1',
            title: t('CONVERSATION.APPLE_FORM.TEMPLATES.CONTACT.PAGE_TITLE'),
            description: t(
              'CONVERSATION.APPLE_FORM.TEMPLATES.CONTACT.PAGE_DESC'
            ),
            items: [
              {
                item_id: 'full_name',
                item_type: 'text',
                title: t('CONVERSATION.APPLE_FORM.FIELD_LABELS.FULL_NAME'),
                required: true,
                placeholder: t(
                  'CONVERSATION.APPLE_FORM.PLACEHOLDERS.FULL_NAME'
                ),
                keyboard_type: 'default',
                text_content_type: 'name',
              },
              {
                item_id: 'email',
                item_type: 'email',
                title: t('CONVERSATION.APPLE_FORM.FIELD_LABELS.EMAIL'),
                required: true,
                placeholder: t('CONVERSATION.APPLE_FORM.PLACEHOLDERS.EMAIL'),
                keyboard_type: 'emailAddress',
                text_content_type: 'emailAddress',
              },
              {
                item_id: 'phone',
                item_type: 'phone',
                title: t('CONVERSATION.APPLE_FORM.FIELD_LABELS.PHONE'),
                required: false,
                placeholder: t('CONVERSATION.APPLE_FORM.PLACEHOLDERS.PHONE'),
                keyboard_type: 'phonePad',
                text_content_type: 'telephoneNumber',
              },
            ],
          },
        ],
      };
      break;
    default:
      // Keep empty or handle other templates
      break;
  }

  currentPageIndex.value = 0;
  activeTab.value = 'builder';
};

const createForm = () => {
  if (!canCreateForm.value) return;

  const formConfig = {
    title: formData.value.title,
    description: formData.value.description || '',
    pages: formData.value.pages,
  };

  emit('create', {
    content_type: 'apple_form',
    content_attributes: formConfig,
  });

  emit('close');
  initializeForm();
};

const closeModal = () => {
  emit('close');
  initializeForm();
};

watch(
  () => props.show,
  newShow => {
    if (newShow) {
      nextTick(() => {
        if (formData.value.pages.length === 0) {
          addNewPage();
        }
      });
    }
  }
);
</script>

<template>
  <div>
    <div
      v-if="show"
      class="fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-80 flex items-center justify-center p-4"
    >
      <div
        class="bg-white dark:bg-slate-800 rounded-lg max-w-4xl w-full max-h-full overflow-hidden flex flex-col shadow-2xl border-4 border-blue-500 dark:border-blue-400 ring-4 ring-blue-200 dark:ring-blue-800"
      >
        <div
          class="flex items-center justify-between p-6 border-b border-slate-200 dark:border-slate-600"
        >
          <div>
            <h2
              class="text-xl font-semibold text-slate-900 dark:text-slate-100"
            >
              {{ t('CONVERSATION.APPLE_FORM.MODAL_TITLE') }}
            </h2>
            <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">
              {{ t('CONVERSATION.APPLE_FORM.MODAL_SUBTITLE') }}
            </p>
          </div>
          <button
            class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
            @click="closeModal"
          >
            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
              <path
                d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z"
              />
            </svg>
          </button>
        </div>

        <div class="flex border-b border-slate-200 dark:border-slate-600">
          <button
            class="px-6 py-3 text-sm font-medium border-b-2 transition-colors"
            :class="[
              activeTab === 'templates'
                ? 'border-woot-500 text-woot-600 dark:text-woot-400'
                : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300',
            ]"
            @click="activeTab = 'templates'"
          >
            {{ t('CONVERSATION.APPLE_FORM.TABS.TEMPLATES') }}
          </button>
          <button
            class="px-6 py-3 text-sm font-medium border-b-2 transition-colors"
            :class="[
              activeTab === 'builder'
                ? 'border-woot-500 text-woot-600 dark:text-woot-400'
                : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300',
            ]"
            @click="activeTab = 'builder'"
          >
            {{ t('CONVERSATION.APPLE_FORM.TABS.BUILDER') }}
          </button>
          <button
            class="px-6 py-3 text-sm font-medium border-b-2 transition-colors"
            :class="[
              activeTab === 'preview'
                ? 'border-woot-500 text-woot-600 dark:text-woot-400'
                : 'border-transparent text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-300',
            ]"
            @click="activeTab = 'preview'"
          >
            {{ t('CONVERSATION.APPLE_FORM.TABS.PREVIEW') }}
          </button>
        </div>

        <div class="flex-1 overflow-y-auto">
          <div v-if="activeTab === 'templates'" class="p-6">
            <h3
              class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4"
            >
              {{ t('CONVERSATION.APPLE_FORM.CHOOSE_TEMPLATE') }}
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <button
                v-for="template in formTemplates"
                :key="template.id"
                class="text-left p-4 border-2 border-slate-200 dark:border-slate-600 rounded-lg hover:border-woot-500 dark:hover:border-woot-400 transition-colors"
                @click="loadTemplate(template.id)"
              >
                <div class="flex items-center space-x-3">
                  <div class="text-2xl">{{ template.icon }}</div>
                  <div>
                    <h4 class="font-medium text-slate-900 dark:text-slate-100">
                      {{ template.name }}
                    </h4>
                    <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">
                      {{ template.description }}
                    </p>
                  </div>
                </div>
              </button>
            </div>
          </div>

          <div v-else-if="activeTab === 'builder'" class="flex h-full">
            <div
              class="w-1/2 p-6 border-r border-slate-200 dark:border-slate-600"
            >
              <div class="mb-6">
                <h3
                  class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4"
                >
                  {{ t('CONVERSATION.APPLE_FORM.FORM_DETAILS') }}
                </h3>
                <div class="space-y-4">
                  <div>
                    <label
                      class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
                    >
                      {{ t('CONVERSATION.APPLE_FORM.FORM_TITLE_LABEL') }}
                    </label>
                    <input
                      v-model="formData.title"
                      type="text"
                      :placeholder="
                        t('CONVERSATION.APPLE_FORM.FORM_TITLE_PLACEHOLDER')
                      "
                      class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                  <div>
                    <label
                      class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
                    >
                      {{ t('CONVERSATION.APPLE_FORM.DESCRIPTION_LABEL') }}
                    </label>
                    <textarea
                      v-model="formData.description"
                      rows="2"
                      :placeholder="
                        t('CONVERSATION.APPLE_FORM.DESCRIPTION_PLACEHOLDER')
                      "
                      class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                </div>
              </div>

              <div class="mb-6">
                <div class="flex items-center justify-between mb-4">
                  <h3
                    class="text-lg font-medium text-slate-900 dark:text-slate-100"
                  >
                    {{ t('CONVERSATION.APPLE_FORM.PAGES') }}
                  </h3>
                  <button
                    class="px-3 py-1 bg-blue-500 text-white text-sm rounded-md hover:bg-blue-600 transition-colors"
                    @click="addNewPage"
                  >
                    {{ t('CONVERSATION.APPLE_FORM.ADD_PAGE') }}
                  </button>
                </div>

                <div class="space-y-2">
                  <div
                    v-for="(page, index) in formData.pages"
                    :key="page.page_id"
                    class="flex items-center justify-between p-3 rounded-lg border cursor-pointer transition-colors"
                    :class="[
                      index === currentPageIndex
                        ? 'border-woot-500 bg-woot-50 dark:bg-woot-900/20'
                        : 'border-slate-200 dark:border-slate-600 hover:border-slate-300',
                    ]"
                    @click="currentPageIndex = index"
                  >
                    <div class="flex-1">
                      <input
                        v-model="page.title"
                        class="font-medium text-slate-900 dark:text-slate-100 bg-transparent border-none p-0 focus:outline-none"
                        @click.stop
                      />
                      <p class="text-sm text-slate-600 dark:text-slate-400">
                        {{ page.items ? page.items.length : 0 }}
                        {{ t('CONVERSATION.APPLE_FORM.FIELDS_COUNT') }}
                      </p>
                    </div>
                    <button
                      v-if="formData.pages.length > 1"
                      class="text-red-500 hover:text-red-700 transition-colors ml-2"
                      @click.stop="removePage(index)"
                    >
                      <svg
                        class="w-4 h-4"
                        fill="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z"
                        />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>

              <div v-if="currentPage">
                <div class="flex items-center justify-between mb-4">
                  <h4
                    class="text-md font-medium text-slate-900 dark:text-slate-100"
                  >
                    {{
                      t('CONVERSATION.APPLE_FORM.FIELDS_TITLE', {
                        page: currentPage.title,
                      })
                    }}
                  </h4>
                  <button
                    class="px-3 py-1 bg-green-500 text-white text-sm rounded-md hover:bg-green-600 transition-colors"
                    @click="openAddFieldModal"
                  >
                    {{ t('CONVERSATION.APPLE_FORM.ADD_FIELD') }}
                  </button>
                </div>

                <div class="space-y-2">
                  <div
                    v-for="(field, index) in currentPage.items"
                    :key="field.item_id"
                    class="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-700 rounded-lg"
                  >
                    <div>
                      <div
                        class="font-medium text-slate-900 dark:text-slate-100"
                      >
                        {{ field.title }}
                      </div>
                      <div class="text-sm text-slate-600 dark:text-slate-400">
                        {{
                          fieldTypes.find(ft => ft.value === field.item_type)
                            ?.label || field.item_type
                        }}
                        <span v-if="field.required" class="text-red-500 ml-1">
                          *
                        </span>
                      </div>
                    </div>
                    <button
                      class="text-red-500 hover:text-red-700 transition-colors"
                      @click="removeField(index)"
                    >
                      <svg
                        class="w-4 h-4"
                        fill="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z"
                        />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div class="w-1/2 p-6">
              <div v-if="currentPage">
                <h3
                  class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4"
                >
                  {{ t('CONVERSATION.APPLE_FORM.PAGE_CONFIG') }}
                </h3>
                <div class="space-y-4">
                  <div>
                    <label
                      class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
                    >
                      {{ t('CONVERSATION.APPLE_FORM.PAGE_TITLE_LABEL') }}
                    </label>
                    <input
                      v-model="currentPage.title"
                      type="text"
                      class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                    />
                  </div>
                  <div>
                    <label
                      class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
                    >
                      {{ t('CONVERSATION.APPLE_FORM.PAGE_DESCRIPTION_LABEL') }}
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

          <div v-else-if="activeTab === 'preview'" class="p-6">
            <h3
              class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4"
            >
              {{ t('CONVERSATION.APPLE_FORM.FORM_PREVIEW') }}
            </h3>
            <div v-if="formData.pages.length === 0" class="text-center py-12">
              <p class="text-slate-600 dark:text-slate-400">
                {{ t('CONVERSATION.APPLE_FORM.NO_PAGES_YET') }}
              </p>
            </div>
            <div v-else class="space-y-6">
              <div
                v-for="page in formData.pages"
                :key="page.page_id"
                class="border border-slate-200 dark:border-slate-600 rounded-lg p-6"
              >
                <div class="mb-4">
                  <h4
                    class="text-lg font-semibold text-slate-900 dark:text-slate-100"
                  >
                    {{ page.title }}
                  </h4>
                  <p
                    v-if="page.description"
                    class="text-sm text-slate-600 dark:text-slate-400 mt-1"
                  >
                    {{ page.description }}
                  </p>
                </div>

                <div
                  v-if="page.items && page.items.length > 0"
                  class="space-y-4"
                >
                  <div
                    v-for="field in page.items"
                    :key="field.item_id"
                    class="space-y-2"
                  >
                    <label
                      class="block text-sm font-medium text-slate-700 dark:text-slate-300"
                    >
                      {{ field.title }}
                      <span v-if="field.required" class="text-red-500">*</span>
                    </label>

                    <input
                      v-if="
                        ['text', 'email', 'phone'].includes(field.item_type)
                      "
                      :type="
                        field.item_type === 'email'
                          ? 'email'
                          : field.item_type === 'phone'
                            ? 'tel'
                            : 'text'
                      "
                      :placeholder="field.placeholder"
                      disabled
                      class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-slate-50 dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                    />

                    <textarea
                      v-else-if="field.item_type === 'textArea'"
                      :placeholder="field.placeholder"
                      rows="3"
                      disabled
                      class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-slate-50 dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                    />

                    <select
                      v-else-if="
                        ['singleSelect', 'multiSelect'].includes(
                          field.item_type
                        )
                      "
                      disabled
                      class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-slate-50 dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                    >
                      <option value="">
                        {{ t('CONVERSATION.APPLE_FORM.SELECT_OPTION') }}
                      </option>
                      <option
                        v-for="option in field.options"
                        :key="option.value"
                        :value="option.value"
                      >
                        {{ option.title }}
                      </option>
                    </select>

                    <div
                      v-else-if="field.item_type === 'toggle'"
                      class="flex items-center"
                    >
                      <input
                        type="checkbox"
                        disabled
                        class="rounded border-slate-300 text-woot-600 focus:ring-woot-500"
                      />
                      <span
                        class="ml-2 text-sm text-slate-600 dark:text-slate-400"
                      >
                        {{
                          field.description ||
                          t('CONVERSATION.APPLE_FORM.TOGGLE_OPTION')
                        }}
                      </span>
                    </div>

                    <div
                      v-else-if="field.item_type === 'stepper'"
                      class="flex items-center space-x-2"
                    >
                      <button
                        type="button"
                        disabled
                        class="px-3 py-1 border border-slate-300 dark:border-slate-600 rounded-md bg-slate-50 dark:bg-slate-700"
                      >
                        -
                      </button>
                      <input
                        type="number"
                        :value="field.min_value || 1"
                        disabled
                        class="w-20 px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-slate-50 dark:bg-slate-700 text-center"
                      />
                      <button
                        type="button"
                        disabled
                        class="px-3 py-1 border border-slate-300 dark:border-slate-600 rounded-md bg-slate-50 dark:bg-slate-700"
                      >
                        +
                      </button>
                    </div>

                    <input
                      v-else-if="field.item_type === 'dateTime'"
                      type="datetime-local"
                      disabled
                      class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md bg-slate-50 dark:bg-slate-700 text-slate-900 dark:text-slate-100"
                    />

                    <div
                      v-else-if="field.item_type === 'richLink'"
                      class="p-3 border border-slate-300 dark:border-slate-600 rounded-md bg-slate-50 dark:bg-slate-700"
                    >
                      <a
                        :href="field.url"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="text-woot-600 hover:underline"
                      >
                        {{ field.url || t('CONVERSATION.APPLE_FORM.LINK_URL') }}
                      </a>
                    </div>
                  </div>
                </div>
                <div
                  v-else
                  class="text-center py-8 text-slate-500 dark:text-slate-400"
                >
                  {{ t('CONVERSATION.APPLE_FORM.NO_FIELDS_YET') }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <div
          class="flex items-center justify-between p-6 border-t border-slate-200 dark:border-slate-600"
        >
          <div class="text-sm text-slate-600 dark:text-slate-400">
            {{
              t('CONVERSATION.APPLE_FORM.SUMMARY', {
                pages: formData.pages.length,
                fields: totalFields,
              })
            }}
          </div>
          <div class="flex space-x-3">
            <button
              class="px-4 py-2 text-slate-600 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200 transition-colors"
              @click="closeModal"
            >
              {{ t('CONVERSATION.APPLE_FORM.CANCEL') }}
            </button>
            <button
              :disabled="!canCreateForm"
              class="px-4 py-2 bg-woot-500 text-white rounded-md hover:bg-woot-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              @click="createForm"
            >
              {{ t('CONVERSATION.APPLE_FORM.CREATE_FORM') }}
            </button>
          </div>
        </div>
      </div>

      <div
        v-if="showAddFieldModal"
        class="fixed inset-0 z-60 overflow-y-auto bg-black bg-opacity-90 flex items-center justify-center p-4"
      >
        <div
          class="bg-white dark:bg-slate-800 rounded-lg max-w-2xl w-full max-h-full overflow-y-auto shadow-2xl border-4 border-green-500 dark:border-green-400"
        >
          <div class="p-6">
            <h3
              class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4"
            >
              {{ t('CONVERSATION.APPLE_FORM.ADD_FIELD_TITLE') }}
            </h3>

            <div class="mb-4">
              <label
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
              >
                {{ t('CONVERSATION.APPLE_FORM.FIELD_TYPE') }}
              </label>
              <div class="grid grid-cols-2 gap-2">
                <button
                  v-for="fieldType in fieldTypes"
                  :key="fieldType.value"
                  class="text-left p-3 border-2 rounded-lg transition-colors"
                  :class="[
                    newField.item_type === fieldType.value
                      ? 'border-woot-500 bg-woot-50 dark:bg-woot-900/20'
                      : 'border-slate-200 dark:border-slate-600 hover:border-slate-300',
                  ]"
                  @click="newField.item_type = fieldType.value"
                >
                  <div class="flex items-center space-x-2">
                    <span class="text-lg">{{ fieldType.icon }}</span>
                    <div>
                      <div
                        class="font-medium text-slate-900 dark:text-slate-100 text-sm"
                      >
                        {{ fieldType.label }}
                      </div>
                      <div class="text-xs text-slate-600 dark:text-slate-400">
                        {{ fieldType.description }}
                      </div>
                    </div>
                  </div>
                </button>
              </div>
            </div>

            <div class="space-y-4">
              <div>
                <label
                  class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
                >
                  {{ t('CONVERSATION.APPLE_FORM.FIELD_TITLE') }}
                </label>
                <input
                  v-model="newField.title"
                  type="text"
                  :placeholder="
                    t('CONVERSATION.APPLE_FORM.FIELD_TITLE_PLACEHOLDER')
                  "
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                />
              </div>

              <div>
                <label
                  class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
                >
                  {{ t('CONVERSATION.APPLE_FORM.DESCRIPTION_LABEL') }}
                </label>
                <input
                  v-model="newField.description"
                  type="text"
                  :placeholder="
                    t('CONVERSATION.APPLE_FORM.FIELD_DESCRIPTION_PLACEHOLDER')
                  "
                  class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                />
              </div>

              <div class="flex items-center space-x-2">
                <input
                  v-model="newField.required"
                  type="checkbox"
                  class="rounded border-slate-300 text-woot-600 focus:ring-woot-500"
                />
                <label class="text-sm text-slate-700 dark:text-slate-300">
                  {{ t('CONVERSATION.APPLE_FORM.REQUIRED_FIELD') }}
                </label>
              </div>

              <div
                v-if="
                  ['text', 'textArea', 'email', 'phone'].includes(
                    newField.item_type
                  )
                "
                class="space-y-4"
              >
                <div>
                  <label
                    class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
                  >
                    {{ t('CONVERSATION.APPLE_FORM.PLACEHOLDER') }}
                  </label>
                  <input
                    v-model="newField.placeholder"
                    type="text"
                    :placeholder="t('CONVERSATION.APPLE_FORM.PLACEHOLDER_TEXT')"
                    class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                  />
                </div>
              </div>

              <div
                v-if="
                  ['singleSelect', 'multiSelect'].includes(newField.item_type)
                "
                class="space-y-4"
              >
                <div>
                  <label
                    class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
                  >
                    {{ t('CONVERSATION.APPLE_FORM.OPTIONS') }}
                  </label>
                  <div class="space-y-2">
                    <div
                      v-for="(option, index) in newField.options"
                      :key="index"
                      class="flex items-center space-x-2"
                    >
                      <input
                        v-model="option.value"
                        type="text"
                        :placeholder="t('CONVERSATION.APPLE_FORM.OPTION_VALUE')"
                        class="flex-1 px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                      />
                      <input
                        v-model="option.title"
                        type="text"
                        :placeholder="t('CONVERSATION.APPLE_FORM.OPTION_LABEL')"
                        class="flex-1 px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-700 dark:text-white"
                      />
                      <button
                        class="text-red-500 hover:text-red-700 transition-colors"
                        @click="removeOption(index)"
                      >
                        <svg
                          class="w-4 h-4"
                          fill="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            d="M19,6.41L17.59,5L12,10.59L6.41,5L5,6.41L10.59,12L5,17.59L6.41,19L12,13.41L17.59,19L19,17.59L13.41,12L19,6.41Z"
                          />
                        </svg>
                      </button>
                    </div>
                    <button
                      class="w-full py-2 border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-md text-slate-600 dark:text-slate-400 hover:border-slate-400 dark:hover:border-slate-500 transition-colors"
                      @click="addOption"
                    >
                      {{ t('CONVERSATION.APPLE_FORM.ADD_OPTION') }}
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div class="flex justify-end space-x-3 mt-6">
              <button
                class="px-4 py-2 text-slate-600 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200 transition-colors"
                @click="showAddFieldModal = false"
              >
                {{ t('CONVERSATION.APPLE_FORM.CANCEL') }}
              </button>
              <button
                :disabled="!newField.title"
                class="px-4 py-2 bg-woot-500 text-white rounded-md hover:bg-woot-600 transition-colors disabled:opacity-50"
                @click="addFieldToCurrentPage"
              >
                {{ t('CONVERSATION.APPLE_FORM.ADD_FIELD') }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
