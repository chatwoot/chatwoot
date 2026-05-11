<script setup>
import { computed } from 'vue';
import { format } from 'date-fns';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  issue: {
    type: Object,
    required: true,
  },
});

const createdAt = computed(() => {
  if (!props.issue.created_at) return '';

  return format(new Date(props.issue.created_at), 'MMM d, yyyy');
});

const createdBy = computed(() => props.issue.metadata?.created_by_name);
</script>

<template>
  <div class="flex flex-col gap-2">
    <a
      :href="issue.url"
      target="_blank"
      rel="noopener noreferrer"
      class="flex items-start gap-1.5 text-sm font-medium text-n-slate-12 hover:underline"
    >
      <span class="min-w-0 break-words">
        {{ issue.title }}
      </span>
      <Icon icon="i-lucide-external-link" class="mt-0.5 size-3 shrink-0" />
    </a>

    <div class="flex flex-col gap-1 text-xs text-n-slate-11">
      <span v-if="createdAt">
        {{ $t('INTEGRATION_SETTINGS.NOTION.ISSUE.CREATED_AT', { createdAt }) }}
      </span>
      <span v-if="createdBy">
        {{
          $t('INTEGRATION_SETTINGS.NOTION.ISSUE.CREATED_BY', {
            name: createdBy,
          })
        }}
      </span>
    </div>
  </div>
</template>
