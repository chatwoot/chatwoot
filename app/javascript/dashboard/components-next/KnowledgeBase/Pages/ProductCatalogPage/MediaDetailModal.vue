<template>
  <div
    class="fixed inset-0 z-[60] flex items-center justify-center p-6 bg-n-slate-1/95 backdrop-blur-sm"
    @click.self="emit('close')"
  >
    <div class="bg-n-background rounded-xl border border-n-weak shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col">
      <!-- Header -->
      <div class="flex items-start justify-between p-6 border-b border-n-weak">
        <div class="flex-1 min-w-0">
          <h3 class="text-lg font-medium text-n-slate-12 truncate">
            {{ media.file_name }}
          </h3>
          <p class="text-sm text-n-slate-11 mt-1">
            {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.TITLE') }}
          </p>
        </div>
        <button
          class="flex-shrink-0 ml-4 p-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-slate-3 rounded-lg transition-colors"
          @click="emit('close')"
        >
          <i class="i-lucide-x w-5 h-5" />
        </button>
      </div>

      <!-- Content -->
      <div class="flex-1 overflow-y-auto p-6">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Preview -->
          <div class="space-y-4">
            <h4 class="text-sm font-medium text-n-slate-12">
              {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.PREVIEW') }}
            </h4>
            <div class="bg-n-slate-2 rounded-xl overflow-hidden aspect-video flex items-center justify-center">
              <img
                v-if="media.file_type === 'IMAGE'"
                :src="media.file_url"
                :alt="media.file_name"
                class="w-full h-full object-contain"
              />
              <video
                v-else-if="media.file_type === 'VIDEO'"
                :src="media.file_url"
                controls
                class="w-full h-full"
              />
              <div v-else class="text-center p-8">
                <i class="i-lucide-file-text w-16 h-16 text-n-slate-9 mb-4" />
                <p class="text-sm text-n-slate-11">
                  {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.NO_PREVIEW') }}
                </p>
                <a
                  :href="media.file_url"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="inline-flex items-center gap-2 mt-4 px-4 py-2 bg-n-blue-9 text-white rounded-lg hover:bg-n-blue-10 transition-colors text-sm"
                >
                  <i class="i-lucide-external-link w-4 h-4" />
                  {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.OPEN_FILE') }}
                </a>
              </div>
            </div>
          </div>

          <!-- Details -->
          <div class="space-y-4">
            <h4 class="text-sm font-medium text-n-slate-12">
              {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.DETAILS') }}
            </h4>
            <div class="bg-n-slate-2 rounded-xl p-4 space-y-3">
              <div class="flex justify-between items-start">
                <span class="text-sm text-n-slate-11">
                  {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.FILE_NAME') }}
                </span>
                <span class="text-sm text-n-slate-12 font-medium text-right">
                  {{ media.file_name }}
                </span>
              </div>

              <div class="flex justify-between items-start">
                <span class="text-sm text-n-slate-11">
                  {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.FILE_TYPE') }}
                </span>
                <span class="inline-flex items-center gap-1.5 px-2 py-1 bg-n-blue-3 text-n-blue-11 rounded text-xs font-medium">
                  <i
                    class="w-3.5 h-3.5"
                    :class="{
                      'i-lucide-image': media.file_type === 'IMAGE',
                      'i-lucide-video': media.file_type === 'VIDEO',
                      'i-lucide-file-text': media.file_type === 'DOCUMENT'
                    }"
                  />
                  {{ media.file_type }}
                </span>
              </div>

              <div v-if="media.mime_type" class="flex justify-between items-start">
                <span class="text-sm text-n-slate-11">
                  {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.MIME_TYPE') }}
                </span>
                <span class="text-sm text-n-slate-12 font-mono">
                  {{ media.mime_type }}
                </span>
              </div>

              <div v-if="media.file_size" class="flex justify-between items-start">
                <span class="text-sm text-n-slate-11">
                  {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.FILE_SIZE') }}
                </span>
                <span class="text-sm text-n-slate-12 font-medium">
                  {{ formatFileSize(media.file_size) }}
                </span>
              </div>

              <div v-if="media.created_at" class="flex justify-between items-start">
                <span class="text-sm text-n-slate-11">
                  {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.UPLOADED_AT') }}
                </span>
                <span class="text-sm text-n-slate-12">
                  {{ formatDateTime(media.created_at) }}
                </span>
              </div>

              <div class="flex justify-between items-start">
                <span class="text-sm text-n-slate-11">
                  {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.DISPLAY_ORDER') }}
                </span>
                <span class="text-sm text-n-slate-12 font-medium">
                  {{ media.display_order + 1 }}
                </span>
              </div>

              <div v-if="media.is_primary" class="pt-3 border-t border-n-weak">
                <div class="flex items-center gap-2 text-n-green-11">
                  <i class="i-lucide-star w-4 h-4" />
                  <span class="text-sm font-medium">
                    {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.PRIMARY_MEDIA') }}
                  </span>
                </div>
              </div>
            </div>

            <!-- URL -->
            <div class="space-y-2">
              <h4 class="text-sm font-medium text-n-slate-12">
                {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.URL') }}
              </h4>
              <div class="flex items-center gap-2">
                <input
                  :value="media.file_url"
                  readonly
                  class="flex-1 px-3 py-2 bg-n-slate-2 border border-n-weak rounded-lg text-sm text-n-slate-12 font-mono"
                />
                <button
                  class="p-2 bg-n-slate-2 border border-n-weak rounded-lg text-n-slate-11 hover:text-n-slate-12 hover:bg-n-slate-3 transition-colors"
                  @click="copyToClipboard(media.file_url)"
                >
                  <i class="i-lucide-copy w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-end gap-3 p-6 border-t border-n-weak">
        <Button
          variant="outline"
          :label="$t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.CLOSE')"
          @click="emit('close')"
        />
        <a
          :href="media.file_url"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center gap-2 px-4 py-2 bg-n-blue-9 text-white rounded-lg hover:bg-n-blue-10 transition-colors text-sm font-medium"
        >
          <i class="i-lucide-external-link w-4 h-4" />
          {{ $t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.OPEN_IN_NEW_TAB') }}
        </a>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

defineProps({
  media: {
    type: Object,
    required: true
  }
});

const emit = defineEmits(['close']);

const formatFileSize = (bytes) => {
  if (!bytes) return '-';
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${Math.round(bytes / Math.pow(k, i) * 100) / 100} ${sizes[i]}`;
};

const formatDateTime = (dateString) => {
  if (!dateString) return '-';
  const date = new Date(dateString);
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: 'numeric'
  }).format(date);
};

const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text);
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.URL_COPIED'));
  } catch (error) {
    useAlert(t('KNOWLEDGE_BASE.PRODUCT_CATALOG.MEDIA_DETAIL.COPY_FAILED'));
  }
};

const handleKeydown = (event) => {
  if (event.key === 'Escape' || event.keyCode === 27) {
    event.preventDefault();
    event.stopPropagation();
    emit('close');
  }
};

onMounted(() => {
  document.addEventListener('keydown', handleKeydown, true);
});

onUnmounted(() => {
  document.removeEventListener('keydown', handleKeydown, true);
});
</script>
