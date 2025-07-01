<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { MAXIMUM_FILE_UPLOAD_SIZE } from 'shared/constants/messages';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import Auth from 'dashboard/api/auth';
import Modal from 'dashboard/components/Modal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'refresh']);

const { t } = useI18n();
const store = useStore();
const accountId = ref(store.getters.getCurrentAccountId);

const selectedSourceType = ref('webpage');
const fileUploadInput = ref(null);
const webpageUrl = ref('');
const crawlSubpages = ref(false);
const isLoading = ref(false);

const selectSourceType = type => {
  selectedSourceType.value = type;
};

const openFileBrowser = () => {
  fileUploadInput.value.click();
};

const closeModal = () => {
  // Reset form state
  selectedSourceType.value = 'webpage';
  webpageUrl.value = '';
  crawlSubpages.value = false;
  isLoading.value = false;
  emit('close');
};

// Create knowledge base record via API
const createKnowledgeBase = async (name, blobId, url = null) => {
  try {
    const requestBody = {
      knowledge_base: {
        name,
        source_type: selectedSourceType.value,
        url,
      },
      file_blob_id: blobId,
    };

    // Get auth headers from the auth system
    const authData = Auth.getAuthData();

    const headers = {
      'Content-Type': 'application/json',
    };

    if (authData) {
      headers['access-token'] = authData['access-token'];
      headers['token-type'] = authData['token-type'];
      headers.client = authData.client;
      headers.expiry = authData.expiry;
      headers.uid = authData.uid;
    }

    const response = await fetch(
      `/api/v1/accounts/${accountId.value}/knowledge_bases`,
      {
        method: 'POST',
        headers,
        body: JSON.stringify(requestBody),
      }
    );

    if (response.ok) {
      await response.json();
      useAlert(t('KNOWLEDGE_SOURCE.SUCCESS_MESSAGE'));
      closeModal();
      emit('refresh'); // Refresh the knowledge sources list
    } else {
      await response.json();
      throw new Error('Failed to create knowledge source');
    }
  } catch (error) {
    useAlert(t('KNOWLEDGE_SOURCE.CREATE_ERROR'));
  }
};

// Handle file selection and upload
const onFileChange = async event => {
  const file = event.target.files[0];
  if (!file) return;

  if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
    isLoading.value = true;
    try {
      const { blobId, fileUrl } = await uploadFile(file, accountId.value);
      await createKnowledgeBase(file.name, blobId, fileUrl);
    } catch (error) {
      useAlert(t('KNOWLEDGE_SOURCE.FILE.UPLOAD_ERROR'));
    } finally {
      isLoading.value = false;
    }
  } else {
    useAlert(t('KNOWLEDGE_SOURCE.FILE.SIZE_LIMIT_ERROR'));
  }

  // Reset the input so the same file can be selected again
  if (fileUploadInput.value) {
    fileUploadInput.value.value = '';
  }
};

