<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import MessageFormatter from 'shared/helpers/MessageFormatter';
import {
  isSafeHttpLink,
  formatDocumentLink,
  getDocumentDisplayPath,
} from 'shared/helpers/documentHelper';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import ResponseCard from '../../assistant/ResponseCard.vue';

const props = defineProps({
  captainDocument: {
    type: Object,
    required: true,
  },
});
const emit = defineEmits(['close']);
const TAB_KEYS = {
  CONTENT: 'content',
  FAQS: 'faqs',
};
const RESPONSES_PER_PAGE = 25;
const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);
const documentDetails = computed(() => props.captainDocument);
const showRawContent = ref(false);
const activeTabIndex = ref(0);

const uiFlags = useMapGetter('captainResponses/getUIFlags');
const responses = useMapGetter('captainResponses/getRecords');
const meta = useMapGetter('captainResponses/getMeta');
const isFetching = computed(() => uiFlags.value.fetchingList);
const totalCount = computed(() => meta.value.totalCount || 0);
const currentPage = computed(() => meta.value.page || 1);
const showPaginationFooter = computed(
  () => totalCount.value > RESPONSES_PER_PAGE
);
const documentContent = computed(() => documentDetails.value?.content?.trim());
const documentContentLength = computed(
  () => documentContent.value?.length || 0
);
const isPdf = computed(() => documentDetails.value?.pdf_document);
const displayUrl = computed(() => documentDetails.value?.display_url);
const externalLink = computed(() => documentDetails.value?.external_link);
const sourceHref = computed(() => displayUrl.value || externalLink.value);
const hasSafeLink = computed(() => isSafeHttpLink(sourceHref.value));
const displayLink = computed(() => {
  if (isPdf.value) return formatDocumentLink(externalLink.value);
  return getDocumentDisplayPath(displayUrl.value || externalLink.value);
});
const contentTabLabel = computed(() =>
  isPdf.value
    ? t('CAPTAIN.DOCUMENTS.DETAILS.PDF_TAB')
    : t('CAPTAIN.DOCUMENTS.DETAILS.CONTENT_TAB')
);
const tabs = computed(() => [
  { key: TAB_KEYS.CONTENT, label: contentTabLabel.value },
  {
    key: TAB_KEYS.FAQS,
    label: t('CAPTAIN.DOCUMENTS.RELATED_RESPONSES.TITLE'),
    count: totalCount.value,
  },
]);
const activeTabKey = computed(() => tabs.value[activeTabIndex.value]?.key);
const isUnreadableContent = computed(() => {
  if (!documentContent.value) return false;

  const content = documentContent.value;
  const sample = content.slice(0, 2000);
  const characters = Array.from(sample);
  const nonPrintableCharacters = characters.filter(character => {
    const charCode = character.charCodeAt(0);
    return (
      (charCode <= 31 && ![9, 10, 13].includes(charCode)) ||
      (charCode >= 127 && charCode <= 159)
    );
  });
  const nonPrintableRatio =
    nonPrintableCharacters.length / Math.max(characters.length, 1);
  const replacementCharacterRatio =
    characters.filter(character => character === '\uFFFD').length /
    Math.max(characters.length, 1);
  const hasPdfObjectMarkers =
    content.includes(' obj') &&
    content.includes(' endobj') &&
    content.includes(' stream');

  return (
    content.startsWith('%PDF') ||
    hasPdfObjectMarkers ||
    nonPrintableRatio > 0.02 ||
    replacementCharacterRatio > 0.05
  );
});
const formattedDocumentContent = computed(() => {
  if (!documentContent.value || isUnreadableContent.value) return '';

  const formatter = new MessageFormatter(documentContent.value);
  formatter.disableImageRendering();
  return formatter.formattedMessage;
});
const updatedAtLabel = computed(() => {
  if (!documentDetails.value?.updated_at) return null;
  return messageTimestamp(
    documentDetails.value.updated_at,
    'MMM d, yyyy h:mm a'
  );
});
const syncedAtLabel = computed(() => {
  if (!documentDetails.value?.last_synced_at) return null;
  return messageTimestamp(
    documentDetails.value.last_synced_at,
    'MMM d, yyyy h:mm a'
  );
});

