<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();
const { accountScopedRoute } = useAccount();

const documents = computed(() => getters['alooWizard/getDocuments'].value);

const isDragging = ref(false);
const websiteUrl = ref('');
const crawlFullSite = ref(false);

const acceptedTypes = [
  'application/pdf',
  'text/plain',
  'text/csv',
  'text/markdown',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
];
const acceptedExtensions = '.pdf,.txt,.csv,.md,.xlsx,.xls,.docx,.doc,.pptx';

const isAcceptedExtension = filename => {
  const ext = filename.split('.').pop().toLowerCase();
  return [
    'pdf',
    'txt',
    'csv',
    'md',
    'xlsx',
    'xls',
    'docx',
    'doc',
    'pptx',
  ].includes(ext);
};

const addDocument = file => {
  const id = Date.now();
  store.dispatch('alooWizard/addDocument', {
    id,
    file,
    name: file.name,
    size: file.size,
    status: 'pending',
  });
};

const handleFiles = files => {
  files.forEach(file => {
    if (!acceptedTypes.includes(file.type) && !isAcceptedExtension(file.name)) {
      useAlert(t('ALOO.DOCUMENTS.STATUS.UNSUPPORTED'));
      return;
    }
    if (file.size > 10 * 1024 * 1024) {
      useAlert(t('ALOO.DOCUMENTS.MAX_SIZE'));
      return;
    }
    addDocument(file);
  });
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
  const files = Array.from(event.dataTransfer.files);
  handleFiles(files);
};

const handleFileSelect = event => {
  const files = Array.from(event.target.files);
  handleFiles(files);
  event.target.value = '';
};

const removeDocument = documentId => {
  const index = documents.value.findIndex(doc => doc.id === documentId);
  if (index !== -1) {
    store.dispatch('alooWizard/removeDocument', index);
  }
};

const formatFileSize = bytes => {
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
    return doc.source_url;
  }
  return formatFileSize(doc.size);
};

const normalizeUrl = urlString => {
  try {
    const url = new URL(urlString);
    const host = url.hostname.toLowerCase().replace(/^www\./, '');
    const path = url.pathname.replace(/\/+$/, '') || '/';
    return `${host}${path}`;
  } catch {
    return urlString;
  }
};

const addWebsite = () => {
  if (!websiteUrl.value) return;

  try {
    const url = new URL(websiteUrl.value);
    const normalizedNew = normalizeUrl(websiteUrl.value);

    // Check for duplicate
    const isDuplicate = documents.value.some(
      doc =>
        doc.source_type === 'website' &&
        normalizeUrl(doc.source_url) === normalizedNew
    );

    if (isDuplicate) {
      useAlert(t('ALOO.KNOWLEDGE.WEBSITE.DUPLICATE_URL'));
      return;
    }

    const id = Date.now();
    store.dispatch('alooWizard/addDocument', {
      id,
      source_type: 'website',
      source_url: websiteUrl.value,
      name: url.hostname.replace(/^www\./, ''),
      crawl_full_site: crawlFullSite.value,
      status: 'pending',
    });
    websiteUrl.value = '';
    crawlFullSite.value = false;
  } catch {
    useAlert(t('ALOO.KNOWLEDGE.WEBSITE.INVALID_URL'));
  }
};

const goToNext = () => {
  router.push(accountScopedRoute('settings_aloo_new_assign'));
};

const goBack = () => {
  router.push(accountScopedRoute('settings_aloo_new_personality'));
};

const skipStep = () => {
  goToNext();
};
</script>

