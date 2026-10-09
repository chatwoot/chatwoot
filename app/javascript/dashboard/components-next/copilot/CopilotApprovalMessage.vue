<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import CopilotRunsAPI from 'dashboard/api/captain/copilotRuns';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['decided']);
const { t } = useI18n();
const decision = ref(null);
const isSubmitting = ref(false);

const approval = computed(() => props.message.approval);
const status = computed(() => decision.value || approval.value.status);
const isPending = computed(() => status.value === 'pending');
const statusLabel = computed(() => {
  if (status.value === 'approved') {
    return t('CAPTAIN.COPILOT.APPROVAL.STATUS.APPROVED');
  }
  if (status.value === 'expired') {
    return t('CAPTAIN.COPILOT.APPROVAL.STATUS.EXPIRED');
  }
  return t('CAPTAIN.COPILOT.APPROVAL.STATUS.REJECTED');
});

const summary = computed(() => {
  const { action, arguments: args, count } = approval.value;
  if (action === 'add_labels') {
    return t(
      'CAPTAIN.COPILOT.APPROVAL.ACTIONS.ADD_LABELS',
      { labels: args.labels.join(', '), count },
      count
    );
  }
  return t('CAPTAIN.COPILOT.APPROVAL.ACTIONS.OTHER', { action, count }, count);
});

const decide = async choice => {
  isSubmitting.value = true;
  try {
    await CopilotRunsAPI[choice](props.message.run_id);
    decision.value = choice === 'approve' ? 'approved' : 'rejected';
    emit('decided', props.message.run_id);
  } catch (error) {
    // A change that expired or was already decided reports its current status.
    const currentStatus = error?.response?.data?.status;
    if (currentStatus) {
      decision.value = currentStatus;
      emit('decided', props.message.run_id);
    }
    useAlert(
      error?.response?.data?.error || t('CAPTAIN.COPILOT.APPROVAL.ERROR')
    );
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div
    class="flex flex-col gap-3 p-3 rounded-xl outline outline-1 outline-n-weak bg-n-alpha-1 text-n-slate-12"
  >
    <div class="flex flex-col gap-1">
      <span class="font-medium">{{ t('CAPTAIN.COPILOT.APPROVAL.TITLE') }}</span>
      <span class="break-words text-n-slate-11">{{ summary }}</span>
    </div>
    <div v-if="isPending" class="flex flex-row gap-2">
      <Button
        :label="t('CAPTAIN.COPILOT.APPROVAL.APPROVE')"
        size="sm"
        :is-loading="isSubmitting"
        @click="decide('approve')"
      />
      <Button
        :label="t('CAPTAIN.COPILOT.APPROVAL.REJECT')"
        size="sm"
        color="slate"
        variant="faded"
        :disabled="isSubmitting"
        @click="decide('reject')"
      />
    </div>
    <span v-else class="text-n-slate-11">
      {{ statusLabel }}
    </span>
  </div>
</template>
