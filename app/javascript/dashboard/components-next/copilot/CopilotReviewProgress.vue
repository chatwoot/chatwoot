<script setup>
import { useI18n } from 'vue-i18n';
import CopilotProgressBar from './CopilotProgressBar.vue';

// The review job updates this card in place. It counts only the current turn's conversations.
defineProps({
  progress: { type: Object, required: true },
});

const { t } = useI18n();
</script>

<template>
  <div
    class="flex flex-col gap-2 p-3 rounded-xl outline outline-1 outline-n-weak bg-n-alpha-1 text-n-slate-12"
  >
    <template v-if="progress.finished">
      <span class="font-medium">
        {{
          t(
            'CAPTAIN.COPILOT.REVIEW.FINISHED',
            { count: progress.done },
            progress.done
          )
        }}
      </span>
      <div class="flex flex-col">
        <span class="text-n-slate-11">
          {{ t('CAPTAIN.COPILOT.REVIEW.MATCHED', { count: progress.matched }) }}
        </span>
        <span v-if="progress.failed > 0" class="text-n-amber-11">
          {{ t('CAPTAIN.COPILOT.REVIEW.FAILED', { count: progress.failed }) }}
        </span>
      </div>
    </template>
    <template v-else>
      <span class="font-medium">{{ t('CAPTAIN.COPILOT.REVIEW.RUNNING') }}</span>
      <CopilotProgressBar :done="progress.done" :total="progress.total" />
      <div class="flex justify-between gap-2 text-n-slate-11 tabular-nums">
        <span>
          {{
            t('CAPTAIN.COPILOT.REVIEW.PROGRESS', {
              done: progress.done,
              total: progress.total,
            })
          }}
        </span>
        <span>
          {{ t('CAPTAIN.COPILOT.REVIEW.MATCHED', { count: progress.matched }) }}
        </span>
      </div>
    </template>
  </div>
</template>