<template>
  <div class="flex flex-col h-full p-8">
    <div class="flex-1 overflow-y-auto">
      <h2 class="text-xl font-semibold text-n-slate-12 mb-2">
        {{ $t('ALOO.WIZARD.STEP_3') }}
      </h2>
      <p class="text-n-slate-11 mb-8">
        {{ $t('ALOO.WIZARD.STEP_3_DESCRIPTION') }}
      </p>

      <div class="max-w-2xl">
        <div class="flex gap-6">
          <!-- Upload Zone -->
          <div
            class="flex-1 border-2 border-dashed rounded-xl p-8 text-center transition-colors cursor-pointer"
            :class="[
              isDragging
                ? 'border-n-blue-7 bg-n-blue-2'
                : 'border-n-weak hover:border-n-blue-7 hover:bg-n-alpha-1',
            ]"
            @dragover="handleDragOver"
            @dragleave="handleDragLeave"
            @drop="handleDrop"
            @click="$refs.fileInput.click()"
          >
            <input
              ref="fileInput"
              type="file"
              multiple
              :accept="acceptedExtensions"
              class="hidden"
              @change="handleFileSelect"
            />
            <div class="flex flex-col items-center gap-3">
              <span class="i-lucide-upload-cloud text-4xl text-n-slate-9" />
              <p class="text-n-slate-12 font-medium">
                {{ $t('ALOO.DOCUMENTS.DROP_FILES') }}
              </p>
              <p class="text-sm text-n-slate-10">
                {{ $t('ALOO.DOCUMENTS.SUPPORTED_FORMATS') }}
              </p>
              <p class="text-xs text-n-slate-9">
                {{ $t('ALOO.DOCUMENTS.MAX_SIZE') }}
              </p>
            </div>
          </div>

          <!-- Website URL Input -->
          <div class="flex-1 border-2 border-dashed rounded-xl p-8">
            <div class="flex flex-col items-center gap-3">
              <span class="i-lucide-globe text-4xl text-n-slate-9" />
              <p class="text-n-slate-12 font-medium">
                {{ $t('ALOO.KNOWLEDGE.WEBSITE.TITLE') }}
              </p>
              <input
                v-model="websiteUrl"
                type="url"
                class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder-n-slate-9 text-sm"
                :placeholder="$t('ALOO.KNOWLEDGE.WEBSITE.URL_PLACEHOLDER')"
                @keyup.enter="addWebsite"
              />
              <label class="flex items-center gap-2 w-full">
                <input
                  v-model="crawlFullSite"
                  type="checkbox"
                  class="rounded border-n-weak"
                />
                <span class="text-sm text-n-slate-10">
                  {{ $t('ALOO.KNOWLEDGE.WEBSITE.CRAWL_FULL_SITE') }}
                </span>
              </label>
              <Button
                icon="i-lucide-plus"
                :disabled="!websiteUrl"
                class="w-full"
                @click="addWebsite"
              >
                {{ $t('ALOO.KNOWLEDGE.WEBSITE.ADD') }}
              </Button>
            </div>
          </div>
        </div>

        <!-- Document List -->
        <div v-if="documents.length" class="mt-6 space-y-3">
          <h3 class="text-sm font-medium text-n-slate-12">
            {{ $t('ALOO.DOCUMENTS.TITLE') }}
          </h3>
          <div
            v-for="doc in documents"
            :key="doc.id"
            class="flex items-center justify-between p-3 bg-n-alpha-1 rounded-lg border border-n-weak"
          >
            <div class="flex items-center gap-3">
              <span
                :class="getDocumentIcon(doc)"
                class="text-xl text-n-slate-9"
              />
              <div>
                <p class="text-sm font-medium text-n-slate-12">
                  {{ doc.name }}
                </p>
                <p class="text-xs text-n-slate-10">
                  {{ getDocumentMeta(doc) }}
                </p>
              </div>
            </div>
            <div class="flex items-center gap-3">
              <span
                class="px-2 py-1 text-xs font-medium rounded"
                :class="getStatusClass(doc.status)"
              >
                {{ $t(`ALOO.DOCUMENTS.STATUS.${doc.status.toUpperCase()}`) }}
              </span>
              <button
                class="p-1 rounded hover:bg-n-alpha-2 text-n-slate-10 hover:text-n-ruby-9"
                @click.stop="removeDocument(doc.id)"
              >
                <span class="i-lucide-x text-lg" />
              </button>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div
          v-else
          class="mt-6 p-6 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
        >
          <span class="i-lucide-files text-3xl text-n-slate-9 mb-2" />
          <p class="text-sm text-n-slate-11">
            {{ $t('ALOO.DOCUMENTS.EMPTY_STATE.DESCRIPTION') }}
          </p>
        </div>
      </div>
    </div>

    <div class="flex justify-between pt-6 border-t border-n-weak">
      <Button variant="faded" slate @click="goBack">
        {{ $t('ALOO.ACTIONS.BACK') }}
      </Button>
      <div class="flex gap-3">
        <Button variant="faded" slate @click="skipStep">
          {{ $t('ALOO.ACTIONS.SKIP') }}
        </Button>
        <Button @click="goToNext">
          {{ $t('ALOO.ACTIONS.NEXT') }}
        </Button>
      </div>
    </div>
  </div>
</template>