// Handle webpage URL submission
const onUrlSubmit = async () => {
  if (!webpageUrl.value.trim()) {
    useAlert(t('KNOWLEDGE_SOURCE.WEBPAGE.URL_REQUIRED'));
    return;
  }

  isLoading.value = true;
  try {
    await createKnowledgeBase(webpageUrl.value, null, webpageUrl.value);
  } catch (error) {
    useAlert(t('KNOWLEDGE_SOURCE.URL.UPLOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

// Handle image URL submission (currently unused but may be needed for future URL image uploads)
// const onImageUrlSubmit = async url => {
//   isLoading.value = true;
//   try {
//     const { blobId } = await uploadExternalImage(url, accountId.value);
//     await createKnowledgeBase(url, blobId, url);
//   } catch (error) {
//     useAlert(t('KNOWLEDGE_SOURCE.URL.UPLOAD_ERROR'));
//   } finally {
//     isLoading.value = false;
//   }
// };
</script>

<template>
  <Modal :show="show" :on-close="closeModal" size="medium">
    <div class="flex flex-col">
      <!-- Hidden file input -->
      <input
        ref="fileUploadInput"
        type="file"
        class="hidden"
        @change="onFileChange"
      />

      <!-- Modal Header -->
      <woot-modal-header :header-title="t('ADD_KNOWLEDGE_SOURCE_BUTTON')" />

      <!-- Modal Body -->
      <div class="p-6">
        <!-- Source Type Selection -->
        <div class="mb-6">
          <h3
            class="text-sm font-medium text-slate-900 dark:text-slate-100 mb-3"
          >
            {{ t('KNOWLEDGE_SOURCE.CHOOSE_TYPE') }}
          </h3>
          <div class="grid grid-cols-3 gap-3">
            <!-- Webpage Option -->
            <div
              class="flex flex-col items-center p-4 border-2 rounded-lg cursor-pointer transition-colors"
              :class="{
                'border-woot-500 bg-woot-50 dark:bg-woot-900/20':
                  selectedSourceType === 'webpage',
                'border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:hover:border-slate-600':
                  selectedSourceType !== 'webpage',
              }"
              @click="selectSourceType('webpage')"
            >
              <i
                class="i-lucide-globe text-2xl mb-2 text-slate-600 dark:text-slate-400"
              />
              <span
                class="text-sm font-medium text-slate-900 dark:text-slate-100"
              >
                {{ t('KNOWLEDGE_SOURCE.WEBPAGE.TITLE') }}
              </span>
            </div>

            <!-- File Option -->
            <div
              class="flex flex-col items-center p-4 border-2 rounded-lg cursor-pointer transition-colors"
              :class="{
                'border-woot-500 bg-woot-50 dark:bg-woot-900/20':
                  selectedSourceType === 'file',
                'border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:hover:border-slate-600':
                  selectedSourceType !== 'file',
              }"
              @click="selectSourceType('file')"
            >
              <i
                class="i-lucide-file-text text-2xl mb-2 text-slate-600 dark:text-slate-400"
              />
              <span
                class="text-sm font-medium text-slate-900 dark:text-slate-100"
              >
                {{ t('KNOWLEDGE_SOURCE.FILE.TITLE') }}
              </span>
            </div>

            <!-- Image Option -->
            <div
              class="flex flex-col items-center p-4 border-2 rounded-lg cursor-pointer transition-colors"
              :class="{
                'border-woot-500 bg-woot-50 dark:bg-woot-900/20':
                  selectedSourceType === 'image',
                'border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:hover:border-slate-600':
                  selectedSourceType !== 'image',
              }"
              @click="selectSourceType('image')"
            >
              <i
                class="i-lucide-image text-2xl mb-2 text-slate-600 dark:text-slate-400"
              />
              <span
                class="text-sm font-medium text-slate-900 dark:text-slate-100"
              >
                {{ t('KNOWLEDGE_SOURCE.IMAGE.TITLE') }}
              </span>
            </div>
          </div>
        </div>

        <!-- Dynamic Content Based on Selected Type -->

        <!-- Webpage View -->
        <div v-if="selectedSourceType === 'webpage'" class="space-y-4">
          <div>
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ t('KNOWLEDGE_SOURCE.WEBPAGE.URL_LABEL') }}
            </label>
            <input
              v-model="webpageUrl"
              type="url"
              class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-woot-500 dark:bg-slate-800 dark:text-slate-100"
              :placeholder="t('KNOWLEDGE_SOURCE.WEBPAGE.URL_PLACEHOLDER')"
            />
          </div>
          <div class="flex items-center">
            <input
              id="crawl-subpages"
              v-model="crawlSubpages"
              type="checkbox"
              class="rounded border-slate-300 text-woot-600 focus:ring-woot-500 dark:border-slate-600 dark:bg-slate-800"
            />
            <label
              for="crawl-subpages"
              class="ml-2 text-sm text-slate-700 dark:text-slate-300"
            >
              {{ t('KNOWLEDGE_SOURCE.WEBPAGE.CRAWL_SUBPAGES') }}
            </label>
          </div>
        </div>

        <!-- File View -->
        <div v-if="selectedSourceType === 'file'" class="space-y-4">
          <div
            class="text-center py-8 border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-lg"
          >
            <i class="i-lucide-upload text-4xl text-slate-400 mb-4" />
            <h4
              class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-2"
            >
              {{ t('KNOWLEDGE_SOURCE.FILE.UPLOAD_TITLE') }}
            </h4>
            <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
              {{ t('KNOWLEDGE_SOURCE.FILE.UPLOAD_DESCRIPTION') }}
            </p>
            <NextButton @click="openFileBrowser">
              {{ t('KNOWLEDGE_SOURCE.FILE.BROWSE') }}
            </NextButton>
          </div>
          <p class="text-xs text-slate-500 dark:text-slate-400 text-center">
            {{ t('KNOWLEDGE_SOURCE.FILE.SUPPORTED_TYPES') }}
          </p>
        </div>

        <!-- Image View -->
        <div v-if="selectedSourceType === 'image'" class="space-y-4">
          <div
            class="text-center py-8 border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-lg"
          >
            <i class="i-lucide-image text-4xl text-slate-400 mb-4" />
            <h4
              class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-2"
            >
              {{ t('KNOWLEDGE_SOURCE.IMAGE.UPLOAD_TITLE') }}
            </h4>
            <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
              {{ t('KNOWLEDGE_SOURCE.IMAGE.UPLOAD_DESCRIPTION') }}
            </p>
            <NextButton @click="openFileBrowser">
              {{ t('KNOWLEDGE_SOURCE.IMAGE.BROWSE') }}
            </NextButton>
          </div>
          <p class="text-xs text-slate-500 dark:text-slate-400 text-center">
            {{ t('KNOWLEDGE_SOURCE.IMAGE.SUPPORTED_TYPES') }}
          </p>
        </div>
      </div>

      <!-- Modal Footer -->
      <div
        class="flex items-center justify-end gap-3 p-6 border-t border-slate-200 dark:border-slate-700"
      >
        <NextButton slate outline @click="closeModal">
          {{ t('KNOWLEDGE_SOURCE.CANCEL') }}
        </NextButton>
        <NextButton
          v-if="selectedSourceType === 'webpage'"
          :loading="isLoading"
          :disabled="isLoading"
          @click="onUrlSubmit"
        >
          {{ t('KNOWLEDGE_SOURCE.CONTINUE') }}
        </NextButton>
        <NextButton
          v-else
          :loading="isLoading"
          :disabled="isLoading"
          @click="openFileBrowser"
        >
          {{ t('KNOWLEDGE_SOURCE.ADD_SOURCE') }}
        </NextButton>
      </div>
    </div>
  </Modal>
</template>
