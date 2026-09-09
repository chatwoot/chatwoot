<script setup>
import { computed, ref, shallowRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import { downloadCsvFile } from 'dashboard/helper/downloadHelper';
import CaptainFaqImportsAPI from 'dashboard/api/captain/faqImports';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['close', 'confirmed']);

const ROW_STATE_STYLES = {
  invalid: {
    icon: 'i-lucide-circle-alert',
    iconClass: 'text-n-ruby-10',
    textClass: 'text-n-ruby-11',
  },
  duplicate: {
    icon: 'i-lucide-circle-minus',
    iconClass: 'text-n-slate-10',
    textClass: 'text-n-slate-11',
  },
};

const { t } = useI18n();

const dialogRef = ref(null);
const fileInput = ref(null);
const selectedFile = ref(null);
const preview = shallowRef(null);
const overwriteRowNumbers = ref(new Set());
const isUploading = ref(false);
const isConfirming = ref(false);
const isDownloading = ref(false);
const isPreviewActionPending = computed(
  () => isConfirming.value || isDownloading.value
);

const rows = computed(() => preview.value?.rows || []);
const invalidCount = computed(() => preview.value?.invalid_row_count || 0);
const existingCount = computed(
  () => rows.value.filter(row => row.state === 'existing').length
);
const validCount = computed(
  () => rows.value.filter(row => row.state === 'valid').length
);
const readyCount = computed(
  () => validCount.value + overwriteRowNumbers.value.size
);
const existingRowActions = computed(() => [
  { value: 'skip', label: t('CAPTAIN.RESPONSES.IMPORT.ACTIONS.SKIP') },
  {
    value: 'overwrite',
    label: t('CAPTAIN.RESPONSES.IMPORT.ACTIONS.OVERWRITE'),
  },
]);
const tableHeaders = computed(() => [
  t('CAPTAIN.RESPONSES.IMPORT.TABLE.ROW'),
  t('CAPTAIN.RESPONSES.IMPORT.TABLE.QUESTION'),
  t('CAPTAIN.RESPONSES.IMPORT.TABLE.ANSWER'),
  t('CAPTAIN.RESPONSES.IMPORT.TABLE.STATUS'),
]);
const sampleRows = computed(() => [
  {
    question: t('CAPTAIN.RESPONSES.IMPORT.SAMPLE.QUESTION_1'),
    answer: t('CAPTAIN.RESPONSES.IMPORT.SAMPLE.ANSWER_1'),
  },
  {
    question: t('CAPTAIN.RESPONSES.IMPORT.SAMPLE.QUESTION_2'),
    answer: t('CAPTAIN.RESPONSES.IMPORT.SAMPLE.ANSWER_2'),
  },
  {
    question: t('CAPTAIN.RESPONSES.IMPORT.SAMPLE.QUESTION_3'),
    answer: t('CAPTAIN.RESPONSES.IMPORT.SAMPLE.ANSWER_3'),
  },
]);

const close = () => dialogRef.value?.close();

const reset = () => {
  preview.value = null;
  selectedFile.value = null;
};

const openFilePicker = () => fileInput.value?.click();

const handleFileChange = event => {
  selectedFile.value = event.target.files?.[0] || null;
};

const uploadForPreview = async () => {
  isUploading.value = true;
  try {
    const { data } = await CaptainFaqImportsAPI.create({
      assistantId: props.assistantId,
      file: selectedFile.value,
    });
    preview.value = data;
    overwriteRowNumbers.value = new Set();
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) ||
        t('CAPTAIN.RESPONSES.IMPORT.ERRORS.PREVIEW')
    );
  } finally {
    isUploading.value = false;
  }
};

const setExistingRowAction = (rowNumber, action) => {
  const selectedRows = new Set(overwriteRowNumbers.value);
  selectedRows[action === 'overwrite' ? 'add' : 'delete'](rowNumber);
  overwriteRowNumbers.value = selectedRows;
};

// Dismissing the dialog mid-confirm must not unmount the component, or the
// page would never receive `confirmed` and miss the import status.
const handleClose = () => {
  if (isConfirming.value) return;
  emit('close');
};

const confirmImport = async () => {
  isConfirming.value = true;
  let response;
  try {
    response = await CaptainFaqImportsAPI.confirm({
      assistantId: props.assistantId,
      importId: preview.value.id,
      overwriteRowNumbers: [...overwriteRowNumbers.value],
    });
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) ||
        t('CAPTAIN.RESPONSES.IMPORT.ERRORS.CONFIRM')
    );
    return;
  } finally {
    isConfirming.value = false;
  }

  useAlert(t('CAPTAIN.RESPONSES.IMPORT.SUCCESS'));
  emit('confirmed', response.data);
  close();
};

