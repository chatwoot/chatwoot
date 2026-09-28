<script setup>
import { useI18n } from 'vue-i18n';
import ToolsetIdentity from './ToolsetIdentity.vue';
import ToolsetInstallBadge from './ToolsetInstallBadge.vue';

defineProps({
  toolset: {
    type: Object,
    required: true,
  },
  installStatus: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['click']);

const { t } = useI18n();
</script>

<template>
  <button
    type="button"
    class="flex flex-col w-full h-full gap-3 p-4 text-start rounded-xl outline outline-1 outline-n-weak bg-n-solid-1 hover:bg-n-alpha-1"
    @click="emit('click')"
  >
    <div class="flex items-start w-full gap-3">
      <ToolsetIdentity :toolset="toolset" class="flex-1" />
      <ToolsetInstallBadge v-if="installStatus" :status="installStatus" />
    </div>
    <p class="mb-0 text-sm text-n-slate-11 line-clamp-2">
      {{ toolset.description }}
    </p>
    <!-- Only the category shrinks, so a long one truncates instead of wrapping the counts -->
    <div
      class="flex items-center w-full min-w-0 gap-2 mt-auto text-xs text-n-slate-11"
    >
      <span class="truncate" :title="toolset.category">
        {{ toolset.category }}
      </span>
      <span class="rounded-full size-1 shrink-0 bg-n-slate-8" />
      <span class="shrink-0 whitespace-nowrap">
        {{
          t('CAPTAIN.CUSTOM_TOOLS.CATALOG.TOOL_COUNT', {
            n: toolset.tool_count,
          })
        }}
      </span>
      <span class="rounded-full size-1 shrink-0 bg-n-slate-8" />
      <span class="shrink-0 whitespace-nowrap">
        {{
          t('CAPTAIN.CUSTOM_TOOLS.CATALOG.VERSION', {
            version: toolset.version,
          })
        }}
      </span>
    </div>
  </button>
</template>
