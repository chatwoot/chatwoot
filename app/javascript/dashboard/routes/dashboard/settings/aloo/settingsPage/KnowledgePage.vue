<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import AddTextBlockDialog from './AddTextBlockDialog.vue';
import AddWebsiteDialog from './AddWebsiteDialog.vue';

const props = defineProps({
  assistantId: {
    type: [String, Number],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

const isLoading = ref(true);
const isUploading = ref(false);
const isDragging = ref(false);
const fileInput = ref(null);
const expandedDocId = ref(null);
const textBlockDialogRef = ref(null);
const websiteDialogRef = ref(null);

const documents = computed(() => getters['alooDocuments/getRecords'].value);

onMounted(async () => {
  try {
    await store.dispatch('alooDocuments/getDocuments', {
      assistantId: props.assistantId,
    });
  } catch {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isLoading.value = false;
  }
});

const uploadFile = async file => {
  const formData = new FormData();
  formData.append('file', file);

  isUploading.value = true;
  try {
    await store.dispatch('alooDocuments/uploadDocument', {
      assistantId: props.assistantId,
      formData,
    });
    useAlert(t('ALOO.MESSAGES.DOCUMENT_UPLOADED'));
    await store.dispatch('alooDocuments/getDocuments', {
      assistantId: props.assistantId,
    });
  } catch {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isUploading.value = false;
  }
};

const handleDragOver = event => {
  event.preventDefault();
  isDragging.value = true;
};

const handleDragLeave = () => {
  isDragging.value = false;
};

const handleDrop = event => {
  event.preventDefault();
  isDragging.value = false;
  const file = event.dataTransfer.files[0];
  if (file) {
    uploadFile(file);
  }
};

const handleFileSelect = event => {
  const file = event.target.files[0];
  if (file) {
    uploadFile(file);
  }
  event.target.value = '';
};

const deleteDocument = async documentId => {
  try {
    await store.dispatch('alooDocuments/deleteDocument', {
      assistantId: props.assistantId,
      documentId,
    });
    useAlert(t('ALOO.MESSAGES.DOCUMENT_DELETED'));
  } catch {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  }
};

const reprocessDocument = async documentId => {
  try {
    await store.dispatch('alooDocuments/reprocessDocument', {
      assistantId: props.assistantId,
      documentId,
    });
    useAlert(t('ALOO.MESSAGES.DOCUMENT_REPROCESSING'));
    await store.dispatch('alooDocuments/getDocuments', {
      assistantId: props.assistantId,
    });
  } catch {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  }
};

const formatFileSize = bytes => {
  if (!bytes) return '0 B';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
};

const getStatusClass = status => {
  const classes = {
    pending: 'bg-n-amber-3 text-n-amber-11',
    processing: 'bg-n-blue-3 text-n-blue-11',
    available: 'bg-n-green-3 text-n-green-11',
    failed: 'bg-n-ruby-3 text-n-ruby-11',
  };
  return classes[status] || classes.pending;
};

const getStatusIcon = status => {
  const icons = {
    pending: 'i-lucide-clock',
    processing: 'i-lucide-loader-2 animate-spin',
    available: 'i-lucide-check-circle',
    failed: 'i-lucide-x-circle',
  };
  return icons[status] || icons.pending;
};

const getDocumentIcon = doc => {
  const icons = {
    website: 'i-lucide-globe',
    text: 'i-lucide-align-left',
    file: 'i-lucide-file-text',
  };
  return icons[doc.source_type] || icons.file;
};

const getDocumentMeta = doc => {
  if (doc.source_type === 'website') {
    const pages = doc.pages_scraped || 0;
    return `${pages} ${t('ALOO.KNOWLEDGE.WEBSITE.PAGES')}`;
  }
  if (doc.source_type === 'text') {
    const chars = doc.character_count || 0;
    return `${chars.toLocaleString()} ${t('ALOO.KNOWLEDGE.TEXT_BLOCK.CHARACTERS')}`;
  }
  return formatFileSize(doc.file_size);
};

const toggleExpand = docId => {
  expandedDocId.value = expandedDocId.value === docId ? null : docId;
};

const openTextBlockDialog = () => {
  textBlockDialogRef.value?.open();
};

const openWebsiteDialog = () => {
  websiteDialogRef.value?.open();
};

const handleTextBlockSubmit = async ({ title, content }) => {
  try {
    await store.dispatch('alooDocuments/addTextBlock', {
      assistantId: props.assistantId,
      title,
      content,
    });
    useAlert(t('ALOO.MESSAGES.TEXT_BLOCK_ADDED'));
    await store.dispatch('alooDocuments/getDocuments', {
      assistantId: props.assistantId,
    });
  } catch {
    useAlert(t('ALOO.MESSAGES.ERROR'));
    throw new Error('Failed to add text block');
  }
};

const handleWebsiteSubmit = async ({
  url,
  title,
  selectedPages,
  autoRefresh,
}) => {
  try {
    await store.dispatch('alooDocuments/addWebsite', {
      assistantId: props.assistantId,
      url,
      title,
      selectedPages,
      autoRefresh,
    });
    useAlert(t('ALOO.MESSAGES.WEBSITE_ADDED'));
    await store.dispatch('alooDocuments/getDocuments', {
      assistantId: props.assistantId,
    });
  } catch (error) {
    const message = error?.response?.data?.message || '';
    if (message.includes('already been added')) {
      useAlert(t('ALOO.KNOWLEDGE.WEBSITE.DUPLICATE_URL'));
    } else {
      useAlert(t('ALOO.MESSAGES.ERROR'));
    }
    throw error;
  }
};
</script>

<template>
  <div>
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <woot-loading-state :message="$t('ALOO.KNOWLEDGE.LOADING')" />
    </div>

    <template v-else>
      <div class="pt-6 space-y-6">
        <!-- Input Buttons -->
        <div class="flex items-start gap-3">
          <!-- File Upload -->
          <div
            class="flex flex-col items-start gap-2 w-32 px-4 py-3 border border-dashed rounded-lg transition-all cursor-pointer"
            :class="[
              isDragging
                ? 'border-n-blue-7 bg-n-blue-2'
                : 'border-n-weak hover:border-n-blue-7 hover:bg-n-alpha-1',
              isUploading ? 'pointer-events-none opacity-60' : '',
            ]"
            @dragover="handleDragOver"
            @dragleave="handleDragLeave"
            @drop="handleDrop"
            @click="fileInput?.click()"
          >
            <input
              ref="fileInput"
              type="file"
              class="hidden"
              accept=".pdf,.txt,.md,.csv"
              @change="handleFileSelect"
            />
            <span
              v-if="isUploading"
              class="i-lucide-loader-2 text-xl text-n-blue-9 animate-spin"
            />
            <span v-else class="i-lucide-upload text-xl text-n-slate-9" />
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('ALOO.KNOWLEDGE.DOCUMENTS.UPLOAD_TITLE') }}
            </span>
          </div>

          <!-- Website URL -->
          <div
            class="flex flex-col items-start gap-2 group w-32 px-4 py-3 border border-dashed rounded-lg transition-all cursor-pointer border-n-weak hover:border-n-blue-7 hover:bg-n-alpha-1"
            @click="openWebsiteDialog"
          >
            <span class="i-lucide-globe text-xl text-n-slate-9" />
            <span class="text-sm font-medium text-n-slate-12">
              {{ $t('ALOO.KNOWLEDGE.WEBSITE.TITLE') }}
            </span>
          </div>

          <!-- Text Block -->
          <div
            class="flex flex-col items-start gap-2 w-32 px-4 py-3 border border-dashed rounded-lg transition-all cursor-pointer border-n-weak hover:border-n-blue-7 hover:bg-n-alpha-1"
            @click="openTextBlockDialog"
          >
            <span class="i-lucide-align-left text-xl text-n-slate-9" />
            <span class="text-xs font-medium text-n-slate-12">
              {{ $t('ALOO.KNOWLEDGE.TEXT_BLOCK.CARD_TITLE') }}
            </span>
          </div>
        </div>

        <!-- Document List -->
        <div v-if="documents.length" class="space-y-2">
          <h3 class="text-sm font-medium text-n-slate-12 mb-3">
            {{ $t('ALOO.KNOWLEDGE.DOCUMENTS.LIST_TITLE') }}
          </h3>
          <div
            v-for="doc in documents"
            :key="doc.id"
            class="bg-n-alpha-1 rounded-lg border border-n-weak overflow-hidden"
          >
            <!-- Main Row -->
            <div
              class="flex items-center justify-between p-4 cursor-pointer hover:bg-n-alpha-2 transition-colors"
              @click="toggleExpand(doc.id)"
            >
              <div class="flex items-center gap-3">
                <div
                  class="w-10 h-10 rounded-lg bg-n-alpha-2 flex items-center justify-center"
                >
                  <span
                    :class="getDocumentIcon(doc)"
                    class="text-xl text-n-slate-9"
                  />
                </div>
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ doc.title }}
                  </p>
                  <p class="text-xs text-n-slate-10">
                    {{ getDocumentMeta(doc) }}
                    <span v-if="doc.chunk_count" class="ml-1">
                      {{
                        $t('ALOO.KNOWLEDGE.DOCUMENTS.CHUNK_COUNT', {
                          count: doc.chunk_count,
                        })
                      }}
                    </span>
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <div
                  class="flex items-center gap-1.5 px-2 py-1 rounded"
                  :class="getStatusClass(doc.status)"
                >
                  <span :class="getStatusIcon(doc.status)" class="text-sm" />
                  <span class="text-xs font-medium">
                    {{
                      $t(
                        `ALOO.DOCUMENTS.STATUS.${(doc.status || 'pending').toUpperCase()}`
                      )
                    }}
                  </span>
                </div>
                <span
                  class="i-lucide-chevron-down text-n-slate-9 transition-transform"
                  :class="{ 'rotate-180': expandedDocId === doc.id }"
                />
              </div>
            </div>

            <!-- Expanded Details -->
            <div
              v-if="expandedDocId === doc.id"
              class="px-4 pb-4 pt-0 border-t border-n-weak bg-n-alpha-2"
            >
              <div class="pt-3 space-y-3">
                <!-- Source URL for websites -->
                <div v-if="doc.source_type === 'website' && doc.source_url">
                  <p class="text-xs text-n-slate-10 mb-1">
                    {{ $t('ALOO.KNOWLEDGE.DETAILS.SOURCE_URL') }}
                  </p>
                  <a
                    :href="doc.source_url"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-sm text-n-blue-11 hover:underline flex items-center gap-1"
                  >
                    {{ doc.source_url }}
                    <span class="i-lucide-external-link text-xs" />
                  </a>
                </div>

                <!-- File info for files -->
                <div v-if="doc.source_type === 'file' && doc.filename">
                  <p class="text-xs text-n-slate-10 mb-1">
                    {{ $t('ALOO.KNOWLEDGE.DETAILS.FILENAME') }}
                  </p>
                  <p class="text-sm text-n-slate-12">{{ doc.filename }}</p>
                </div>

                <!-- Text content preview -->
                <div
                  v-if="doc.source_type === 'text' && doc.text_content_preview"
                >
                  <p class="text-xs text-n-slate-10 mb-1">
                    {{ $t('ALOO.KNOWLEDGE.DETAILS.CONTENT_PREVIEW') }}
                  </p>
                  <p class="text-sm text-n-slate-11 italic line-clamp-3">
                    {{
                      $t('ALOO.KNOWLEDGE.DETAILS.CONTENT_QUOTED', {
                        content: doc.text_content_preview,
                      })
                    }}
                  </p>
                </div>

                <!-- Scrape info for websites -->
                <div v-if="doc.source_type === 'website'">
                  <p class="text-xs text-n-slate-10 mb-1">
                    {{ $t('ALOO.KNOWLEDGE.DETAILS.SCRAPE_MODE') }}
                  </p>
                  <p class="text-sm text-n-slate-12">
                    <template v-if="doc.selected_pages?.length">
                      {{
                        $t('ALOO.KNOWLEDGE.DETAILS.SELECTED_PAGES', {
                          count: doc.selected_pages.length,
                        })
                      }}
                    </template>
                    <template v-else-if="doc.crawl_full_site">
                      {{ $t('ALOO.KNOWLEDGE.DETAILS.FULL_SITE') }}
                    </template>
                    <template v-else>
                      {{ $t('ALOO.KNOWLEDGE.DETAILS.SINGLE_PAGE') }}
                    </template>
                  </p>
                </div>

                <!-- Auto-refresh info for websites -->
                <div v-if="doc.source_type === 'website' && doc.auto_refresh">
                  <p class="text-xs text-n-slate-10 mb-1">
                    {{ $t('ALOO.KNOWLEDGE.DETAILS.AUTO_REFRESH') }}
                  </p>
                  <div class="flex items-center gap-2">
                    <span class="i-lucide-refresh-cw text-n-green-9 text-sm" />
                    <span class="text-sm text-n-slate-12">
                      {{ $t('ALOO.KNOWLEDGE.DETAILS.AUTO_REFRESH_ENABLED') }}
                    </span>
                  </div>
                  <p
                    v-if="doc.next_refresh_at"
                    class="text-xs text-n-slate-10 mt-1"
                  >
                    {{
                      $t('ALOO.KNOWLEDGE.DETAILS.NEXT_REFRESH_DATE', {
                        date: new Date(doc.next_refresh_at).toLocaleString(),
                      })
                    }}
                  </p>
                </div>

                <!-- Created at -->
                <div>
                  <p class="text-xs text-n-slate-10 mb-1">
                    {{ $t('ALOO.KNOWLEDGE.DETAILS.ADDED') }}
                  </p>
                  <p class="text-sm text-n-slate-12">
                    {{ new Date(doc.created_at).toLocaleString() }}
                  </p>
                </div>

                <!-- Actions -->
                <div class="flex items-center gap-2 pt-2">
                  <Button
                    v-if="doc.status === 'failed'"
                    icon="i-lucide-refresh-cw"
                    xs
                    faded
                    @click.stop="reprocessDocument(doc.id)"
                  >
                    {{ $t('ALOO.ACTIONS.REPROCESS') }}
                  </Button>
                  <Button
                    icon="i-lucide-trash-2"
                    xs
                    ruby
                    faded
                    @click.stop="deleteDocument(doc.id)"
                  >
                    {{ $t('ALOO.ACTIONS.DELETE') }}
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div
          v-else
          class="p-12 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
        >
          <div
            class="w-16 h-16 rounded-full bg-n-alpha-2 flex items-center justify-center mx-auto mb-4"
          >
            <span class="i-lucide-book-open text-3xl text-n-slate-9" />
          </div>
          <p class="text-sm font-medium text-n-slate-12 mb-1">
            {{ $t('ALOO.DOCUMENTS.EMPTY_STATE.TITLE') }}
          </p>
          <p class="text-sm text-n-slate-10">
            {{ $t('ALOO.DOCUMENTS.EMPTY_STATE.DESCRIPTION') }}
          </p>
        </div>
      </div>

      <!-- Dialogs -->
      <AddTextBlockDialog
        ref="textBlockDialogRef"
        @submit="handleTextBlockSubmit"
      />
      <AddWebsiteDialog
        ref="websiteDialogRef"
        :assistant-id="assistantId"
        @submit="handleWebsiteSubmit"
      />
    </template>
  </div>
</template>
