<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { fetchToolsetCatalog } from 'dashboard/api/captain/toolsetCatalog';
import MessageFormatter from 'shared/helpers/MessageFormatter';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Policy from 'dashboard/components/policy.vue';

const emit = defineEmits(['install']);
const { t } = useI18n();
const globalConfig = useMapGetter('globalConfig/get');
const panelRef = ref(null);
const selectedToolset = ref(null);
const details = ref(null);
const hasError = ref(false);
const { run, abort, isPending } = useAbortableRequest();

const formattedReadme = computed(() => {
  const formatter = new MessageFormatter(details.value.readme);
  formatter.disableImageRendering();
  return formatter.formattedMessage;
});
const catalogPageURL = computed(() => {
  const baseURL = globalConfig.value.captainToolsCatalogURL.replace(/\/+$/, '');
  return `${baseURL}/toolsets/${selectedToolset.value.source}/`;
});
const requiredFields = computed(() =>
  [...details.value.inputs, ...details.value.secrets].filter(
    field => field.required
  )
);

const loadDetails = async () => {
  details.value = null;
  hasError.value = false;
  try {
    const data = await run(signal =>
      fetchToolsetCatalog(selectedToolset.value.detail_url, { signal })
    );
    if (data) details.value = data;
  } catch {
    hasError.value = true;
  }
};

const open = toolset => {
  selectedToolset.value = toolset;
  panelRef.value.open();
  loadDetails();
};

const install = () => {
  const source = details.value.manifest_url;
  panelRef.value.close();
  emit('install', source);
};

defineExpose({ open });
</script>

