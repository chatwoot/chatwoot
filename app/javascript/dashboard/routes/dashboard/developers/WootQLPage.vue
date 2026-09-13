<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useClipboard } from '@vueuse/core';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import api from 'dashboard/api/captain/wootql';
import Button from 'dashboard/components-next/button/Button.vue';

const MAX_SOURCE_LENGTH = 32768;
const PAGE_SIZE = 200;
const EXAMPLES = [
  {
    label: 'WOOTQL.EXAMPLE_OPEN',
    source:
      'conversations\n| where status = "open"\n| project id, display_id, status, inbox.name as inbox_name\n| sort id desc\n| take 20',
  },
  {
    label: 'WOOTQL.EXAMPLE_CONTACTS',
    source:
      'conversations\n| summarize count() as conversation_count by contact_id\n| sort conversation_count desc, contact_id asc\n| take 5\n| join contacts as contact on contact_id = contact.id\n| project contact_id, contact.name as name, contact.email as email, conversation_count',
  },
  {
    label: 'WOOTQL.EXAMPLE_REFUND',
    source:
      'conversations\n| where labels contains "refund"\n| project id, display_id, status, labels, contact.name as customer, inbox.name as inbox_name\n| sort id desc\n| take 20',
  },
  {
    label: 'WOOTQL.EXAMPLE_INBOXES',
    source:
      'conversations\n| where created_at >= now() - 30d\n| summarize count() by inbox.id, inbox.name\n| sort count desc',
  },
];

const { t } = useI18n();
const route = useRoute();
const { run, abort, isPending } = useAbortableRequest();
const { run: fetchResources } = useAbortableRequest();
const { copy, copied } = useClipboard();
const resources = ref({});
const resourcesError = ref('');
const source = ref(EXAMPLES[0].source);
const result = ref(null);
const error = ref('');
const executedSource = ref('');
const offset = ref(0);
const unchanged = computed(() => source.value === executedSource.value);

const displayValue = value => {
  if (value === null) return 'null';
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value);
};

async function execute(nextOffset = 0) {
  error.value = '';
  result.value = null;
  const submitted = source.value;
  try {
    const response = await run(signal =>
      api.run(submitted, nextOffset, { signal })
    );
    if (!response) return;
    result.value = response.data;
    executedSource.value = submitted;
    offset.value = nextOffset;
  } catch (exception) {
    error.value = exception.response?.data?.error || t('WOOTQL.ERROR');
  }
}

async function loadResources() {
  resources.value = {};
  resourcesError.value = '';
  try {
    const response = await fetchResources(signal => api.resources({ signal }));
    if (response) resources.value = response.data.resources;
  } catch (exception) {
    resourcesError.value =
      exception.response?.data?.error || t('WOOTQL.RESOURCES_ERROR');
  }
}

function reset() {
  abort();
  result.value = null;
  error.value = '';
  executedSource.value = '';
  offset.value = 0;
}

function useExample(example) {
  reset();
  source.value = example.source;
}

function onKeydown(event) {
  if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
    event.preventDefault();
    if (!isPending.value && source.value.trim()) execute();
  }
}

watch(
  () => route.params.accountId,
  () => {
    reset();
    loadResources();
  },
  { immediate: true }
);
</script>

