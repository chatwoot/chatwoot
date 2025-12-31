<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Button from 'dashboard/components-next/button/Button.vue';

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
const fileInput = ref(null);

const documents = computed(() => getters['alooDocuments/getRecords'].value);
const embeddings = computed(() => getters['alooEmbeddings/getRecords'].value);
const embeddingsMeta = computed(
  () => getters['alooEmbeddings/getMeta'].value || {}
);

onMounted(async () => {
  try {
    await Promise.all([
      store.dispatch('alooDocuments/getDocuments', {
        assistantId: props.assistantId,
      }),
      store.dispatch('alooEmbeddings/getEmbeddings', {
        assistantId: props.assistantId,
      }),
    ]);
  } catch {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isLoading.value = false;
  }
});

const handleFileSelect = async event => {
  const file = event.target.files[0];
  if (!file) return;

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
    if (fileInput.value) {
      fileInput.value.value = '';
    }
  }
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
</script>

<template>
  <div>
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <woot-loading-state :message="$t('ALOO.KNOWLEDGE.LOADING')" />
    </div>

    <template v-else>
      <SettingsSection
        :title="$t('ALOO.KNOWLEDGE.DOCUMENTS.TITLE')"
        :sub-title="$t('ALOO.KNOWLEDGE.DOCUMENTS.DESCRIPTION')"
      >
        <div class="space-y-4">
          <div>
            <input
              ref="fileInput"
              type="file"
              class="hidden"
              accept=".pdf,.txt,.md,.csv"
              @change="handleFileSelect"
            />
            <Button
              icon="i-lucide-upload"
              :is-loading="isUploading"
              @click="fileInput?.click()"
            >
              {{ $t('ALOO.KNOWLEDGE.DOCUMENTS.UPLOAD') }}
            </Button>
            <p class="mt-2 text-xs text-n-slate-10">
              {{ $t('ALOO.KNOWLEDGE.DOCUMENTS.ALLOWED_TYPES') }}
            </p>
          </div>

          <div v-if="documents.length" class="space-y-3">
            <div
              v-for="doc in documents"
              :key="doc.id"
              class="flex items-center justify-between p-4 bg-n-alpha-1 rounded-lg border border-n-weak"
            >
              <div class="flex items-center gap-3">
                <span class="i-lucide-file-text text-xl text-n-slate-9" />
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ doc.title }}
                  </p>
                  <p class="text-xs text-n-slate-10">
                    {{ formatFileSize(doc.file_size) }}
                    {{ $t('ALOO.KNOWLEDGE.EMBEDDINGS.TOTAL') }}:
                    {{ doc.chunk_count || 0 }}
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <span
                  class="px-2 py-1 text-xs font-medium rounded"
                  :class="getStatusClass(doc.status)"
                >
                  {{
                    $t(
                      `ALOO.DOCUMENTS.STATUS.${(doc.status || 'pending').toUpperCase()}`
                    )
                  }}
                </span>
                <Button
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  @click="deleteDocument(doc.id)"
                />
              </div>
            </div>
          </div>
          <div
            v-else
            class="p-8 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
          >
            <span class="i-lucide-files text-3xl text-n-slate-9" />
            <p class="text-sm text-n-slate-11 mt-2">
              {{ $t('ALOO.DOCUMENTS.EMPTY_STATE.DESCRIPTION') }}
            </p>
          </div>
        </div>
      </SettingsSection>

      <SettingsSection
        :title="$t('ALOO.KNOWLEDGE.EMBEDDINGS.TITLE')"
        :sub-title="$t('ALOO.KNOWLEDGE.EMBEDDINGS.DESCRIPTION')"
        :show-border="false"
      >
        <div class="space-y-4">
          <div class="grid grid-cols-3 gap-4">
            <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
              <p class="text-2xl font-semibold text-n-slate-12">
                {{ embeddingsMeta.total_count || 0 }}
              </p>
              <p class="text-sm text-n-slate-10">
                {{ $t('ALOO.KNOWLEDGE.EMBEDDINGS.TOTAL') }}
              </p>
            </div>
            <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
              <p class="text-2xl font-semibold text-n-green-11">
                {{ embeddingsMeta.approved_count || 0 }}
              </p>
              <p class="text-sm text-n-slate-10">
                {{ $t('ALOO.KNOWLEDGE.EMBEDDINGS.APPROVED') }}
              </p>
            </div>
            <div class="p-4 bg-n-alpha-1 rounded-lg border border-n-weak">
              <p class="text-2xl font-semibold text-n-amber-11">
                {{ embeddingsMeta.pending_count || 0 }}
              </p>
              <p class="text-sm text-n-slate-10">
                {{ $t('ALOO.KNOWLEDGE.EMBEDDINGS.PENDING') }}
              </p>
            </div>
          </div>

          <div v-if="embeddings.length" class="space-y-2">
            <div
              v-for="embedding in embeddings.slice(0, 5)"
              :key="embedding.id"
              class="p-3 bg-n-alpha-1 rounded-lg border border-n-weak"
            >
              <div class="flex items-start justify-between gap-2">
                <p class="text-sm text-n-slate-12 line-clamp-2">
                  {{ embedding.content }}
                </p>
                <span
                  class="px-2 py-0.5 text-xs font-medium rounded shrink-0"
                  :class="getStatusClass(embedding.status)"
                >
                  {{ embedding.status }}
                </span>
              </div>
              <p
                v-if="embedding.document_title"
                class="text-xs text-n-slate-10 mt-1"
              >
                {{ $t('ALOO.KNOWLEDGE.EMBEDDINGS.FROM') }}:
                {{ embedding.document_title }}
              </p>
            </div>
            <p
              v-if="embeddings.length > 5"
              class="text-sm text-n-slate-10 text-center py-2"
            >
              {{
                $t('ALOO.KNOWLEDGE.EMBEDDINGS.AND_MORE', {
                  count: embeddings.length - 5,
                })
              }}
            </p>
          </div>
          <div
            v-else
            class="p-8 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
          >
            <span class="i-lucide-database text-3xl text-n-slate-9" />
            <p class="text-sm text-n-slate-11 mt-2">
              {{ $t('ALOO.KNOWLEDGE.EMBEDDINGS.EMPTY') }}
            </p>
          </div>
        </div>
      </SettingsSection>
    </template>
  </div>
</template>