const downloadInvalidRows = async () => {
  isDownloading.value = true;
  try {
    const { data } = await CaptainFaqImportsAPI.downloadInvalidRows({
      assistantId: props.assistantId,
      importId: preview.value.id,
    });
    const originalName = preview.value.original_filename.replace(/\.csv$/i, '');
    downloadCsvFile(`${originalName}-invalid-rows.csv`, data);
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) ||
        t('CAPTAIN.RESPONSES.IMPORT.ERRORS.DOWNLOAD')
    );
  } finally {
    isDownloading.value = false;
  }
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="3xl"
    position="top"
    overflow-y-auto
    :title="$t('CAPTAIN.RESPONSES.IMPORT.TITLE')"
    :description="$t('CAPTAIN.RESPONSES.IMPORT.DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <div v-if="!preview" class="flex flex-col gap-4">
      <button
        type="button"
        class="flex min-h-32 w-full flex-col items-center justify-center gap-2 rounded-xl border border-dashed border-n-strong bg-n-background px-6 py-5 text-center transition-colors hover:bg-n-background/50"
        @click="openFilePicker"
      >
        <Icon icon="i-lucide-file-up" class="size-6 text-n-slate-10" />
        <span class="text-sm font-medium text-n-slate-12">
          {{ selectedFile?.name || $t('CAPTAIN.RESPONSES.IMPORT.CHOOSE_FILE') }}
        </span>
        <span class="text-xs text-n-slate-10">
          {{ $t('CAPTAIN.RESPONSES.IMPORT.FILE_HELP') }}
        </span>

        <div
          v-if="!selectedFile"
          data-testid="csv-format-sample"
          aria-hidden="true"
          class="mt-3 w-full max-w-lg overflow-hidden rounded-lg border border-n-strong bg-n-solid-1 text-start shadow-sm"
        >
          <div
            class="grid grid-cols-2 divide-x divide-n-weak border-b border-n-strong bg-n-solid-2 text-xs font-medium text-n-slate-12"
          >
            <span class="px-3 py-2">
              {{ $t('CAPTAIN.RESPONSES.IMPORT.SAMPLE.QUESTION_HEADER') }}
            </span>
            <span class="px-3 py-2">
              {{ $t('CAPTAIN.RESPONSES.IMPORT.SAMPLE.ANSWER_HEADER') }}
            </span>
          </div>
          <div
            class="divide-y divide-n-weak [mask-image:linear-gradient(to_bottom,#000_20%,transparent_100%)] [-webkit-mask-image:linear-gradient(to_bottom,#000_20%,transparent_100%)]"
          >
            <div
              v-for="row in sampleRows"
              :key="row.question"
              class="grid grid-cols-2 divide-x divide-n-weak text-xs text-n-slate-11"
            >
              <span class="truncate px-3 py-2">
                {{ row.question }}
              </span>
              <span class="truncate px-3 py-2">
                {{ row.answer }}
              </span>
            </div>
          </div>
        </div>
      </button>
      <input
        ref="fileInput"
        type="file"
        accept=".csv,text/csv"
        class="hidden"
        @change="handleFileChange"
      />
    </div>

    <div v-else class="flex min-h-0 flex-col gap-4">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div class="flex flex-wrap items-center gap-2 text-xs text-n-slate-11">
          <span
            class="inline-flex items-center gap-1.5 rounded-full bg-n-alpha-2 px-2.5 py-1"
          >
            <Icon icon="i-lucide-file-spreadsheet" class="size-3.5" />
            {{ preview.original_filename }}
          </span>
          <span class="rounded-full bg-n-alpha-2 px-2.5 py-1">
            {{
              $t('CAPTAIN.RESPONSES.IMPORT.ROW_COUNT', {
                count: preview.row_count,
              })
            }}
          </span>
          <span
            v-if="existingCount"
            class="rounded-full bg-n-amber-3 px-2.5 py-1 text-n-amber-11"
          >
            {{
              $t('CAPTAIN.RESPONSES.IMPORT.EXISTING_COUNT', {
                count: existingCount,
              })
            }}
          </span>
          <span
            v-if="invalidCount"
            class="rounded-full bg-n-ruby-3 px-2.5 py-1 text-n-ruby-11"
          >
            {{
              $t('CAPTAIN.RESPONSES.IMPORT.INVALID_COUNT', {
                count: invalidCount,
              })
            }}
          </span>
        </div>
        <Button
          v-if="invalidCount"
          :label="$t('CAPTAIN.RESPONSES.IMPORT.DOWNLOAD_INVALID')"
          icon="i-lucide-download"
          variant="ghost"
          color="slate"
          size="sm"
          :is-loading="isDownloading"
          :disabled="isPreviewActionPending"
          @click="downloadInvalidRows"
        />
      </div>

      <p class="mb-0 text-sm text-n-slate-11">
        {{ $t('CAPTAIN.RESPONSES.IMPORT.PREVIEW_HELP') }}
      </p>

      <div
        class="max-h-[28rem] overflow-auto rounded-xl border border-n-strong"
      >
        <BaseTable
          class="[&_table]:table-fixed [&_table]:divide-n-strong [&_tbody]:divide-n-strong [&_thead]:sticky [&_thead]:top-0 [&_thead]:z-10 [&_thead]:bg-n-solid-2 [&_thead]:border-t-0 [&_th:first-child]:ps-4 [&_td:first-child]:ps-4 [&_th:first-child]:w-14 [&_th:nth-child(2)]:w-[28%] [&_th:last-child]:w-44"
          :headers="tableHeaders"
          :items="rows"
        >
          <template #row="{ items }">
            <BaseTableRow
              v-for="row in items"
              :key="row.row_number"
              :item="row"
              class="align-top"
            >
              <BaseTableCell
                :id="`faq-import-row-${row.row_number}`"
                class="tabular-nums text-n-slate-10"
              >
                {{ row.row_number }}
              </BaseTableCell>
              <BaseTableCell
                :id="`faq-import-question-${row.row_number}`"
                class="whitespace-pre-wrap break-words font-medium text-n-slate-12"
              >
                {{ row.question }}
              </BaseTableCell>
              <BaseTableCell class="whitespace-pre-wrap break-words">
                <div
                  v-if="row.state === 'existing'"
                  class="flex flex-col gap-2"
                >
                  <div>
                    <span class="text-xs text-n-slate-10">
                      {{ $t('CAPTAIN.RESPONSES.IMPORT.EXISTING_ANSWER') }}
                    </span>
                    <p class="mb-0 mt-0.5">{{ row.existing_answer }}</p>
                  </div>
                  <div>
                    <span class="text-xs text-n-slate-10">
                      {{ $t('CAPTAIN.RESPONSES.IMPORT.IMPORTED_ANSWER') }}
                    </span>
                    <p class="mb-0 mt-0.5">{{ row.answer }}</p>
                  </div>
                </div>
                <template v-else>{{ row.answer }}</template>
              </BaseTableCell>
              <BaseTableCell>
                <div
                  v-if="row.state === 'existing'"
                  class="flex flex-col gap-2"
                >
                  <span class="text-xs font-medium text-n-amber-11">
                    {{ $t('CAPTAIN.RESPONSES.IMPORT.STATES.EXISTING') }}
                  </span>
                  <div
                    class="flex flex-col gap-1.5"
                    role="radiogroup"
                    :aria-labelledby="`faq-import-row-${row.row_number} faq-import-question-${row.row_number}`"
                  >
                    <label
                      v-for="action in existingRowActions"
                      :key="action.value"
                      class="inline-flex items-center gap-2"
                      :class="
                        isConfirming
                          ? 'cursor-not-allowed opacity-50'
                          : 'cursor-pointer'
                      "
                    >
                      <input
                        type="radio"
                        :name="`faq-import-row-${row.row_number}`"
                        :value="action.value"
                        :checked="
                          overwriteRowNumbers.has(row.row_number) ===
                          (action.value === 'overwrite')
                        "
                        :disabled="isConfirming"
                        class="grid size-5 shrink-0 cursor-pointer appearance-none place-items-center rounded-full border-2 border-n-strong shadow before:rounded-full before:border-4 before:border-n-strong before:bg-n-brand before:content-[''] checked:border checked:border-n-brand checked:bg-n-brand checked:before:h-[18px] checked:before:w-[18px] disabled:cursor-not-allowed"
                        @change="
                          setExistingRowAction(row.row_number, action.value)
                        "
                      />
                      <span class="text-xs text-n-slate-12">
                        {{ action.label }}
                      </span>
                    </label>
                  </div>
                </div>
                <div
                  v-else-if="ROW_STATE_STYLES[row.state]"
                  class="flex gap-1.5"
                >
                  <Icon
                    :icon="ROW_STATE_STYLES[row.state].icon"
                    class="mt-0.5 size-3.5 shrink-0"
                    :class="ROW_STATE_STYLES[row.state].iconClass"
                  />
                  <span
                    class="text-xs"
                    :class="ROW_STATE_STYLES[row.state].textClass"
                  >
                    {{
                      row.state === 'duplicate'
                        ? $t('CAPTAIN.RESPONSES.IMPORT.STATES.SKIPPED')
                        : row.error
                    }}
                  </span>
                </div>
                <span v-else class="text-xs font-medium text-n-teal-11">
                  {{ $t('CAPTAIN.RESPONSES.IMPORT.STATES.READY') }}
                </span>
              </BaseTableCell>
            </BaseTableRow>
          </template>
        </BaseTable>
      </div>
    </div>

    <template #footer>
      <div class="flex w-full items-center justify-between gap-3">
        <Button
          v-if="preview"
          :label="$t('CAPTAIN.RESPONSES.IMPORT.UPLOAD_ANOTHER')"
          variant="ghost"
          color="slate"
          :disabled="isPreviewActionPending"
          @click="reset"
        />
        <Button
          v-else
          :label="$t('DIALOG.BUTTONS.CANCEL')"
          variant="faded"
          color="slate"
          @click="close"
        />
        <Button
          v-if="preview && readyCount > 0"
          :label="$t('CAPTAIN.RESPONSES.IMPORT.CONFIRM', { count: readyCount })"
          :is-loading="isConfirming"
          :disabled="isPreviewActionPending"
          @click="confirmImport"
        />
        <Button
          v-else-if="!preview"
          :label="$t('CAPTAIN.RESPONSES.IMPORT.PREVIEW')"
          :is-loading="isUploading"
          :disabled="!selectedFile || isUploading"
          @click="uploadForPreview"
        />
      </div>
    </template>
  </Dialog>
</template>
