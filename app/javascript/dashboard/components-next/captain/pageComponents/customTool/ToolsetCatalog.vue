<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { fetchToolsetCatalog } from 'dashboard/api/captain/toolsetCatalog';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ToolsetCatalogDetails from './ToolsetCatalogDetails.vue';

const emit = defineEmits(['install']);
const { t } = useI18n();
const globalConfig = useMapGetter('globalConfig/get');
const toolsets = ref([]);
const search = ref('');
const hasError = ref(false);
const detailsRef = ref(null);
const { run, isPending } = useAbortableRequest();

const filteredToolsets = computed(() => {
  const query = search.value.trim().toLowerCase();
  return toolsets.value.filter(toolset =>
    [toolset.name, toolset.description, toolset.category, toolset.owner]
      .join(' ')
      .toLowerCase()
      .includes(query)
  );
});

const loadCatalog = async () => {
  hasError.value = false;
  try {
    const baseURL = globalConfig.value.captainToolsCatalogURL.replace(
      /\/+$/,
      ''
    );
    const data = await run(signal =>
      fetchToolsetCatalog(`${baseURL}/toolsets.json`, { signal })
    );
    if (data) toolsets.value = data.toolsets;
  } catch {
    hasError.value = true;
  }
};

onMounted(loadCatalog);
</script>

<template>
  <div class="flex flex-col gap-4">
    <Input
      v-model="search"
      type="search"
      :placeholder="t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SEARCH')"
      :aria-label="t('CAPTAIN.CUSTOM_TOOLS.CATALOG.SEARCH')"
      custom-input-class="ltr:!pl-9 rtl:!pr-9"
      class="w-full max-w-xs"
    >
      <template #prefix>
        <span
          class="absolute size-4 -translate-y-1/2 i-lucide-search text-n-slate-10 top-1/2 ltr:left-3 rtl:right-3"
          aria-hidden="true"
        />
      </template>
    </Input>
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
      <p class="text-body-main text-n-slate-11">
        {{ t('CAPTAIN.CUSTOM_TOOLS.CATALOG.ERROR') }}
      </p>
      <Button
        :label="t('CAPTAIN.CUSTOM_TOOLS.CATALOG.RETRY')"
        variant="faded"
        color="slate"
        @click="loadCatalog"
      />
    </div>
    <p
      v-else-if="!filteredToolsets.length"
      class="py-10 text-body-main text-center text-n-slate-11"
    >
      {{
        search.trim()
          ? t('CAPTAIN.CUSTOM_TOOLS.CATALOG.NO_RESULTS')
          : t('CAPTAIN.CUSTOM_TOOLS.CATALOG.EMPTY')
      }}
    </p>
    <div v-else class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
      <button
        v-for="toolset in filteredToolsets"
        :key="toolset.source"
        type="button"
        class="group flex flex-col items-start gap-4 p-5 rounded-xl outline outline-1 outline-n-weak bg-n-solid-1 text-start transition-colors hover:outline-n-slate-6 focus-visible:outline-2 focus-visible:outline-n-brand"
        @click="detailsRef.open(toolset)"
      >
        <div class="flex items-center w-full gap-3">
          <div
            class="flex items-center justify-center size-11 shrink-0 rounded-lg bg-n-alpha-1"
          >
            <img
              :src="toolset.logo_url"
              alt=""
              loading="lazy"
              class="object-contain size-8 dark:hidden"
            />
            <img
              :src="toolset.logo_dark_url || toolset.logo_url"
              alt=""
              loading="lazy"
              class="hidden object-contain size-8 dark:block"
            />
          </div>
          <span class="flex-1 min-w-0 truncate text-heading-3 text-n-slate-12">
            {{ toolset.name }}
          </span>
          <span
            class="size-4 shrink-0 i-lucide-arrow-up-right text-n-slate-9 group-hover:text-n-slate-12"
            aria-hidden="true"
          />
        </div>
        <span class="text-body-main text-n-slate-11 line-clamp-2">{{
          toolset.description
        }}</span>
        <div
          class="flex items-center justify-between w-full gap-3 pt-3 mt-auto border-t border-n-weak text-label-small text-n-slate-10"
        >
          <span class="truncate">{{ toolset.category }}</span>
          <span class="shrink-0">{{
            t('CAPTAIN.CUSTOM_TOOLS.TOOLSET.TOOL_COUNT', {
              n: toolset.tool_count,
            })
          }}</span>
        </div>
      </button>
    </div>
  </div>
  <ToolsetCatalogDetails ref="detailsRef" @install="emit('install', $event)" />
</template>