const handleClose = () => {
  emit('close');
};

const handleCopyContent = async () => {
  try {
    await copyTextToClipboard(documentContent.value);
    useAlert(t('CAPTAIN.DOCUMENTS.DETAILS.COPY_SUCCESS'));
  } catch {
    useAlert(t('CAPTAIN.DOCUMENTS.DETAILS.COPY_ERROR'));
  }
};

const handleTabChanged = tab => {
  activeTabIndex.value = tabs.value.findIndex(item => item.key === tab.key);
};

const fetchResponses = (page = 1) => {
  return store.dispatch('captainResponses/get', {
    page,
    assistantId: props.captainDocument.assistant.id,
    documentId: props.captainDocument.id,
  });
};

const handlePageChange = page => {
  fetchResponses(page);
};

onMounted(() => {
  fetchResponses();
});
defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="documentDetails.name || documentDetails.external_link"
    :description="t('CAPTAIN.DOCUMENTS.DETAILS.DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    width="3xl"
    @close="handleClose"
  >
    <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div v-else class="flex flex-col gap-6 min-h-48">
      <section class="flex flex-col gap-3">
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div class="flex flex-col gap-1">
            <span class="text-xs font-medium uppercase text-n-slate-10">
              {{ t('CAPTAIN.DOCUMENTS.DETAILS.SOURCE') }}
            </span>
            <a
              v-if="hasSafeLink"
              :href="sourceHref"
              :title="sourceHref"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center min-w-0 gap-1 text-sm text-n-slate-12 hover:underline"
            >
              <Icon icon="i-lucide-external-link" class="size-3 shrink-0" />
              <span class="truncate">{{ displayLink }}</span>
            </a>
            <span v-else class="text-sm truncate text-n-slate-12">
              {{ displayLink }}
            </span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs font-medium uppercase text-n-slate-10">
              {{ t('CAPTAIN.DOCUMENTS.DETAILS.GENERATED_FAQS') }}
            </span>
            <span class="text-sm text-n-slate-12">
              {{ totalCount }}
            </span>
          </div>
          <div class="flex flex-col gap-1">
            <span class="text-xs font-medium uppercase text-n-slate-10">
              {{ t('CAPTAIN.DOCUMENTS.DETAILS.LAST_UPDATED') }}
            </span>
            <span class="text-sm text-n-slate-12">
              {{
                syncedAtLabel ||
                updatedAtLabel ||
                t('CAPTAIN.DOCUMENTS.DETAILS.NOT_AVAILABLE')
              }}
            </span>
          </div>
        </div>
      </section>

      <TabBar
        :tabs="tabs"
        :initial-active-tab="activeTabIndex"
        @tab-changed="handleTabChanged"
      />

      <div class="h-[32rem] overflow-y-auto">
        <section
          v-if="activeTabKey === TAB_KEYS.CONTENT"
          class="flex flex-col gap-3"
        >
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div class="flex flex-col gap-1">
              <h4 class="text-sm font-medium text-n-slate-12">
                {{
                  isPdf
                    ? t('CAPTAIN.DOCUMENTS.DETAILS.PDF_TITLE')
                    : t('CAPTAIN.DOCUMENTS.DETAILS.CONTENT_TITLE')
                }}
              </h4>
              <span
                v-if="documentContent && !isPdf"
                class="text-xs text-n-slate-10"
              >
                {{
                  t('CAPTAIN.DOCUMENTS.DETAILS.CHARACTER_COUNT', {
                    count: documentContentLength.toLocaleString(),
                  })
                }}
              </span>
            </div>
            <div
              v-if="documentContent && !isPdf"
              class="flex flex-wrap items-center justify-end gap-4"
            >
              <Button
                :label="
                  showRawContent
                    ? t('CAPTAIN.DOCUMENTS.DETAILS.VIEW_PREVIEW')
                    : t('CAPTAIN.DOCUMENTS.DETAILS.VIEW_RAW')
                "
                sm
                slate
                link
                @click="showRawContent = !showRawContent"
              />
              <Button
                :label="t('CAPTAIN.DOCUMENTS.DETAILS.COPY_CONTENT')"
                icon="i-lucide-copy"
                sm
                slate
                link
                @click="handleCopyContent"
              />
            </div>
          </div>
          <div
            v-if="isPdf"
            class="rounded-lg border border-n-weak bg-n-alpha-1 p-4 text-sm text-n-slate-11"
          >
            <p class="mb-3">
              {{ t('CAPTAIN.DOCUMENTS.DETAILS.PDF_DESCRIPTION') }}
            </p>
            <a
              v-if="hasSafeLink"
              :href="sourceHref"
              :title="sourceHref"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 font-medium text-n-blue-11 hover:underline"
            >
              <Icon icon="i-ph-file-pdf" class="size-4" />
              {{ displayLink }}
              <Icon icon="i-lucide-external-link" class="size-3" />
            </a>
            <span v-else class="inline-flex items-center gap-1 text-n-slate-12">
              <Icon icon="i-ph-file-pdf" class="size-4" />
              {{ displayLink }}
            </span>
          </div>
          <template v-else-if="documentContent">
            <div
              v-if="isUnreadableContent && !showRawContent"
              class="rounded-lg border border-dashed border-n-weak p-4 text-sm text-n-slate-11"
            >
              {{ t('CAPTAIN.DOCUMENTS.DETAILS.UNREADABLE_CONTENT') }}
            </div>
            <div
              v-else
              class="h-[26rem] overflow-y-auto rounded-lg border border-n-weak bg-n-alpha-1 p-4"
            >
              <pre
                v-if="showRawContent || isUnreadableContent"
                class="m-0 whitespace-pre-wrap break-words text-xs leading-5 text-n-slate-12"
              ><code>{{ documentContent }}</code></pre>
              <div
                v-else
                v-dompurify-html="formattedDocumentContent"
                class="prose prose-sm max-w-none break-words text-n-slate-12 prose-p:my-2 prose-headings:mb-2 prose-headings:mt-4 prose-a:text-n-blue-11 prose-ul:my-2 prose-ol:my-2 prose-li:my-1 prose-img:hidden"
              />
            </div>
          </template>
          <div
            v-else
            class="rounded-lg border border-dashed border-n-weak p-4 text-sm text-n-slate-11"
          >
            {{ t('CAPTAIN.DOCUMENTS.DETAILS.EMPTY_CONTENT') }}
          </div>
        </section>

        <section
          v-if="activeTabKey === TAB_KEYS.FAQS"
          class="flex flex-col gap-3"
        >
          <div v-if="responses.length" class="flex flex-col gap-3">
            <ResponseCard
              v-for="response in responses"
              :id="response.id"
              :key="response.id"
              :question="response.question"
              :status="response.status"
              :answer="response.answer"
              :assistant="response.assistant"
              :created-at="response.created_at"
              :updated-at="response.updated_at"
              compact
            />
          </div>
          <div
            v-else
            class="rounded-lg border border-dashed border-n-weak p-4 text-sm text-n-slate-11"
          >
            {{ t('CAPTAIN.DOCUMENTS.RELATED_RESPONSES.EMPTY') }}
          </div>
          <footer v-if="showPaginationFooter" class="sticky bottom-0 z-10">
            <PaginationFooter
              :current-page="currentPage"
              :total-items="totalCount"
              :items-per-page="RESPONSES_PER_PAGE"
              class="!px-0"
              @update:current-page="handlePageChange"
            />
          </footer>
        </section>
      </div>
    </div>
  </Dialog>
</template>
