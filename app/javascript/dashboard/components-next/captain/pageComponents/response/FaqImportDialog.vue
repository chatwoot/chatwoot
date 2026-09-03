<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import CaptainFaqImportsAPI from 'dashboard/api/captain/faqImports';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['close', 'confirmed']);
const EXISTING_ROW_ACTIONS = ['skip', 'overwrite'];
const { t } = useI18n();

const dialogRef = ref(null);
const fileInput = ref(null);
const selectedFile = ref(null);
const preview = ref(null);
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
const readyCount = computed(
  () =>
    rows.value.filter(row => row.state === 'valid').length +
    overwriteRowNumbers.value.size
);
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
  if (isPreviewActionPending.value) return;

  preview.value = null;
  selectedFile.value = null;
  overwriteRowNumbers.value = new Set();
  if (fileInput.value) fileInput.value.value = '';
};

const openFilePicker = () => fileInput.value?.click();

const handleFileChange = event => {
  selectedFile.value = event.target.files?.[0] || null;
};

const uploadForPreview = async () => {
  if (!selectedFile.value) return;

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
      error?.response?.data?.error ||
        error?.response?.data?.message ||
        error?.message ||
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

const existingRowActionLabel = action =>
  action === 'overwrite'
    ? t('CAPTAIN.RESPONSES.IMPORT.ACTIONS.OVERWRITE')
    : t('CAPTAIN.RESPONSES.IMPORT.ACTIONS.SKIP');

const confirmImport = async () => {
  if (!readyCount.value || isPreviewActionPending.value) return;

  isConfirming.value = true;
  try {
    const { data } = await CaptainFaqImportsAPI.confirm({
      assistantId: props.assistantId,
      importId: preview.value.id,
      overwriteRowNumbers: [...overwriteRowNumbers.value],
    });
    useAlert(t('CAPTAIN.RESPONSES.IMPORT.SUCCESS'));
    emit('confirmed', data);
    close();
  } catch (error) {
    useAlert(
      error?.response?.data?.error ||
        error?.response?.data?.message ||
        error?.message ||
        t('CAPTAIN.RESPONSES.IMPORT.ERRORS.CONFIRM')
    );
  } finally {
    isConfirming.value = false;
  }
};

const downloadInvalidRows = async () => {
  if (!preview.value || isPreviewActionPending.value) return;

  isDownloading.value = true;
  let url;
  try {
    const { data } = await CaptainFaqImportsAPI.downloadInvalidRows({
      assistantId: props.assistantId,
      importId: preview.value.id,
    });
    url = URL.createObjectURL(data);
    const link = document.createElement('a');
    const originalName = preview.value.original_filename.replace(/\.csv$/i, '');
    link.href = url;
    link.download = `${originalName}-invalid-rows.csv`;
    link.click();
  } catch (error) {
    useAlert(error?.message || t('CAPTAIN.RESPONSES.IMPORT.ERRORS.DOWNLOAD'));
  } finally {
    if (url) URL.revokeObjectURL(url);
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
    @close="emit('close')"
  >
    <div v-if="!preview" class="flex flex-col gap-4">
      <button
        type="button"
        class="flex min-h-32 w-full flex-col items-center justify-center gap-2 rounded-xl border border-dashed border-n-strong bg-n-alpha-2 px-6 py-5 text-center transition-colors hover:border-n-brand hover:bg-n-blue-2"
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
          class="mt-3 w-full max-w-lg overflow-hidden rounded-lg border border-n-weak bg-n-solid-1 text-start shadow-sm"
        >
          <div
            class="grid grid-cols-2 divide-x divide-n-weak border-b border-n-weak bg-n-solid-2 text-xs font-medium text-n-slate-12"
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

      <div class="max-h-[28rem] overflow-auto rounded-xl border border-n-weak">
        <table class="w-full table-fixed border-collapse text-start text-sm">
          <thead class="sticky top-0 z-10 bg-n-solid-2 text-xs text-n-slate-10">
            <tr>
              <th class="w-14 px-3 py-2.5 text-start font-medium">
                {{ $t('CAPTAIN.RESPONSES.IMPORT.TABLE.ROW') }}
              </th>
              <th class="w-[28%] px-3 py-2.5 text-start font-medium">
                {{ $t('CAPTAIN.RESPONSES.IMPORT.TABLE.QUESTION') }}
              </th>
              <th class="px-3 py-2.5 text-start font-medium">
                {{ $t('CAPTAIN.RESPONSES.IMPORT.TABLE.ANSWER') }}
              </th>
              <th class="w-44 px-3 py-2.5 text-start font-medium">
                {{ $t('CAPTAIN.RESPONSES.IMPORT.TABLE.STATUS') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-n-weak">
            <tr
              v-for="row in rows"
              :key="row.row_number"
              class="align-top text-n-slate-11"
            >
              <td
                :id="`faq-import-row-${row.row_number}`"
                class="px-3 py-3 tabular-nums text-n-slate-10"
              >
                {{ row.row_number }}
              </td>
              <td
                :id="`faq-import-question-${row.row_number}`"
                class="whitespace-pre-wrap break-words px-3 py-3 font-medium text-n-slate-12"
              >
                {{ row.question }}
              </td>
              <td class="whitespace-pre-wrap break-words px-3 py-3">
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
              </td>
              <td class="px-3 py-3">
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
                      v-for="action in EXISTING_ROW_ACTIONS"
                      :key="action"
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
                        :value="action"
                        :checked="
                          action === 'overwrite'
                            ? overwriteRowNumbers.has(row.row_number)
                            : !overwriteRowNumbers.has(row.row_number)
                        "
                        :disabled="isConfirming"
                        class="size-4 accent-n-blue-9"
                        @change="setExistingRowAction(row.row_number, action)"
                      />
                      <span class="text-xs text-n-slate-12">
                        {{ existingRowActionLabel(action) }}
                      </span>
                    </label>
                  </div>
                </div>
                <div
                  v-else-if="['invalid', 'duplicate'].includes(row.state)"
                  class="flex gap-1.5"
                >
                  <Icon
                    :icon="
                      row.state === 'invalid'
                        ? 'i-lucide-circle-alert'
                        : 'i-lucide-circle-minus'
                    "
                    class="mt-0.5 size-3.5 shrink-0"
                    :class="
                      row.state === 'invalid'
                        ? 'text-n-ruby-10'
                        : 'text-n-slate-10'
                    "
                  />
                  <span
                    class="text-xs"
                    :class="
                      row.state === 'invalid'
                        ? 'text-n-ruby-11'
                        : 'text-n-slate-11'
                    "
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
              </td>
            </tr>
          </tbody>
        </table>
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
