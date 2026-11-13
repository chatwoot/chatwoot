<script setup>
import { ref, watch } from 'vue';
import Papa from 'papaparse';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  file: { type: File, required: true },
});

const PREVIEW_ROWS = 5;
const headers = ref([]);
const rows = ref([]);
const isLoading = ref(false);
const hasError = ref(false);

watch(
  () => props.file,
  (file, _, onCleanup) => {
    let cancelled = false;
    onCleanup(() => {
      cancelled = true;
    });
    headers.value = [];
    rows.value = [];
    hasError.value = false;
    isLoading.value = true;

    // Decode without byte chunks to preserve UTF-8 characters at chunk boundaries.
    Papa.parse(file, {
      delimiter: ',',
      skipEmptyLines: true,
      preview: PREVIEW_ROWS + 1,
      worker: true,
      complete: ({ data, errors }) => {
        if (cancelled) return;

        headers.value = data[0] || [];
        rows.value = data.slice(1, PREVIEW_ROWS + 1);
        hasError.value =
          errors.length > 0 ||
          rows.value.some(row => row.length > headers.value.length);
        isLoading.value = false;
      },
      error: () => {
        if (cancelled) return;

        hasError.value = true;
        isLoading.value = false;
      },
    });
  },
  { immediate: true }
);
</script>

<template>
  <section class="flex min-w-0 flex-col gap-2">
    <h4 class="text-heading-3 text-n-slate-12">
      {{ $t('DATA_IMPORTS.CSV.PREVIEW_TITLE') }}
    </h4>
    <div
      v-if="isLoading"
      role="status"
      class="flex items-center gap-2 py-4 text-body-main text-n-slate-11"
    >
      <Spinner :size="16" />
      {{ $t('DATA_IMPORTS.CSV.PREVIEW_LOADING') }}
    </div>
    <Banner v-else-if="hasError" color="amber">
      {{ $t('DATA_IMPORTS.CSV.PREVIEW_ERROR') }}
    </Banner>
    <p v-else-if="!rows.length" class="text-body-main text-n-slate-11">
      {{ $t('DATA_IMPORTS.CSV.PREVIEW_EMPTY') }}
    </p>
    <template v-else>
      <div
        tabindex="0"
        role="region"
        :aria-label="$t('DATA_IMPORTS.CSV.PREVIEW_TITLE')"
        class="max-h-64 overflow-auto rounded-xl border border-n-weak focus-visible:outline focus-visible:outline-n-brand"
      >
        <table class="min-w-full divide-y divide-n-weak text-start">
          <caption class="sr-only">
            {{
              $t('DATA_IMPORTS.CSV.PREVIEW_TITLE')
            }}
          </caption>
          <thead class="sticky top-0 bg-n-solid-2">
            <tr>
              <th
                v-for="(header, index) in headers"
                :key="index"
                scope="col"
                class="px-3 py-2 text-start text-label-small text-n-slate-12"
              >
                <span class="block max-w-64 truncate" :title="header">
                  {{ header }}
                </span>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-n-weak">
            <tr v-for="(row, rowIndex) in rows" :key="rowIndex">
              <td
                v-for="(header, columnIndex) in headers"
                :key="columnIndex"
                class="px-3 py-2 align-top text-label-small text-n-slate-11"
              >
                <span
                  class="line-clamp-2 min-w-32 max-w-64 whitespace-pre-wrap break-words"
                  :title="row[columnIndex]"
                >
                  {{ row[columnIndex] }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p class="text-label-small text-n-slate-11">
        {{
          $t('DATA_IMPORTS.CSV.PREVIEW_DESCRIPTION', { count: PREVIEW_ROWS })
        }}
      </p>
    </template>
  </section>
</template>
