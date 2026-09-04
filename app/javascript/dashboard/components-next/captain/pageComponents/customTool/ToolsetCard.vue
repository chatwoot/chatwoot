<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import CustomToolCard from './CustomToolCard.vue';

const props = defineProps({
  tools: {
    type: Array,
    required: true,
  },
  pendingToggleIds: {
    type: Set,
    default: () => new Set(),
  },
});

const emit = defineEmits(['action', 'toggle']);

const { t } = useI18n();
const isExpanded = ref(false);

const metadata = computed(() => props.tools[0].source_metadata);
const sourceLabel = computed(() => {
  if (metadata.value.type === 'github') {
    const path = metadata.value.path.replace(/\/toolset\.ya?ml$/, '');
    return [metadata.value.repository, path].filter(Boolean).join('/');
  }

  return metadata.value.filename;
});

const toolCountLabel = computed(() =>
  t('CAPTAIN.CUSTOM_TOOLS.TOOLSET.TOOL_COUNT', {
    n: props.tools.length,
  })
);

const sourceDetails = computed(() =>
  t('CAPTAIN.CUSTOM_TOOLS.TOOLSET.SOURCE_DETAILS', {
    source: sourceLabel.value,
    version: metadata.value.toolset_version,
  })
);
</script>

<template>
  <CardLayout class="overflow-hidden">
    <button
      type="button"
      class="flex flex-col w-full gap-3 p-0 text-start"
      :aria-expanded="isExpanded"
      @click="isExpanded = !isExpanded"
    >
      <div class="flex items-center justify-between w-full gap-4">
        <span class="text-base font-medium text-n-slate-12 line-clamp-1">
          {{ metadata.toolset_name }}
        </span>
        <div class="flex items-center gap-3 shrink-0">
          <span class="text-sm text-n-slate-11">{{ toolCountLabel }}</span>
          <i
            class="size-5 text-n-slate-10 transition-transform i-lucide-chevron-down"
            :class="{ 'rotate-180': isExpanded }"
          />
        </div>
      </div>
      <span class="text-sm truncate text-n-slate-11">
        {{ sourceDetails }}
      </span>
    </button>

    <template #after>
      <div
        v-if="isExpanded"
        class="flex flex-col gap-2 p-3 overflow-y-auto border-y max-h-96 border-n-weak bg-n-alpha-1"
      >
        <CustomToolCard
          v-for="tool in tools"
          :id="tool.id"
          :key="tool.id"
          :title="tool.title"
          :description="tool.description"
          :auth-type="tool.auth_type"
          :enabled="tool.enabled"
          :is-updating="pendingToggleIds.has(tool.id)"
          :created-at="tool.created_at"
          :updated-at="tool.updated_at"
          :source-metadata="tool.source_metadata"
          :show-source="false"
          @action="emit('action', $event)"
          @toggle="emit('toggle', $event)"
        />
      </div>
    </template>
  </CardLayout>
</template>
