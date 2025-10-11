<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import { createRichLinkPreview } from 'dashboard/helper/appleMessagesRichLink';

const props = defineProps({
  properties: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update:properties']);

const { t } = useI18n();

const localProps = ref({
  title: props.properties.title || '',
  description: props.properties.description || '',
  pages: props.properties.pages || [],
  receivedMessage: props.properties.receivedMessage || {
    title: '',
    subtitle: '',
    imageIdentifier: '',
    style: 'large',
  },
  replyMessage: props.properties.replyMessage || {
    title: '',
    subtitle: '',
    imageIdentifier: '',
    style: 'large',
  },
  images: props.properties.images || [],
});

watch(
  localProps,
  newValue => {
    emit('update:properties', newValue);
  },
  { deep: true }
);

// Automatically sync reply image with received image
watch(
  () => localProps.value.receivedMessage?.imageIdentifier,
  newIdentifier => {
    if (localProps.value.replyMessage) {
      localProps.value.replyMessage.imageIdentifier = newIdentifier || '';
    }
  },
  { immediate: true }
);

// Automatically sync received message title with form title
watch(
  () => localProps.value.title,
  newTitle => {
    if (localProps.value.receivedMessage) {
      localProps.value.receivedMessage.title = newTitle || '';
    }
  },
  { immediate: true }
);

// Automatically sync received message subtitle with form description
watch(
  () => localProps.value.description,
  newDescription => {
    if (
      localProps.value.receivedMessage &&
      (!localProps.value.receivedMessage.subtitle ||
        localProps.value.receivedMessage.subtitle ===
          localProps.value.description)
    ) {
      localProps.value.receivedMessage.subtitle = newDescription || '';
    }
  },
  { immediate: true }
);

const fieldTypes = computed(() => [
  {
    value: 'text',
    label: t('APPLE_FORM.FIELD_TYPES.TEXT'),
    icon: '📝',
    description: t('APPLE_FORM.FIELD_DESCRIPTIONS.TEXT'),
  },
  {
    value: 'textArea',
    label: t('APPLE_FORM.FIELD_TYPES.TEXT_AREA'),
    icon: '📄',
    description: t('APPLE_FORM.FIELD_DESCRIPTIONS.TEXT_AREA'),
  },
  {
    value: 'email',
    label: t('APPLE_FORM.FIELD_TYPES.EMAIL'),
    icon: '📧',
    description: t('APPLE_FORM.FIELD_DESCRIPTIONS.EMAIL'),
  },
  {
    value: 'phone',
    label: t('APPLE_FORM.FIELD_TYPES.PHONE'),
    icon: '📱',
    description: t('APPLE_FORM.FIELD_DESCRIPTIONS.PHONE'),
  },
  {
    value: 'singleSelect',
    label: t('APPLE_FORM.FIELD_TYPES.SINGLE_CHOICE'),
    icon: '🔘',
    description: t('APPLE_FORM.FIELD_DESCRIPTIONS.SINGLE_CHOICE'),
  },
  {
    value: 'multiSelect',
    label: t('APPLE_FORM.FIELD_TYPES.MULTIPLE_CHOICE'),
    icon: '☑️',
    description: t('APPLE_FORM.FIELD_DESCRIPTIONS.MULTIPLE_CHOICE'),
  },
  {
    value: 'dateTime',
    label: t('APPLE_FORM.FIELD_TYPES.DATE_TIME'),
    icon: '📅',
    description: t('APPLE_FORM.FIELD_DESCRIPTIONS.DATE_TIME'),
  },
  {
    value: 'toggle',
    label: t('APPLE_FORM.FIELD_TYPES.TOGGLE'),
    icon: '🔄',
    description: t('APPLE_FORM.FIELD_DESCRIPTIONS.TOGGLE'),
  },
  {
    value: 'stepper',
    label: t('APPLE_FORM.FIELD_TYPES.STEPPER'),
    icon: '🔢',
    description: t('APPLE_FORM.FIELD_DESCRIPTIONS.STEPPER'),
  },
  {
    value: 'richLink',
    label: t('APPLE_FORM.FIELD_TYPES.RICH_LINK'),
    icon: '🔗',
    description: t('APPLE_FORM.FIELD_DESCRIPTIONS.RICH_LINK'),
  },
]);

const styleOptions = [
  { value: 'icon', label: 'Icon (280x65)' },
  { value: 'small', label: 'Small (280x85)' },
  { value: 'large', label: 'Large (280x210)' },
];

const currentPageIndex = ref(0);
const showAddFieldModal = ref(false);

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
  regex: '',
  input_type: 'singleline',
  label_text: '',
  prefix_text: '',
  maximum_character_count: null,
  hint_text: '',
  date_format: 'MM/dd/yyyy',
  start_date: '',
  maximum_date: '',
  minimum_date: '',
  picker_title: '',
  selected_item_index: 0,
  multiple_selection: false,
});

