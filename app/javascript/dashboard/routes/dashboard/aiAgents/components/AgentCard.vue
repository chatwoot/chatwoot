<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  agent: {
    type: Object,
    required: true,
  },
});

defineEmits(['click', 'edit', 'delete']);

const { t } = useI18n();

const agentTypeLabel = computed(() => {
  const typeMap = {
    rag: t('AI_AGENTS.TYPES.RAG'),
    tool_calling: t('AI_AGENTS.TYPES.TOOL_CALLING'),
    voice: t('AI_AGENTS.TYPES.VOICE'),
    hybrid: t('AI_AGENTS.TYPES.HYBRID'),
  };
  return typeMap[props.agent.agent_type] || props.agent.agent_type;
});

const statusColor = computed(() => {
  const colorMap = {
    active: 'bg-n-teal-9',
    paused: 'bg-n-amber-9',
    archived: 'bg-n-slate-8',
  };
  return colorMap[props.agent.status] || 'bg-n-slate-8';
});

const statusLabel = computed(() => {
  const statusMap = {
    active: t('AI_AGENTS.STATUS.ACTIVE'),
    paused: t('AI_AGENTS.STATUS.PAUSED'),
    archived: t('AI_AGENTS.STATUS.ARCHIVED'),
  };
  return statusMap[props.agent.status] || props.agent.status;
});
</script>

<template>
  <CardLayout
    class="cursor-pointer hover:outline-n-blue-7 transition-all"
    @click="$emit('click')"
  >
    <div class="flex items-start justify-between w-full">
      <div class="flex items-center gap-3 min-w-0">
        <div
          class="flex items-center justify-center size-10 rounded-lg bg-n-alpha-2 text-n-slate-11 shrink-0"
        >
          <div class="i-lucide-bot size-5" />
        </div>
        <div class="min-w-0">
          <h3 class="text-sm font-medium text-n-slate-12 truncate">
            {{ agent.name }}
          </h3>
          <p class="text-xs text-n-slate-11 truncate mt-0.5">
            {{
              agent.description || t('AI_AGENTS.FORM.DESCRIPTION.PLACEHOLDER')
            }}
          </p>
        </div>
      </div>
      <div class="flex items-center gap-1 shrink-0">
        <Button
          icon="i-lucide-pencil"
          variant="ghost"
          color="slate"
          size="xs"
          @click.stop="$emit('edit')"
        />
        <Button
          icon="i-lucide-trash-2"
          variant="ghost"
          color="ruby"
          size="xs"
          @click.stop="$emit('delete')"
        />
      </div>
    </div>

    <div class="flex items-center gap-3 mt-3">
      <span
        class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded text-xs font-medium text-n-slate-12 bg-n-alpha-2"
      >
        {{ agentTypeLabel }}
      </span>
      <span class="inline-flex items-center gap-1.5 text-xs text-n-slate-11">
        <span class="size-1.5 rounded-full" :class="statusColor" />
        {{ statusLabel }}
      </span>
    </div>

    <div
      v-if="
        agent.inboxes_count || agent.knowledge_bases_count || agent.tools_count
      "
      class="flex items-center gap-3 mt-2 text-xs text-n-slate-11"
    >
      <span v-if="agent.inboxes_count" class="flex items-center gap-1">
        <div class="i-lucide-inbox size-3.5" />
        {{ t('AI_AGENTS.LIST.INBOXES_COUNT', { count: agent.inboxes_count }) }}
      </span>
      <span v-if="agent.knowledge_bases_count" class="flex items-center gap-1">
        <div class="i-lucide-database size-3.5" />
        {{
          t('AI_AGENTS.LIST.KB_COUNT', { count: agent.knowledge_bases_count })
        }}
      </span>
      <span v-if="agent.tools_count" class="flex items-center gap-1">
        <div class="i-lucide-wrench size-3.5" />
        {{ t('AI_AGENTS.LIST.TOOLS_COUNT', { count: agent.tools_count }) }}
      </span>
    </div>
  </CardLayout>
</template>
