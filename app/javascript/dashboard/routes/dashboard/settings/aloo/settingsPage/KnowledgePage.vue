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
const isAddingWebsite = ref(false);
const fileInput = ref(null);
const websiteUrl = ref('');
const crawlFullSite = ref(false);

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

const getDocumentIcon = doc => {
  return doc.source_type === 'website'
    ? 'i-lucide-globe'
    : 'i-lucide-file-text';
};

const getDocumentMeta = doc => {
  if (doc.source_type === 'website') {
    const pages = doc.pages_scraped || 0;
    return `${pages} ${t('ALOO.KNOWLEDGE.WEBSITE.PAGES')}`;
  }
  return formatFileSize(doc.file_size);
};

const addWebsite = async () => {
  if (!websiteUrl.value) return;

  isAddingWebsite.value = true;
  try {
    await store.dispatch('alooDocuments/addWebsite', {
      assistantId: props.assistantId,
      url: websiteUrl.value,
      crawlFullSite: crawlFullSite.value,
    });
    useAlert(t('ALOO.MESSAGES.WEBSITE_ADDED'));
    websiteUrl.value = '';
    crawlFullSite.value = false;
    await store.dispatch('alooDocuments/getDocuments', {
      assistantId: props.assistantId,
    });
  } catch {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isAddingWebsite.value = false;
  }
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
          <div class="flex gap-4">
            <div class="flex-1">
              <h4 class="text-sm font-medium text-n-slate-12 mb-2">
                {{ $t('ALOO.KNOWLEDGE.DOCUMENTS.UPLOAD_TITLE') }}
              </h4>
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

            <div class="flex-1">
              <h4 class="text-sm font-medium text-n-slate-12 mb-2">
                {{ $t('ALOO.KNOWLEDGE.WEBSITE.TITLE') }}
              </h4>
              <div class="flex gap-2">
                <input
                  v-model="websiteUrl"
                  type="url"
                  class="flex-1 px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 text-sm"
                  :placeholder="$t('ALOO.KNOWLEDGE.WEBSITE.URL_PLACEHOLDER')"
                />
                <Button
                  icon="i-lucide-globe"
                  :is-loading="isAddingWebsite"
                  :disabled="!websiteUrl"
                  @click="addWebsite"
                >
                  {{ $t('ALOO.KNOWLEDGE.WEBSITE.ADD') }}
                </Button>
              </div>
              <label class="flex items-center gap-2 mt-2">
                <input
                  v-model="crawlFullSite"
                  type="checkbox"
                  class="rounded border-n-weak"
                />
                <span class="text-sm text-n-slate-10">
                  {{ $t('ALOO.KNOWLEDGE.WEBSITE.CRAWL_FULL_SITE') }}
                </span>
              </label>
              <p class="mt-1 text-xs text-n-slate-9">
                {{ $t('ALOO.KNOWLEDGE.WEBSITE.CRAWL_DESCRIPTION') }}
              </p>
            </div>
          </div>

          <div v-if="documents.length" class="space-y-3">
            <div
              v-for="doc in documents"
              :key="doc.id"
              class="flex items-center justify-between p-4 bg-n-alpha-1 rounded-lg border border-n-weak"
            >
              <div class="flex items-center gap-3">
                <span
                  :class="getDocumentIcon(doc)"
                  class="text-xl text-n-slate-9"
                />
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ doc.title }}
                  </p>
                  <p class="text-xs text-n-slate-10">
                    {{ getDocumentMeta(doc) }} ·
                    {{ $t('ALOO.KNOWLEDGE.DOCUMENTS.CHUNKS') }}:
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
    </template>
  </div>
</template>
