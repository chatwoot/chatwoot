<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatDistanceToNow } from 'date-fns';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inboxName: {
    type: String,
    default: '',
  },
  templates: {
    type: Array,
    default: () => [],
  },
  lastSyncedAt: {
    type: String,
    default: '',
  },
  isSyncing: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['sync']);

const { t } = useI18n();

const lastSyncedLabel = computed(() => {
  if (!props.lastSyncedAt) return '';
  return t('CAMPAIGN.TEMPLATES.SYNCED.LAST_SYNCED', {
    time: formatDistanceToNow(new Date(props.lastSyncedAt), {
      addSuffix: true,
    }),
  });
});
</script>

<template>
  <section class="flex flex-col gap-3">
    <div class="flex items-center justify-between gap-3">
      <span class="text-sm font-medium text-n-slate-12">
        {{ inboxName }}
      </span>
      <div class="flex items-center gap-3">
        <span v-if="lastSyncedLabel" class="text-xs text-n-slate-11">
          {{ lastSyncedLabel }}
        </span>
        <Button
          variant="faded"
          color="slate"
          size="sm"
          icon="i-lucide-refresh-cw"
          :label="t('CAMPAIGN.TEMPLATES.SYNCED.SYNC_BUTTON')"
          :is-loading="isSyncing"
          :disabled="isSyncing"
          @click="emit('sync')"
        />
      </div>
    </div>

    <p v-if="templates.length === 0" class="mb-0 text-sm text-n-slate-11">
      {{ t('CAMPAIGN.TEMPLATES.SYNCED.NO_TEMPLATES') }}
    </p>
    <CardLayout v-for="template in templates" :key="template.id">
      <div class="flex flex-wrap items-center gap-2">
        <span class="text-base font-medium text-n-slate-12">
          {{ template.name }}
        </span>
        <span
          v-if="template.language"
          class="px-2 py-0.5 text-xs rounded-md bg-n-alpha-2 text-n-slate-11"
        >
          {{ template.language }}
        </span>
        <span
          v-if="template.category"
          class="px-2 py-0.5 text-xs rounded-md bg-n-alpha-2 text-n-slate-11"
        >
          {{ template.category }}
        </span>
      </div>
      <p class="mb-0 text-sm text-n-slate-11 line-clamp-3">
        {{ template.body }}
      </p>
    </CardLayout>
  </section>
</template>