<template>
  <main class="flex-1 min-w-0 overflow-y-auto bg-n-background p-6">
    <div class="max-w-6xl mx-auto space-y-6">
      <header class="flex items-start justify-between gap-4">
        <div class="space-y-1">
          <h1 class="m-0 text-heading-1 text-n-slate-12">
            {{ t('WOOTQL.TITLE') }}
          </h1>
          <p class="m-0 text-sm text-n-slate-11">{{ t('WOOTQL.SUBTITLE') }}</p>
        </div>
        <span class="rounded bg-n-alpha-2 px-2 py-1 text-xs text-n-slate-11">
          {{ t('WOOTQL.DEVELOPMENT_ONLY') }}
        </span>
      </header>

      <details class="border-b border-n-weak pb-4 text-sm">
        <summary class="cursor-pointer font-medium text-n-slate-12">
          {{ t('WOOTQL.RESOURCES') }}
        </summary>
        <p v-if="resourcesError" role="alert" class="mt-3 text-n-ruby-11">
          {{ resourcesError }}
        </p>
        <div class="mt-4 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          <div
            v-for="(definition, name) in resources"
            :key="name"
            class="space-y-2"
          >
            <Button
              :label="name"
              variant="link"
              size="sm"
              @click="useExample({ source: `${name}\n| take 5` })"
            />
            <p class="m-0 break-words font-mono text-xs text-n-slate-11">
              {{ definition.fields.join(', ') }}
            </p>
            <p
              v-if="Object.keys(definition.relations).length"
              class="m-0 text-xs text-n-slate-10"
            >
              {{
                t('WOOTQL.RELATIONSHIPS', {
                  names: Object.keys(definition.relations).join(', '),
                })
              }}
            </p>
          </div>
        </div>
      </details>

      <section class="space-y-3">
        <div class="flex flex-wrap items-center gap-2">
          <label
            for="wootql-source"
            class="font-medium text-sm text-n-slate-12"
          >
            {{ t('WOOTQL.EDITOR') }}
          </label>
          <span class="ms-auto text-xs text-n-slate-10">{{
            t('WOOTQL.EXAMPLES')
          }}</span>
          <Button
            v-for="example in EXAMPLES"
            :key="example.label"
            :label="t(example.label)"
            size="xs"
            variant="ghost"
            color="slate"
            @click="useExample(example)"
          />
        </div>
        <textarea
          id="wootql-source"
          v-model="source"
          :maxlength="MAX_SOURCE_LENGTH"
          :aria-label="t('WOOTQL.EDITOR')"
          spellcheck="false"
          class="!m-0 !min-h-56 !w-full !rounded-lg !border-n-weak !bg-n-alpha-1 !p-4 !font-mono !text-sm !text-n-slate-12 focus:!border-n-brand"
          @keydown="onKeydown"
        />
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div class="space-y-1 text-xs text-n-slate-10">
            <p class="m-0 font-mono">{{ t('WOOTQL.SYNTAX') }}</p>
            <p class="m-0">{{ t('WOOTQL.HINT') }}</p>
          </div>
          <Button
            :label="t('WOOTQL.RUN')"
            icon="i-lucide-play"
            :is-loading="isPending"
            :disabled="isPending || !source.trim()"
            @click="execute()"
          />
        </div>
      </section>

      <p
        v-if="error"
        role="alert"
        class="m-0 rounded-lg bg-n-ruby-2 p-4 text-sm text-n-ruby-11"
      >
        {{ error }}
      </p>

      <section class="space-y-3" aria-live="polite">
        <div class="flex items-center justify-between gap-3">
          <h2 class="m-0 text-heading-3 text-n-slate-12">
            {{ t('WOOTQL.RESULTS') }}
          </h2>
          <span v-if="result" class="text-xs text-n-slate-10">
            {{
              t('WOOTQL.RESULT_COUNT', {
                count: result.items.length,
                duration: result.duration_ms,
              })
            }}
          </span>
        </div>
        <div
          v-if="result?.items.length"
          class="overflow-x-auto rounded-lg border border-n-weak"
        >
          <table class="w-full text-start text-sm">
            <thead class="bg-n-alpha-2">
              <tr>
                <th
                  v-for="column in result.columns"
                  :key="column"
                  class="whitespace-nowrap px-4 py-3 text-start font-mono font-medium text-n-slate-11"
                >
                  {{ column }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(row, index) in result.items"
                :key="index"
                class="border-t border-n-weak"
              >
                <td
                  v-for="column in result.columns"
                  :key="column"
                  class="max-w-lg break-words px-4 py-3 align-top text-n-slate-12"
                >
                  {{ displayValue(row[column]) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <p
          v-else
          class="m-0 rounded-lg border border-dashed border-n-weak p-8 text-center text-sm text-n-slate-10"
        >
          {{ t(result ? 'WOOTQL.EMPTY' : 'WOOTQL.NOT_RUN') }}
        </p>
        <div v-if="result" class="flex items-center justify-end gap-2">
          <span class="me-auto text-xs text-n-slate-10">{{
            t('WOOTQL.PAGE', { offset })
          }}</span>
          <Button
            :label="t('WOOTQL.PREVIOUS')"
            variant="ghost"
            color="slate"
            :disabled="!unchanged || offset === 0 || isPending"
            @click="execute(Math.max(0, offset - PAGE_SIZE))"
          />
          <Button
            :label="t('WOOTQL.NEXT')"
            variant="ghost"
            color="slate"
            :disabled="!unchanged || result.next_offset === false || isPending"
            @click="execute(result.next_offset)"
          />
        </div>
      </section>

      <section v-if="result" class="space-y-3">
        <div class="flex items-center justify-between">
          <h2 class="m-0 text-heading-3 text-n-slate-12">
            {{ t('WOOTQL.SQL') }}
          </h2>
          <Button
            :label="t(copied ? 'WOOTQL.COPIED' : 'WOOTQL.COPY_SQL')"
            icon="i-lucide-copy"
            variant="ghost"
            color="slate"
            size="sm"
            @click="copy(result.sql)"
          />
        </div>
        <pre
          class="m-0 max-h-80 overflow-auto whitespace-pre-wrap break-words rounded-lg border border-n-weak bg-n-alpha-1 p-4 font-mono text-xs text-n-slate-11"
          >{{ result.sql }}</pre
        >
        <details v-if="result.binds.length" class="text-sm text-n-slate-11">
          <summary class="cursor-pointer py-2 font-medium">
            {{ t('WOOTQL.PARAMETERS') }}
          </summary>
          <dl
            class="m-0 grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 rounded-lg bg-n-alpha-1 p-4 font-mono text-xs"
          >
            <template v-for="(value, index) in result.binds" :key="index">
              <dt>{{ `$${index + 1}` }}</dt>
              <dd class="m-0 break-all">{{ displayValue(value) }}</dd>
            </template>
          </dl>
        </details>
      </section>
    </div>
  </main>
</template>
