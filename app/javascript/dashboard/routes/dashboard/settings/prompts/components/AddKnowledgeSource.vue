<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Modal from 'dashboard/components/Modal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['close']);
const { t } = useI18n();

const sourceTypes = [
  {
    id: 'webpage',
    name: 'KNOWLEDGE_SOURCE.TYPE.WEBPAGE',
    icon: 'i-lucide-globe',
  },
  {
    id: 'file',
    name: 'KNOWLEDGE_SOURCE.TYPE.FILE',
    icon: 'i-lucide-file-text',
  },
  {
    id: 'image',
    name: 'KNOWLEDGE_SOURCE.TYPE.IMAGE',
    icon: 'i-lucide-image',
  },
];

const selectedSourceType = ref('webpage');
const publicURL = ref('');
const crawlSubpages = ref(false);

const selectSourceType = type => {
  selectedSourceType.value = type;
};

const closeModal = () => {
  emit('close');
};

const actionButtonText = computed(() => {
  if (selectedSourceType.value === 'webpage') {
    return 'KNOWLEDGE_SOURCE.ACTIONS.CONTINUE';
  }
  return 'KNOWLEDGE_SOURCE.ACTIONS.ADD_SOURCE';
});

const handleContinue = () => {
  // Handle the continuation logic
  closeModal();
};
</script>

<template>
  <Modal show :on-close="closeModal">
    <div class="flex flex-col">
      <div class="p-6 border-b border-slate-50 dark:border-slate-800">
        <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">
          {{ t('KNOWLEDGE_SOURCE.TITLE') }}
        </h3>
      </div>
      <div class="p-6">
        <div class="flex flex-col gap-4">
          <div>
            <label
              class="text-sm font-medium text-slate-900 dark:text-slate-100"
            >
              {{ t('KNOWLEDGE_SOURCE.TYPE.LABEL') }}
            </label>
            <div class="grid grid-cols-3 gap-3 mt-2">
              <button
                v-for="sourceType in sourceTypes"
                :key="sourceType.id"
                class="flex flex-col items-center justify-center p-4 border rounded-lg transition-colors"
                :class="{
                  'border-woot-500 bg-woot-50 dark:bg-woot-800/20 text-woot-600 dark:text-woot-500':
                    selectedSourceType === sourceType.id,
                  'border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:hover:border-slate-600':
                    selectedSourceType !== sourceType.id,
                }"
                @click="selectSourceType(sourceType.id)"
              >
                <Icon :icon="sourceType.icon" class="w-6 h-6" />
                <span class="mt-2 text-sm font-medium">
                  {{ t(sourceType.name) }}
                </span>
              </button>
            </div>
          </div>

          <!-- Webpage View -->
          <template v-if="selectedSourceType === 'webpage'">
            <div>
              <label
                for="public-url"
                class="flex items-center text-sm font-medium text-slate-900 dark:text-slate-100"
              >
                {{ t('KNOWLEDGE_SOURCE.WEBPAGE.PUBLIC_URL') }}
                <Icon
                  icon="i-lucide-info"
                  class="w-3 h-3 ml-1 text-slate-500"
                />
              </label>
              <input
                id="public-url"
                v-model="publicURL"
                type="text"
                class="mt-1 w-full p-2 border border-slate-300 dark:border-slate-600 rounded-md focus:ring-woot-500 focus:border-woot-500 dark:bg-slate-800"
              />
            </div>
            <div class="flex items-center">
              <input
                id="crawl-subpages"
                v-model="crawlSubpages"
                type="checkbox"
                class="h-4 w-4 text-woot-600 border-slate-300 rounded focus:ring-woot-500"
              />
              <label
                for="crawl-subpages"
                class="ml-2 flex items-center text-sm text-slate-900 dark:text-slate-100"
              >
                {{ t('KNOWLEDGE_SOURCE.WEBPAGE.CRAWL_SUBPAGES') }}
                <Icon
                  icon="i-lucide-info"
                  class="w-3 h-3 ml-1 text-slate-500"
                />
              </label>
            </div>
          </template>

          <!-- File View -->
          <div v-if="selectedSourceType === 'file'">
            <label
              class="text-sm font-medium text-slate-900 dark:text-slate-100"
            >
              {{ t('KNOWLEDGE_SOURCE.FILE.LABEL') }}
            </label>
            <div class="mt-2">
              <NextButton>
                {{ t('KNOWLEDGE_SOURCE.FILE.BROWSE') }}
              </NextButton>
              <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">
                {{ t('KNOWLEDGE_SOURCE.FILE.SUPPORTED_TYPES') }}
              </p>
            </div>
          </div>

          <!-- Image View -->
          <div v-if="selectedSourceType === 'image'">
            <label
              class="text-sm font-medium text-slate-900 dark:text-slate-100"
            >
              {{ t('KNOWLEDGE_SOURCE.IMAGE.LABEL') }}
            </label>
            <div class="mt-2">
              <NextButton>
                {{ t('KNOWLEDGE_SOURCE.IMAGE.BROWSE') }}
              </NextButton>
              <p class="mt-2 text-sm text-slate-500 dark:text-slate-400">
                {{ t('KNOWLEDGE_SOURCE.IMAGE.SUPPORTED_TYPES') }}
              </p>
            </div>
          </div>
        </div>
      </div>
      <div
        class="flex justify-end gap-2 p-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-100 dark:border-slate-800"
      >
        <NextButton variant="smooth" @click="closeModal">
          {{ t('KNOWLEDGE_SOURCE.ACTIONS.CANCEL') }}
        </NextButton>
        <NextButton @click="handleContinue">
          {{ t(actionButtonText) }}
        </NextButton>
      </div>
    </div>
  </Modal>
</template>
