<script setup>
import { useI18n } from 'vue-i18n';
import Icon from '../icon/Icon.vue';
import Spinner from '../spinner/Spinner.vue';
import CopilotProgressBar from './CopilotProgressBar.vue';

// The review job updates this line in place. It counts only the current turn's conversations.
defineProps({
  progress: { type: Object, required: true },
});

const { t } = useI18n();
</script>

<template>
  <div class="flex flex-col gap-1.5 text-xs text-n-slate-11 tabular-nums">
    <div class="flex items-center gap-2 -ms-3">
      <Spinner
        v-if="!progress.finished"
        :size="16"
        class="flex-shrink-0 text-n-slate-9"
      />
      <!-- A review stopped by errors or credits finishes before it reaches every conversation in this turn. -->
      <Icon
        v-else-if="progress.done < progress.total"
        icon="i-lucide-triangle-alert"
        class="size-4 flex-shrink-0 text-n-amber-11"
      />
      <Icon
        v-else
        icon="i-lucide-check"
        class="size-4 flex-shrink-0 text-n-teal-10"
      />
      <span class="text-n-slate-12">
        {{
          progress.finished
            ? t(
                'CAPTAIN.COPILOT.REVIEW.FINISHED',
                { count: progress.done },
                progress.done
              )
            : t('CAPTAIN.COPILOT.REVIEW.RUNNING')
        }}
      </span>
      <span v-if="!progress.finished">
        {{
          t('CAPTAIN.COPILOT.REVIEW.PROGRESS', {
            done: progress.done,
            total: progress.total,
          })
        }}
      </span>
      <span class="ms-auto">
        {{ t('CAPTAIN.COPILOT.REVIEW.MATCHED', { count: progress.matched }) }}
      </span>
    </div>
    <CopilotProgressBar
      v-if="!progress.finished"
      :done="progress.done"
      :total="progress.total"
      class="ms-3"
    />
    <span v-else-if="progress.failed > 0" class="ms-3 text-n-amber-11">
      {{ t('CAPTAIN.COPILOT.REVIEW.FAILED', { count: progress.failed }) }}
    </span>
  </div>
</template>
