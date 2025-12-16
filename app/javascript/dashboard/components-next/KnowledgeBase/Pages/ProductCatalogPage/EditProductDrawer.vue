<template>
  <div
    class="fixed inset-y-0 right-0 z-50 w-full max-w-2xl bg-n-background border-l border-n-weak shadow-2xl flex flex-col"
  >
    <!-- Header -->
    <div class="flex items-start justify-between p-6 border-b border-n-weak bg-n-blue-2">
      <div class="flex-1 min-w-0">
        <h2 class="text-xl font-medium text-n-slate-12 truncate">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.TITLE') }}
        </h2>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ editForm.productName }}
        </p>
      </div>
      <button
        class="flex-shrink-0 ml-4 p-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-slate-3 rounded-lg transition-colors"
        @click="handleDiscard"
      >
        <i class="i-lucide-x w-5 h-5" />
      </button>
    </div>

    <!-- Edit Form -->
    <div class="flex-1 overflow-y-auto p-6 space-y-6">
      <!-- Product Name -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.PRODUCT_NAME') }}
        </label>
        <input
          v-model="editForm.productName"
          type="text"
          :class="getFieldClass('productName')"
        />
      </div>

      <!-- Product ID (readonly) -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.PRODUCT_ID') }}
        </label>
        <input
          :value="product.product_id || product.id"
          type="text"
          disabled
          class="w-full px-4 py-2 bg-n-slate-2 border border-n-weak rounded-lg text-sm text-n-slate-11 font-mono cursor-not-allowed"
        />
      </div>

      <!-- Type & Industry -->
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.TYPE') }}
          </label>
          <input
            v-model="editForm.type"
            type="text"
            :class="getFieldClass('type')"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.INDUSTRY') }}
          </label>
          <input
            v-model="editForm.industry"
            type="text"
            :class="getFieldClass('industry')"
          />
        </div>
      </div>

      <!-- Price -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.PRICE') }}
        </label>
        <input
          v-model.number="editForm.listPrice"
          type="number"
          step="0.01"
          :class="getFieldClass('listPrice')"
        />
      </div>

      <!-- Description -->
      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.DESCRIPTION') }}
        </label>
        <textarea
          v-model="editForm.description"
          rows="4"
          :class="getFieldClass('description')"
        />
      </div>

      <!-- Media Files -->
      <div>
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-sm font-medium text-n-slate-12">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DRAWER.TITLE') }}
          </h3>
          <button
            class="inline-flex items-center gap-2 px-3 py-1.5 bg-n-blue-9 text-white rounded-lg hover:bg-n-blue-10 transition-colors text-sm"
            @click="triggerFileUpload"
          >
            <i class="i-lucide-upload w-4 h-4" />
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.UPLOAD_MEDIA') }}
          </button>
          <input
            ref="fileInputRef"
            type="file"
            multiple
            accept="image/*,video/*,.pdf"
            class="hidden"
            @change="handleFileUpload"
          />
        </div>

        <!-- Existing Media -->
        <div v-if="editForm.product_media.length > 0" class="space-y-2">
          <div
            v-for="media in editForm.product_media"
            :key="media.id"
            class="flex items-center gap-3 p-3 bg-n-slate-2 rounded-lg border border-n-weak"
          >
            <i
              class="w-5 h-5 text-n-slate-11"
              :class="{
                'i-lucide-image': media.file_type === 'IMAGE',
                'i-lucide-video': media.file_type === 'VIDEO',
                'i-lucide-file-text': media.file_type === 'DOCUMENT'
              }"
            />
            <div class="flex-1 min-w-0">
              <p class="text-sm text-n-slate-12 truncate">{{ media.file_name }}</p>
              <p class="text-xs text-n-slate-11">{{ media.file_type }}</p>
            </div>
            <button
              class="p-1.5 text-n-red-11 hover:bg-n-red-2 rounded transition-colors"
              @click="removeMedia(media.id)"
            >
              <i class="i-lucide-trash-2 w-4 h-4" />
            </button>
          </div>
        </div>

        <!-- New Files to Upload -->
        <div v-if="newFiles.length > 0" class="mt-4 space-y-2">
          <p class="text-sm font-medium text-n-green-11">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.NEW_FILES') }} ({{ newFiles.length }})
          </p>
          <div
            v-for="(file, index) in newFiles"
            :key="`new-${index}`"
            class="flex items-center gap-3 p-3 bg-n-green-2 rounded-lg border border-n-green-6"
          >
            <i class="i-lucide-file-plus w-5 h-5 text-n-green-11" />
            <div class="flex-1 min-w-0">
              <p class="text-sm text-n-slate-12 truncate">{{ file.name }}</p>
              <p class="text-xs text-n-slate-11">{{ formatFileSize(file.size) }}</p>
            </div>
            <button
              class="p-1.5 text-n-red-11 hover:bg-n-red-2 rounded transition-colors"
              @click="removeNewFile(index)"
            >
              <i class="i-lucide-x w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Footer Actions -->
    <div class="flex items-center justify-end gap-3 p-6 border-t border-n-weak bg-n-slate-2">
      <button
        class="px-4 py-2 text-n-slate-12 hover:bg-n-slate-3 rounded-lg transition-colors text-sm font-medium"
        @click="handleDiscard"
      >
        {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.DISCARD') }}
      </button>
      <button
        class="px-4 py-2 bg-n-blue-9 text-white rounded-lg hover:bg-n-blue-10 transition-colors text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="!hasChanges"
        @click="handleSave"
      >
        {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.SAVE') }}
      </button>
    </div>

    <!-- Confirmation Modal -->
    <Teleport to="body">
      <div
        v-if="showConfirmModal"
        class="fixed inset-0 z-[70] flex items-center justify-center p-6 bg-n-slate-12/80 backdrop-blur-sm"
        @click.self="showConfirmModal = false"
      >
        <div class="bg-n-background rounded-xl border border-n-weak shadow-2xl max-w-md w-full p-6">
          <h3 class="text-lg font-medium text-n-slate-12 mb-2">
            {{ confirmModalTitle }}
          </h3>
          <p class="text-sm text-n-slate-11 mb-6">
            {{ confirmModalMessage }}
          </p>
          <div class="flex items-center justify-end gap-3">
            <button
              class="px-4 py-2 text-n-slate-12 hover:bg-n-slate-3 rounded-lg transition-colors text-sm font-medium"
              @click="showConfirmModal = false"
            >
              {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.CANCEL') }}
            </button>
            <button
              class="px-4 py-2 bg-n-blue-9 text-white rounded-lg hover:bg-n-blue-10 transition-colors text-sm font-medium"
              @click="confirmAction"
            >
              {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.CONFIRM') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  product: {
    type: Object,
    required: true
  }
});

const emit = defineEmits(['close', 'saved']);

const { t } = useI18n();
const store = useStore();

const fileInputRef = ref(null);
const newFiles = ref([]);
const removedMediaIds = ref([]);
const showConfirmModal = ref(false);
const confirmModalTitle = ref('');
const confirmModalMessage = ref('');
const pendingAction = ref(null);

// Create editable form
const editForm = ref({
  productName: props.product.productName,
  type: props.product.type,
  industry: props.product.industry,
  listPrice: props.product.listPrice,
  description: props.product.description,
  product_media: [...(props.product.product_media || [])]
});

const originalForm = {
  productName: props.product.productName,
  type: props.product.type,
  industry: props.product.industry,
  listPrice: props.product.listPrice,
  description: props.product.description
};

const hasChanges = computed(() => {
  return (
    editForm.value.productName !== originalForm.productName ||
    editForm.value.type !== originalForm.type ||
    editForm.value.industry !== originalForm.industry ||
    editForm.value.listPrice !== originalForm.listPrice ||
    editForm.value.description !== originalForm.description ||
    newFiles.value.length > 0 ||
    removedMediaIds.value.length > 0
  );
});

const getFieldClass = (fieldName) => {
  const baseClass = 'w-full px-4 py-2 border rounded-lg text-sm text-n-slate-12 placeholder:text-n-slate-11 focus:outline-none focus:ring-2 focus:ring-n-blue-9 focus:border-transparent transition-colors';
  const changedClass = editForm.value[fieldName] !== originalForm[fieldName]
    ? 'bg-n-orange-2 border-n-orange-6'
    : 'bg-n-background border-n-weak';
  return `${baseClass} ${changedClass}`;
};

const formatFileSize = (bytes) => {
  if (!bytes) return '-';
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${Math.round(bytes / Math.pow(k, i) * 100) / 100} ${sizes[i]}`;
};

const triggerFileUpload = () => {
  fileInputRef.value?.click();
};

const handleFileUpload = (event) => {
  const files = Array.from(event.target.files);
  newFiles.value.push(...files);
  event.target.value = ''; // Reset input
};

const removeNewFile = (index) => {
  newFiles.value.splice(index, 1);
};

const removeMedia = (mediaId) => {
  const index = editForm.value.product_media.findIndex(m => m.id === mediaId);
  if (index !== -1) {
    editForm.value.product_media.splice(index, 1);
    removedMediaIds.value.push(mediaId);
  }
};

const handleDiscard = () => {
  if (hasChanges.value) {
    confirmModalTitle.value = t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.DISCARD_TITLE');
    confirmModalMessage.value = t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.DISCARD_MESSAGE');
    pendingAction.value = 'discard';
    showConfirmModal.value = true;
  } else {
    emit('close');
  }
};

const handleSave = () => {
  confirmModalTitle.value = t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.SAVE_TITLE');
  confirmModalMessage.value = t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.SAVE_MESSAGE');
  pendingAction.value = 'save';
  showConfirmModal.value = true;
};

const confirmAction = async () => {
  showConfirmModal.value = false;

  if (pendingAction.value === 'discard') {
    emit('close');
  } else if (pendingAction.value === 'save') {
    await saveChanges();
  }
};

const saveChanges = async () => {
  try {
    const formData = new FormData();

    // Add product fields
    formData.append('product_catalog[productName]', editForm.value.productName);
    formData.append('product_catalog[type]', editForm.value.type);
    formData.append('product_catalog[industry]', editForm.value.industry);
    formData.append('product_catalog[listPrice]', editForm.value.listPrice || '');
    formData.append('product_catalog[description]', editForm.value.description || '');

    // Add removed media IDs
    removedMediaIds.value.forEach(id => {
      formData.append('removed_media_ids[]', id);
    });

    // Add new files
    newFiles.value.forEach(file => {
      formData.append('new_media[]', file);
    });

    await store.dispatch('productCatalogs/update', {
      id: props.product.id,
      data: formData
    });

    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.SUCCESS'));
    emit('saved');
    emit('close');
  } catch (error) {
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.EDIT.ERROR'));
  }
};
</script>
