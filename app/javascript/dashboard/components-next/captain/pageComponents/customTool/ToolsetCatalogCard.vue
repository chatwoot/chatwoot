<script setup>
import { useI18n } from 'vue-i18n';
import ToolsetIdentity from './ToolsetIdentity.vue';

defineProps({
  toolset: {
    type: Object,
    required: true,
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
    <ToolsetIdentity :toolset="toolset" />
    <p class="mb-0 text-sm text-n-slate-11 line-clamp-2">
      {{ toolset.description }}
    </p>
    <div class="flex items-center gap-2 mt-auto text-xs text-n-slate-11">
      <span>{{ toolset.category }}</span>
      <span class="rounded-full size-1 bg-n-slate-8" />
      <span>
        {{
          t('CAPTAIN.CUSTOM_TOOLS.CATALOG.TOOL_COUNT', {
            n: toolset.tool_count,
          })
        }}
      </span>
      <span class="rounded-full size-1 bg-n-slate-8" />
      <span>
        {{
          t('CAPTAIN.CUSTOM_TOOLS.CATALOG.VERSION', {
            version: toolset.version,
          })
        }}
      </span>
    </div>
  </button>
</template>