<template>
  <SidePanel
    ref="panelRef"
    width="3xl"
    :title="selectedToolset?.name"
    @close="abort"
  >
    <template #header>
      <div v-if="selectedToolset" class="flex items-center min-w-0 gap-3">
        <div
          class="flex items-center justify-center size-12 shrink-0 rounded-xl bg-n-alpha-1"
        >
          <img
            :src="selectedToolset.logo_url"
            alt=""
            class="object-contain size-8 dark:hidden"
          />
          <img
            :src="selectedToolset.logo_dark_url || selectedToolset.logo_url"
            alt=""
            class="hidden object-contain size-8 dark:block"
          />
        </div>
        <div class="flex flex-col min-w-0 gap-0.5">
          <h3 class="m-0 truncate text-heading-2 text-n-slate-12">
            {{ selectedToolset.name }}
          </h3>
          <span class="truncate text-label-small text-n-slate-11">
            {{
              t('CAPTAIN.CUSTOM_TOOLS.CATALOG.PUBLISHER', {
                name: selectedToolset.owner,
              })
            }}
          </span>
        </div>
      </div>
    </template>
    <div v-if="isPending" class="flex justify-center py-10" role="status">
      <Spinner />
      <span class="sr-only">{{
        t('CAPTAIN.CUSTOM_TOOLS.CATALOG.LOADING')
      }}</span>
    </div>
    <div
      v-else-if="hasError"
      class="flex flex-col items-center gap-4 py-10"
      role="alert"
    >
      <p class="m-0 text-body-main text-n-slate-11">
        {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.DETAIL_ERROR') }}
      </p>
      <Button
        :label="t('CAPTAIN.CUSTOM_TOOLS.CATALOG.RETRY')"
        variant="faded"
        color="slate"
        @click="loadDetails"
      />
    </div>
    <div v-else-if="details" class="flex flex-col gap-8">
      <div class="flex flex-col gap-3">
        <p class="m-0 text-body-para text-n-slate-11">
          {{ details.description }}
        </p>
        <div class="flex flex-wrap items-center gap-2">
          <span
            class="px-2 py-0.5 rounded-md bg-n-alpha-2 text-label-small text-n-slate-11"
          >
            {{ selectedToolset.category }}
          </span>
          <span
            class="px-2 py-0.5 rounded-md bg-n-alpha-2 text-label-small text-n-slate-11"
          >
            {{
              t('CAPTAIN.CUSTOM_TOOLS.CATALOG.VERSION', {
                version: details.version,
              })
            }}
          </span>
        </div>
      </div>
      <section class="flex flex-col gap-1">
        <div class="flex items-baseline justify-between gap-3 pb-2">
          <h4 class="m-0 text-heading-3 text-n-slate-12">
            {{ t('CAPTAIN.CUSTOM_TOOLS.IMPORT.TOOLS_LABEL') }}
          </h4>
          <span class="text-label-small text-n-slate-10">
            {{
              t('CAPTAIN.CUSTOM_TOOLS.TOOLSET.TOOL_COUNT', {
                n: details.tools.length,
              })
            }}
          </span>
        </div>
        <div class="border-t divide-y divide-n-weak border-n-weak">
          <details v-for="tool in details.tools" :key="tool.id" class="group">
            <summary
              class="flex items-center gap-2.5 py-2.5 cursor-pointer list-none rounded-md focus-visible:outline-n-brand [&::-webkit-details-marker]:hidden"
            >
              <span
                class="px-1.5 py-0.5 font-mono text-xs uppercase rounded bg-n-alpha-2 text-n-slate-11"
              >
                {{ tool.method }}
              </span>
              <span
                class="flex-1 min-w-0 truncate text-heading-3 text-n-slate-12"
              >
                {{ tool.title }}
              </span>
              <span
                class="transition-transform size-4 shrink-0 i-lucide-chevron-down text-n-slate-10 group-open:rotate-180"
                aria-hidden="true"
              />
            </summary>
            <div class="flex flex-col gap-1 pb-3">
              <p class="m-0 text-body-main text-n-slate-11">
                {{ tool.description }}
              </p>
              <span class="font-mono text-xs break-all text-n-slate-10">
                {{ tool.endpoint }}
              </span>
            </div>
          </details>
        </div>
      </section>
      <section
        v-if="requiredFields.length"
        class="flex flex-col gap-3 p-4 rounded-xl outline outline-1 outline-n-weak"
      >
        <h4 class="m-0 text-heading-3 text-n-slate-12">
          {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.REQUIRED_CONFIGURATION') }}
        </h4>
        <ul class="flex flex-col gap-2 m-0 list-none">
          <li
            v-for="field in requiredFields"
            :key="field.id"
            class="flex items-center gap-2 text-body-main text-n-slate-11"
          >
            <span
              class="size-4 shrink-0 i-lucide-key-round text-n-slate-10"
              aria-hidden="true"
            />
            {{ field.label }}
          </li>
        </ul>
      </section>
      <div
        v-if="details.readme"
        v-dompurify-html="formattedReadme"
        class="max-w-none break-words prose prose-sm text-n-slate-11 prose-headings:text-n-slate-12 prose-headings:font-medium prose-headings:tracking-normal prose-headings:text-sm prose-headings:mt-6 prose-headings:mb-2 prose-p:my-2 prose-li:my-0.5 prose-a:text-n-blue-11 prose-strong:text-n-slate-12 prose-strong:font-medium prose-code:text-n-slate-11 prose-code:font-normal prose-code:before:content-none prose-code:after:content-none prose-code:bg-n-alpha-2 prose-code:rounded prose-code:px-1 prose-pre:bg-n-alpha-2 prose-pre:text-n-slate-11 prose-img:hidden [&>:first-child]:mt-0 [&>:last-child]:mb-0"
      />
    </div>
    <template #footer>
      <div class="flex items-center justify-between gap-4">
        <a
          :href="catalogPageURL"
          target="_blank"
          rel="noopener noreferrer"
          class="flex items-center gap-1.5 text-body-main text-n-slate-11 hover:text-n-slate-12"
        >
          {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.VIEW_DETAILS') }}
          <span class="size-4 i-lucide-arrow-up-right" aria-hidden="true" />
        </a>
        <Policy :permissions="['administrator']">
          <Button
            :label="t('CAPTAIN.CUSTOM_TOOLS.CATALOG.INSTALL')"
            :disabled="!details"
            class="ms-auto"
            @click="install"
          />
        </Policy>
      </div>
    </template>
  </SidePanel>
</template>
