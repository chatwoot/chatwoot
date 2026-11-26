<script setup>
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  suggestions: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['keep', 'keepAll', 'remove']);

const { t } = useI18n();
</script>

<template>
  <div class="flex flex-col rounded-lg border border-n-weak bg-n-alpha-1">
    <div class="flex items-start justify-between gap-3 px-3 pt-3 pb-2">
      <div class="flex items-start gap-2 min-w-0">
        <Icon
          icon="i-lucide-sparkles"
          class="flex-shrink-0 mt-0.5 size-4 text-n-iris-10"
        />
        <div class="flex flex-col min-w-0">
          <span class="text-sm font-medium text-n-slate-12">
            {{
              t(
                'CAPTAIN.ASSISTANTS.SCENARIOS.TOOL_SUGGESTIONS.TITLE',
                suggestions.length
              )
            }}
          </span>
          <span class="text-xs text-n-slate-11">
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.TOOL_SUGGESTIONS.DESCRIPTION') }}
          </span>
        </div>
      </div>
      <Button
        :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.TOOL_SUGGESTIONS.KEEP_ALL')"
        xs
        faded
        blue
        class="flex-shrink-0"
        @click="emit('keepAll')"
      />
    </div>
    <ul class="flex flex-col mb-0 list-none ps-0 border-t border-n-weak">
      <li
        v-for="suggestion in suggestions"
        :key="suggestion.toolId"
        class="flex items-center justify-between gap-3 px-3 py-2 border-b border-n-weak last:border-b-0"
      >
        <div class="flex flex-col min-w-0 gap-0.5">
          <span class="text-sm font-medium text-n-iris-11 break-words">
            {{ `@${suggestion.toolTitle}` }}
          </span>
          <span class="text-xs text-n-slate-11 break-words">
            {{ suggestion.phrase }}
          </span>
        </div>
        <div class="flex items-center flex-shrink-0 gap-1">
          <Button
            v-tooltip.top="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.TOOL_SUGGESTIONS.KEEP')
            "
            icon="i-lucide-check"
            :aria-label="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.TOOL_SUGGESTIONS.KEEP')
            "
            xs
            ghost
            teal
            @click="emit('keep', suggestion.toolId)"
          />
          <Button
            v-tooltip.top="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.TOOL_SUGGESTIONS.REMOVE')
            "
            icon="i-lucide-x"
            :aria-label="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.TOOL_SUGGESTIONS.REMOVE')
            "
            xs
            ghost
            ruby
            @click="emit('remove', suggestion.toolId)"
          />
        </div>
      </li>
    </ul>
  </div>
</template>