const currentPage = computed(() => {
  if (!localProps.value.pages || localProps.value.pages.length === 0) {
    return null;
  }
  return localProps.value.pages[currentPageIndex.value];
});

const fileInputRef = ref(null);

const getImagePreviewUrl = identifier => {
  const image = localProps.value.images.find(
    img => img.identifier === identifier
  );
  if (!image) return null;
  return (
    image.preview || image.imageUrl || `data:image/jpeg;base64,${image.data}`
  );
};

const handleImageUpload = () => {
  if (fileInputRef.value) {
    fileInputRef.value.click();
  }
};

const handleFileSelected = async event => {
  const file = event.target.files[0];
  if (!file) return;

  if (!file.type.startsWith('image/')) {
    useAlert(t('APPLE_FORM.IMAGE_UPLOAD.INVALID_FILE_TYPE'));
    return;
  }

  const reader = new FileReader();
  reader.onload = e => {
    const imageData = {
      identifier: `${Date.now()}_${file.name.replace(/[^a-zA-Z0-9]/g, '_')}`,
      data: e.target.result.split(',')[1],
      preview: e.target.result,
      description: file.name,
      originalName: file.name,
      size: file.size,
    };

    localProps.value.images.push(imageData);
    localProps.value.receivedMessage.imageIdentifier = imageData.identifier;
  };
  reader.readAsDataURL(file);

  event.target.value = '';
};

const addNewPage = () => {
  const pageNumber = localProps.value.pages.length + 1;
  const newPage = {
    page_id: `page_${pageNumber}`,
    title: `${t('APPLE_FORM.PAGE_LABEL')} ${pageNumber}`,
    description: '',
    items: [],
  };

  localProps.value.pages.push(newPage);
  currentPageIndex.value = localProps.value.pages.length - 1;
};

const removePage = index => {
  if (localProps.value.pages.length > 1) {
    localProps.value.pages.splice(index, 1);
    if (currentPageIndex.value >= localProps.value.pages.length) {
      currentPageIndex.value = localProps.value.pages.length - 1;
    }
  }
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
    default_value: '',
    keyboard_type: 'default',
    text_content_type: '',
    regex: '',
    input_type: 'singleline',
    label_text: '',
    prefix_text: '',
    maximum_character_count: null,
    hint_text: '',
    date_format: 'MM/dd/yyyy',
    start_date: '',
    maximum_date: '',
    minimum_date: '',
    picker_title: '',
    selected_item_index: 0,
    multiple_selection: false,
  };
};

const openAddFieldModal = () => {
  resetNewField();
  showAddFieldModal.value = true;
};

const addFieldToCurrentPage = () => {
  if (!currentPage.value) return;

  const isEditing = typeof newField.value.editingIndex === 'number';

  if (!newField.value.item_id && !isEditing) {
    const fieldCount = currentPage.value.items.length;
    newField.value.item_id = `field_${currentPageIndex.value + 1}_${fieldCount + 1}`;
  }

  const fieldData = { ...newField.value };
  delete fieldData.editingIndex;

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

  if (isEditing) {
    currentPage.value.items[newField.value.editingIndex] = fieldData;
  } else {
    currentPage.value.items.push(fieldData);
  }

  showAddFieldModal.value = false;
  resetNewField();
};

const removeField = fieldIndex => {
  if (currentPage.value && currentPage.value.items) {
    currentPage.value.items.splice(fieldIndex, 1);
  }
};

