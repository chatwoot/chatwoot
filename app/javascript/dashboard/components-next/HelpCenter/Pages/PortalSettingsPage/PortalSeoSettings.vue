<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  activePortal: { type: Object, required: true },
  isFetching: { type: Boolean, default: false },
});

const emit = defineEmits(['updatePortalConfiguration']);

const { t } = useI18n();

const isSearchIndexingDisabled = computed(
  () => props.activePortal?.config?.disable_search_indexing || false
);

const toggleSearchIndexing = () => {
  emit('updatePortalConfiguration', {
    id: props.activePortal.id,
    slug: props.activePortal.slug,
    config: { disable_search_indexing: !isSearchIndexingDisabled.value },
  });
};
</script>

<template>
  <div class="flex flex-col w-full gap-6">
    <div class="flex flex-col gap-2">
      <h6 class="text-base font-medium text-n-slate-12">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.SEO.HEADER') }}
      </h6>
      <span class="text-sm text-n-slate-11">
        {{ t('HELP_CENTER.PORTAL_SETTINGS.SEO.DESCRIPTION') }}
      </span>
    </div>
    <div class="flex items-center justify-between w-full gap-4">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{
            t('HELP_CENTER.PORTAL_SETTINGS.SEO.SEARCH_ENGINE_VISIBILITY.LABEL')
          }}
        </label>
        <span class="text-sm text-n-slate-11">
          {{
            t(
              'HELP_CENTER.PORTAL_SETTINGS.SEO.SEARCH_ENGINE_VISIBILITY.DESCRIPTION'
            )
          }}
        </span>
      </div>
      <Switch
        :model-value="!isSearchIndexingDisabled"
        :disabled="isFetching"
        @change="toggleSearchIndexing"
      />
    </div>
  </div>
</template>
