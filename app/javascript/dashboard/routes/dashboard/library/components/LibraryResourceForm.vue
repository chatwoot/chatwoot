<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useLibraryResources } from '../composables/useLibraryResources';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Textarea from 'dashboard/components-next/textarea/Textarea.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
import FileUpload from 'vue-upload-component';

const props = defineProps({
  resource: { type: Object, default: () => ({}) },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['save', 'cancel']);

const { t } = useI18n();
const { uploadFile } = useLibraryResources();

const form = ref({
  title: '',
  description: '',
  content: '',
  resource_type: 'text',
  custom_attributes: {},
});

// Resource type options
const resourceTypeOptions = computed(() => [
  { value: 'text', label: t('LIBRARY.FORM.RESOURCE_TYPE_TEXT') },
  { value: 'image', label: t('LIBRARY.FORM.RESOURCE_TYPE_IMAGE') },
  { value: 'video', label: t('LIBRARY.FORM.RESOURCE_TYPE_VIDEO') },
  { value: 'audio', label: t('LIBRARY.FORM.RESOURCE_TYPE_AUDIO') },
  { value: 'pdf', label: t('LIBRARY.FORM.RESOURCE_TYPE_PDF') },
  { value: 'web_page', label: t('LIBRARY.FORM.RESOURCE_TYPE_WEB_PAGE') },
]);

// Get selected resource type label
const selectedResourceTypeLabel = computed(() => {
  const selected = resourceTypeOptions.value.find(
    option => option.value === form.value.resource_type
  );
  return selected ? selected.label : t('LIBRARY.FORM.RESOURCE_TYPE_TEXT');
});

// File upload management
const uploadedFile = ref(null);
const fileUploadRef = ref(null);
const isUploading = ref(false);

// Watch for changes in resource prop and update form
watch(
  () => props.resource,
  newResource => {
    if (newResource) {
      form.value = {
        title: newResource.title || '',
        description: newResource.description || '',
        content: newResource.content || '',
        resource_type: newResource.resource_type || 'text',
        custom_attributes: newResource.custom_attributes || {},
      };

      // Set uploaded file info if exists (file attached via ActiveStorage)
      if (
        newResource.file_url &&
        newResource.file_url.includes('/rails/active_storage/')
      ) {
        uploadedFile.value = {
          name: t('LIBRARY.FORM.FILE_ATTACHED'),
          url: newResource.file_url,
          blob_id: null, // We don't have the blob_id in edit mode
        };
      } else {
        uploadedFile.value = null;
      }
    }
  },
  { immediate: true }
);

const isValid = computed(() => {
  const hasRequiredFields =
    form.value.title.trim() && form.value.description.trim();

  // For text and web_page types, content is required
  if (
    form.value.resource_type === 'text' ||
    form.value.resource_type === 'web_page'
  ) {
    return hasRequiredFields && form.value.content.trim();
  }

  // For file types (image, video, audio, pdf), file attachment is required
  const fileRequiredTypes = ['image', 'video', 'audio', 'pdf'];
  if (fileRequiredTypes.includes(form.value.resource_type)) {
    const hasFile = uploadedFile.value !== null || form.value.file_blob_id;
    return hasRequiredFields && hasFile;
  }

  // For other types, only basic fields required
  return hasRequiredFields;
});

// Computed property to check if content field should be shown
const shouldShowContentField = computed(() => {
  return (
    form.value.resource_type === 'text' ||
    form.value.resource_type === 'web_page'
  );
});

// Custom attributes management
const customAttributes = ref([]);

// Initialize custom attributes from form data only once
watch(
  () => props.resource,
  newResource => {
    if (newResource && newResource.custom_attributes) {
      customAttributes.value = Object.entries(
        newResource.custom_attributes
      ).map(([key, value]) => ({
        key,
        label: key.charAt(0).toUpperCase() + key.slice(1),
        value,
      }));
    }
  },
  { immediate: true }
);

const addCustomAttribute = () => {
  customAttributes.value.push({ key: '', label: '', value: '' });
};

const updateCustomAttributesForm = () => {
  const attrs = {};
  customAttributes.value.forEach(attr => {
    if (attr.key && attr.value) {
      attrs[attr.key] = attr.value;
    }
  });
  form.value.custom_attributes = attrs;
};

const removeCustomAttribute = index => {
  customAttributes.value.splice(index, 1);
  updateCustomAttributesForm();
};

const handleSave = () => {
  if (isValid.value) {
    // Ensure custom attributes are up to date before saving
    updateCustomAttributesForm();
    emit('save', { ...form.value });
  }
};

const handleCancel = () => {
  emit('cancel');
};

// File upload methods
const acceptedFileTypes = computed(() => {
  const typeMap = {
    image: 'image/*',
    video: 'video/*',
    audio: 'audio/*',
    pdf: 'application/pdf',
  };
  return typeMap[form.value.resource_type] || '*';
});

const validateFileType = file => {
  const allowedTypes = {
    image: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    video: ['video/mp4', 'video/mpeg', 'video/quicktime', 'video/webm'],
    audio: ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp3'],
    pdf: ['application/pdf'],
  };

  const resourceTypeAllowed = allowedTypes[form.value.resource_type];
  if (resourceTypeAllowed && !resourceTypeAllowed.includes(file.file.type)) {
    alert(
      `File type ${file.file.type} is not allowed for ${form.value.resource_type} resources`
    );
    return false;
  }

  // Check file size (40MB max)
  const maxSize = 40 * 1024 * 1024;
  if (file.file.size > maxSize) {
    alert('File size must be less than 40MB');
    return false;
  }

  return true;
};

const onFileUpload = async file => {
  if (!file || !validateFileType(file)) return;

  isUploading.value = true;

  try {
    const data = await uploadFile(file.file);

    uploadedFile.value = {
      name: file.file.name,
      url: data.file_url,
      blob_id: data.blob_id,
    };

    form.value.file_blob_id = data.blob_id;
  } catch (error) {
    const errorMessage = error.message || 'Upload failed';
    alert(errorMessage);
  } finally {
    isUploading.value = false;
  }
};

const removeFile = () => {
  uploadedFile.value = null;
  form.value.file_blob_id = null;
};
</script>

<template>
  <div class="flex flex-col gap-6 p-6">
    <div class="flex items-center justify-between">
      <h2 class="text-xl font-semibold text-n-base">
        {{
          resource?.id
            ? t('LIBRARY.FORM.EDIT_TITLE')
            : t('LIBRARY.FORM.ADD_TITLE')
        }}
      </h2>
    </div>

    <form class="flex flex-col gap-4" @submit.prevent="handleSave">
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('LIBRARY.FORM.RESOURCE_TYPE_LABEL') }}
        </label>
        <SelectMenu
          v-if="!resource?.id"
          v-model="form.resource_type"
          :label="selectedResourceTypeLabel"
          :options="resourceTypeOptions"
        />
        <div
          v-else
          class="px-3 py-2 bg-n-slate-3 border border-n-weak rounded-md text-sm text-n-slate-11"
        >
          {{ selectedResourceTypeLabel }}
        </div>
      </div>

      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('LIBRARY.FORM.TITLE_LABEL') }}
        </label>
        <Input
          v-model="form.title"
          :placeholder="t('LIBRARY.FORM.TITLE_PLACEHOLDER')"
          required
        />
      </div>

      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('LIBRARY.FORM.DESCRIPTION_LABEL') }}
        </label>
        <Textarea
          v-model="form.description"
          :placeholder="t('LIBRARY.FORM.DESCRIPTION_PLACEHOLDER')"
          rows="3"
          required
        />
      </div>

      <div v-if="shouldShowContentField">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{
            form.resource_type === 'web_page'
              ? t('LIBRARY.FORM.URL_LABEL')
              : t('LIBRARY.FORM.CONTENT_LABEL')
          }}
        </label>
        <Textarea
          v-model="form.content"
          :placeholder="
            form.resource_type === 'web_page'
              ? t('LIBRARY.FORM.URL_PLACEHOLDER')
              : t('LIBRARY.FORM.CONTENT_PLACEHOLDER')
          "
          :rows="form.resource_type === 'web_page' ? 3 : 10"
          required
        />
      </div>

      <div v-else>
        <!-- File Upload Area -->
        <div v-if="!uploadedFile && !isUploading" class="space-y-3">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ t('LIBRARY.FORM.FILE_LABEL') }}
          </label>
          <div
            class="border-2 border-dashed border-n-weak rounded-lg px-6 py-8 text-center"
          >
            <FileUpload
              ref="fileUploadRef"
              v-slot="{ uploadFiles }"
              :accept="acceptedFileTypes"
              :multiple="false"
              :maximum="1"
              @input-file="onFileUpload"
            >
              <div class="py-4">
                <p class="text-sm text-n-slate-11 mb-4">
                  {{ t('LIBRARY.FORM.FILE_UPLOAD_PLACEHOLDER') }}
                </p>
                <Button
                  variant="outline"
                  size="sm"
                  type="button"
                  @click="uploadFiles"
                >
                  {{ t('LIBRARY.FORM.SELECT_FILE') }}
                </Button>
              </div>
            </FileUpload>
          </div>
        </div>

        <!-- Loading State -->
        <div v-else-if="isUploading" class="space-y-3">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ t('LIBRARY.FORM.FILE_LABEL') }}
          </label>
          <div
            class="border-2 border-dashed border-n-weak rounded-lg px-6 py-8 text-center"
          >
            <div class="py-4">
              <div class="flex items-center justify-center mb-4">
                <div
                  class="animate-spin rounded-full h-8 w-8 border-b-2 border-n-brand"
                />
              </div>
              <p class="text-sm text-n-slate-11">
                {{ t('LIBRARY.FORM.UPLOADING_FILE') }}
              </p>
            </div>
          </div>
        </div>

        <!-- Uploaded File Preview -->
        <div v-else class="space-y-3">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ t('LIBRARY.FORM.FILE_LABEL') }}
          </label>
          <div
            class="flex items-center gap-3 p-3 border border-n-weak rounded-lg bg-n-slate-2"
          >
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-n-slate-12 truncate">
                {{ uploadedFile.name }}
              </p>
              <p class="text-xs text-n-slate-10">
                {{
                  uploadedFile.blob_id
                    ? t('LIBRARY.FORM.FILE_UPLOADED')
                    : t('LIBRARY.FORM.FILE_ATTACHED')
                }}
              </p>
            </div>
            <Button
              variant="outline"
              size="sm"
              type="button"
              icon="i-lucide-x"
              @click="removeFile"
            />
          </div>
        </div>
      </div>

      <!-- Custom Attributes Section -->
      <div>
        <div class="flex items-center justify-between mb-3">
          <label class="block text-sm font-medium text-n-slate-12">
            {{ t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_LABEL') }}
          </label>
          <Button
            variant="outline"
            size="sm"
            type="button"
            @click="addCustomAttribute"
          >
            {{ t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_ADD') }}
          </Button>
        </div>

        <div
          v-if="customAttributes.length === 0"
          class="text-sm text-n-slate-10 italic"
        >
          {{ t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_EMPTY') }}
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="(attr, index) in customAttributes"
            :key="index"
            class="flex gap-3 items-start p-3 border border-n-weak rounded-md"
          >
            <div class="flex-1">
              <Input
                v-model="attr.key"
                :placeholder="
                  t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_KEY_PLACEHOLDER')
                "
                class="mb-2"
                @blur="updateCustomAttributesForm"
              />
              <Input
                v-model="attr.label"
                :placeholder="
                  t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_LABEL_PLACEHOLDER')
                "
                class="mb-2"
              />
              <Input
                v-model="attr.value"
                :placeholder="
                  t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_VALUE_PLACEHOLDER')
                "
                @blur="updateCustomAttributesForm"
              />
            </div>
            <Button
              variant="outline"
              size="sm"
              type="button"
              @click="removeCustomAttribute(index)"
            >
              {{ t('LIBRARY.FORM.CUSTOM_ATTRIBUTES_REMOVE') }}
            </Button>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-3 pt-4 border-t border-n-weak">
        <Button variant="outline" :disabled="isLoading" @click="handleCancel">
          {{ t('LIBRARY.FORM.CANCEL') }}
        </Button>
        <Button
          type="submit"
          :disabled="!isValid || isLoading"
          :loading="isLoading"
        >
          {{ resource?.id ? t('LIBRARY.FORM.UPDATE') : t('LIBRARY.FORM.SAVE') }}
        </Button>
      </div>
    </form>
  </div>
</template>