const editField = fieldIndex => {
  if (currentPage.value && currentPage.value.items) {
    const field = currentPage.value.items[fieldIndex];
    newField.value = { ...field };

    if (!newField.value.options || newField.value.options.length === 0) {
      newField.value.options = [{ value: '', title: '' }];
    }

    newField.value.editingIndex = fieldIndex;
    showAddFieldModal.value = true;
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

const isLoadingRichLink = ref(false);

const fetchRichLinkData = async () => {
  if (!newField.value.url) {
    useAlert('Please enter a URL first');
    return;
  }

  isLoadingRichLink.value = true;
  try {
    const result = await createRichLinkPreview(newField.value.url);

    if (result.success && result.richLinkData) {
      // Auto-fill title if empty
      if (!newField.value.title && result.richLinkData.title) {
        newField.value.title = result.richLinkData.title;
      }

      // Auto-fill description if empty
      if (!newField.value.description && result.richLinkData.description) {
        newField.value.description = result.richLinkData.description;
      }

      useAlert(t('CONVERSATION.APPLE_FORM.RICH_LINK_AUTOFILL.SUCCESS'));
    } else {
      useAlert(
        t('CONVERSATION.APPLE_FORM.RICH_LINK_AUTOFILL.WARNING'),
        'warning'
      );
    }
  } catch (error) {
    useAlert(t('CONVERSATION.APPLE_FORM.RICH_LINK_AUTOFILL.ERROR'), 'error');
  } finally {
    isLoadingRichLink.value = false;
  }
};

// Initialize with one page if empty
if (localProps.value.pages.length === 0) {
  addNewPage();
}
</script>

<template>
  <div class="space-y-6">
    <!-- Hidden file input for image upload -->
    <input
      ref="fileInputRef"
      type="file"
      accept="image/*"
      class="hidden"
      @change="handleFileSelected"
    />

    <!-- Form Details -->
    <div class="space-y-4">
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('APPLE_FORM.FORM_DETAILS') }}
      </h3>

      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('APPLE_FORM.FORM_TITLE_LABEL') }}
        </label>
        <input
          v-model="localProps.title"
          type="text"
          :placeholder="t('APPLE_FORM.FORM_TITLE_PLACEHOLDER')"
          class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('APPLE_FORM.DESCRIPTION_LABEL') }}
        </label>
        <textarea
          v-model="localProps.description"
          rows="2"
          :placeholder="t('APPLE_FORM.DESCRIPTION_PLACEHOLDER')"
          class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        />
      </div>
    </div>

    <!-- Message Configuration -->
    <div class="space-y-4">
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('APPLE_FORM.MESSAGES_TAB.MESSAGE_CONFIGURATION') }}
      </h3>

      <!-- Received Message Subtitle -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('APPLE_FORM.MESSAGES_TAB.RECEIVED_MESSAGE_SUBTITLE_LABEL') }}
        </label>
        <input
          v-model="localProps.receivedMessage.subtitle"
          type="text"
          :placeholder="
            t('APPLE_FORM.MESSAGES_TAB.RECEIVED_MESSAGE_SUBTITLE_PLACEHOLDER')
          "
          class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        />
      </div>

      <!-- Image Selection -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('APPLE_FORM.MESSAGES_TAB.IMAGE_LABEL') }}
        </label>
        <div class="flex items-center gap-2">
          <select
            v-model="localProps.receivedMessage.imageIdentifier"
            class="flex-1 px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          >
            <option value="">
              {{ t('APPLE_FORM.MESSAGES_TAB.NO_IMAGE') }}
            </option>
            <option
              v-for="image in localProps.images"
              :key="image.identifier"
              :value="image.identifier"
            >
              {{ image.description || image.identifier }}
            </option>
          </select>
          <Button icon="i-lucide-upload" xs @click="handleImageUpload">
            {{ t('APPLE_FORM.MESSAGES_TAB.UPLOAD_BUTTON') }}
          </Button>
        </div>
        <div v-if="localProps.receivedMessage.imageIdentifier" class="mt-2">
          <img
            :src="
              getImagePreviewUrl(localProps.receivedMessage.imageIdentifier)
            "
            class="h-16 rounded border border-n-slate-7"
            alt="Preview"
          />
        </div>
      </div>

      <!-- Style Selection -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('APPLE_FORM.MESSAGES_TAB.IMAGE_STYLE') }}
        </label>
        <select
          v-model="localProps.receivedMessage.style"
          class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
        >
          <option
            v-for="style in styleOptions"
            :key="style.value"
            :value="style.value"
          >
            {{ style.label }}
          </option>
        </select>
      </div>

      <!-- Reply Message -->
      <div class="space-y-4 pt-4 border-t border-n-slate-6">
        <h4 class="text-sm font-semibold text-n-slate-12">
          {{ t('APPLE_FORM.MESSAGES_TAB.REPLY_MESSAGE') }}
        </h4>

        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ t('APPLE_FORM.REPLY_MESSAGE_TITLE_LABEL') }}
          </label>
          <input
            v-model="localProps.replyMessage.title"
            type="text"
            :placeholder="t('APPLE_FORM.REPLY_MESSAGE_TITLE_PLACEHOLDER')"
            class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ t('APPLE_FORM.REPLY_MESSAGE_SUBTITLE_LABEL') }}
          </label>
          <input
            v-model="localProps.replyMessage.subtitle"
            type="text"
            :placeholder="t('APPLE_FORM.REPLY_MESSAGE_SUBTITLE_PLACEHOLDER')"
            class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
      </div>
    </div>

    <!-- Pages Management -->
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <h3 class="text-base font-semibold text-n-slate-12">
          {{ t('APPLE_FORM.PAGES') }}
        </h3>
        <Button icon="i-lucide-plus" xs @click="addNewPage">
          {{ t('APPLE_FORM.ADD_PAGE') }}
        </Button>
      </div>

      <div class="space-y-2">
        <div
          v-for="(page, index) in localProps.pages"
          :key="page.page_id"
          class="flex items-center justify-between p-3 rounded-lg border cursor-pointer transition-colors"
          :class="[
            index === currentPageIndex
              ? 'border-n-blue-7 bg-n-blue-2'
              : 'border-n-slate-7 hover:border-n-slate-8',
          ]"
          @click="currentPageIndex = index"
        >
          <div class="flex-1 min-w-0">
            <input
              v-model="page.title"
              class="w-full text-sm font-medium text-n-slate-12 bg-transparent border-none p-0 focus:outline-none truncate"
              @click.stop
            />
            <p class="text-xs text-n-slate-11">
              {{ page.items ? page.items.length : 0 }}
              {{ t('APPLE_FORM.FIELDS_COUNT') }}
            </p>
          </div>
          <Button
            v-if="localProps.pages.length > 1"
            icon="i-lucide-x"
            ruby
            xs
            faded
            @click.stop="removePage(index)"
          />
        </div>
      </div>
    </div>

    <!-- Current Page Fields -->
    <div v-if="currentPage" class="space-y-4">
      <div class="flex items-center justify-between">
        <h4 class="text-sm font-semibold text-n-slate-12 truncate">
          {{ t('APPLE_FORM.FIELDS_TITLE', { page: currentPage.title }) }}
        </h4>
        <Button icon="i-lucide-plus" xs @click="openAddFieldModal">
          {{ t('APPLE_FORM.ADD_FIELD') }}
        </Button>
      </div>

      <div class="space-y-2">
        <div
          v-for="(field, index) in currentPage.items"
          :key="field.item_id"
          class="flex items-center justify-between p-3 bg-n-slate-2 rounded-lg cursor-pointer hover:bg-n-slate-3 transition-colors"
          @click="editField(index)"
        >
          <div class="flex-1 min-w-0">
            <div class="text-sm font-medium text-n-slate-12 truncate">
              {{ field.title }}
            </div>
            <div class="text-xs text-n-slate-11 truncate">
              {{
                fieldTypes.find(ft => ft.value === field.item_type)?.label ||
                field.item_type
              }}
              <span v-if="field.required" class="text-n-ruby-9 ml-1">*</span>
            </div>
          </div>
          <Button
            icon="i-lucide-trash-2"
            ruby
            xs
            faded
            @click.stop="removeField(index)"
          />
        </div>
      </div>
    </div>

    <!-- Add/Edit Field Modal -->
    <div
      v-if="showAddFieldModal"
      class="fixed inset-0 z-50 overflow-y-auto bg-black bg-opacity-50 flex items-center justify-center p-4"
    >
      <div
        class="bg-white dark:bg-n-slate-2 rounded-lg max-w-2xl w-full max-h-full overflow-y-auto shadow-xl"
      >
        <div class="p-6 space-y-4">
          <h3 class="text-lg font-medium text-n-slate-12">
            {{
              typeof newField.editingIndex === 'number'
                ? t('CONVERSATION.APPLE_FORM.EDIT_FIELD_TITLE')
                : t('APPLE_FORM.ADD_FIELD_TITLE')
            }}
          </h3>

          <!-- Field Type Selection -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('APPLE_FORM.FIELD_TYPE') }}
            </label>
            <div class="grid grid-cols-2 gap-2">
              <button
                v-for="fieldType in fieldTypes"
                :key="fieldType.value"
                class="text-left p-3 border-2 rounded-lg transition-colors"
                :class="[
                  newField.item_type === fieldType.value
                    ? 'border-n-blue-7 bg-n-blue-2'
                    : 'border-n-slate-7 hover:border-n-slate-8',
                ]"
                @click="newField.item_type = fieldType.value"
              >
                <div class="flex items-center gap-2">
                  <span class="text-lg">{{ fieldType.icon }}</span>
                  <div>
                    <div class="font-medium text-n-slate-12 text-sm">
                      {{ fieldType.label }}
                    </div>
                    <div class="text-xs text-n-slate-11">
                      {{ fieldType.description }}
                    </div>
                  </div>
                </div>
              </button>
            </div>
          </div>

          <!-- Basic Field Info -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('APPLE_FORM.FIELD_TITLE') }}
            </label>
            <input
              v-model="newField.title"
              type="text"
              :placeholder="t('APPLE_FORM.FIELD_TITLE_PLACEHOLDER')"
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('APPLE_FORM.DESCRIPTION_LABEL') }}
            </label>
            <input
              v-model="newField.description"
              type="text"
              :placeholder="t('APPLE_FORM.FIELD_DESCRIPTION_PLACEHOLDER')"
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>

          <div class="flex items-center gap-2">
            <input
              v-model="newField.required"
              type="checkbox"
              class="w-4 h-4 rounded border-n-slate-7 text-n-blue-9 focus:ring-2 focus:ring-n-blue-7"
            />
            <label class="text-sm text-n-slate-12">
              {{ t('APPLE_FORM.REQUIRED_FIELD') }}
            </label>
          </div>

          <!-- Input Field Options (text, textArea, email, phone) -->
          <div
            v-if="
              ['text', 'textArea', 'email', 'phone'].includes(
                newField.item_type
              )
            "
            class="space-y-4 pt-4 border-t border-n-slate-6"
          >
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2">
                {{ t('APPLE_FORM.PLACEHOLDER') }}
              </label>
              <input
                v-model="newField.placeholder"
                type="text"
                :placeholder="t('APPLE_FORM.PLACEHOLDER_TEXT')"
                class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2">
                {{ t('APPLE_FORM.FIELD_OPTIONS.LABEL_TEXT') }}
              </label>
              <input
                v-model="newField.label_text"
                type="text"
                :placeholder="
                  t('APPLE_FORM.FIELD_OPTIONS.LABEL_TEXT_PLACEHOLDER')
                "
                class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2">
                {{ t('CONVERSATION.APPLE_FORM.FIELD_OPTIONS.MAX_CHAR_COUNT') }}
              </label>
              <input
                v-model.number="newField.maximum_character_count"
                type="number"
                :placeholder="
                  t(
                    'CONVERSATION.APPLE_FORM.FIELD_OPTIONS.MAX_CHAR_COUNT_PLACEHOLDER'
                  )
                "
                class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
              />
            </div>
          </div>

          <!-- Select Options (singleSelect, multiSelect) -->
          <div
            v-if="['singleSelect', 'multiSelect'].includes(newField.item_type)"
            class="space-y-4 pt-4 border-t border-n-slate-6"
          >
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2">
                {{ t('APPLE_FORM.OPTIONS') }}
              </label>
              <div class="space-y-2">
                <div
                  v-for="(option, index) in newField.options"
                  :key="index"
                  class="space-y-2"
                >
                  <div class="flex items-center gap-2">
                    <input
                      v-model="option.value"
                      type="text"
                      :placeholder="t('APPLE_FORM.OPTION_VALUE')"
                      class="flex-1 px-3 py-2 text-sm border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                    />
                    <input
                      v-model="option.title"
                      type="text"
                      :placeholder="t('APPLE_FORM.OPTION_LABEL')"
                      class="flex-1 px-3 py-2 text-sm border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                    />
                    <Button
                      icon="i-lucide-x"
                      ruby
                      xs
                      faded
                      @click="removeOption(index)"
                    />
                  </div>

                  <!-- Image selector for option -->
                  <div class="ml-4 flex items-center gap-2">
                    <label class="text-xs text-n-slate-11">
                      {{
                        t('CONVERSATION.APPLE_FORM.FIELD_OPTIONS.OPTION_IMAGE')
                      }}
                    </label>
                    <select
                      v-model="option.imageIdentifier"
                      class="flex-1 px-2 py-1 text-sm border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                    >
                      <option value="">
                        {{ t('CONVERSATION.APPLE_FORM.MESSAGES_TAB.NO_IMAGE') }}
                      </option>
                      <option
                        v-for="img in localProps.images"
                        :key="img.identifier"
                        :value="img.identifier"
                      >
                        {{ img.identifier }}
                      </option>
                    </select>
                    <div
                      v-if="
                        option.imageIdentifier &&
                        getImagePreviewUrl(option.imageIdentifier)
                      "
                      class="w-8 h-8 rounded overflow-hidden border border-n-slate-7"
                    >
                      <img
                        :src="getImagePreviewUrl(option.imageIdentifier)"
                        alt="Option image"
                        class="w-full h-full object-cover"
                      />
                    </div>
                  </div>
                </div>
                <button
                  class="w-full py-2 border-2 border-dashed border-n-slate-7 rounded-lg text-n-slate-11 hover:border-n-slate-8 transition-colors"
                  @click="addOption"
                >
                  {{ t('APPLE_FORM.ADD_OPTION') }}
                </button>
              </div>
            </div>
          </div>

          <!-- Stepper Options -->
          <div
            v-if="newField.item_type === 'stepper'"
            class="space-y-4 pt-4 border-t border-n-slate-6"
          >
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-n-slate-12 mb-2">
                  {{ t('CONVERSATION.APPLE_FORM.STEPPER.MIN_VALUE') }}
                </label>
                <input
                  v-model.number="newField.min_value"
                  type="number"
                  class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-n-slate-12 mb-2">
                  {{ t('CONVERSATION.APPLE_FORM.STEPPER.MAX_VALUE') }}
                </label>
                <input
                  v-model.number="newField.max_value"
                  type="number"
                  class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                />
              </div>
            </div>
          </div>

          <!-- Rich Link Options -->
          <div
            v-if="newField.item_type === 'richLink'"
            class="space-y-4 pt-4 border-t border-n-slate-6"
          >
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2">
                {{ t('CONVERSATION.APPLE_FORM.RICH_LINK.URL_LABEL') }}
              </label>
              <div class="flex gap-2">
                <input
                  v-model="newField.url"
                  type="url"
                  :placeholder="
                    t('CONVERSATION.APPLE_FORM.RICH_LINK.URL_PLACEHOLDER')
                  "
                  class="flex-1 px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                />
                <Button
                  slate
                  icon="i-lucide-sparkles"
                  :disabled="!newField.url || isLoadingRichLink"
                  @click="fetchRichLinkData"
                >
                  {{
                    isLoadingRichLink
                      ? t('CONVERSATION.APPLE_FORM.RICH_LINK.LOADING')
                      : t('CONVERSATION.APPLE_FORM.RICH_LINK.AUTOFILL_BUTTON')
                  }}
                </Button>
              </div>
              <p class="text-xs text-n-slate-10 mt-1">
                {{
                  t('CONVERSATION.APPLE_FORM.RICH_LINK.AUTOFILL_DESCRIPTION')
                }}
              </p>
            </div>
          </div>

          <div class="flex justify-end gap-3 pt-4">
            <Button slate @click="showAddFieldModal = false">
              {{ t('APPLE_FORM.CANCEL') }}
            </Button>
            <Button :disabled="!newField.title" @click="addFieldToCurrentPage">
              {{ t('APPLE_FORM.ADD_FIELD') }}
            </Button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
