<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import CopilotRunsAPI from 'dashboard/api/captain/copilotRuns';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();
const isSubmitting = ref(false);

const approval = computed(() => props.message.approval);
const status = computed(() => approval.value.status);
const isAwaitingApproval = computed(() => status.value === 'awaiting_approval');
const statusLabel = computed(() => {
  if (status.value === 'approved') {
    return t('CAPTAIN.COPILOT.APPROVAL.STATUS.APPROVED');
  }
  if (status.value === 'expired') {
    return t('CAPTAIN.COPILOT.APPROVAL.STATUS.EXPIRED');
  }
  return t('CAPTAIN.COPILOT.APPROVAL.STATUS.REJECTED');
});

// The card links the first few records the change will touch; the count covers the rest.
const targets = computed(() => approval.value.targets || []);
const hiddenTargetCount = computed(
  () => approval.value.count - targets.value.length
);

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
    const { data } = await CopilotRunsAPI[choice](props.message.run_id);
    store.dispatch('copilotMessages/upsert', data);
  } catch (error) {
    // A change that expired or was already decided returns its saved card.
    const card = error?.response?.data?.message;
    if (card) store.dispatch('copilotMessages/upsert', card);
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
    <div v-if="targets.length" class="flex flex-wrap gap-x-2 gap-y-1">
      <router-link
        v-for="target in targets"
        :key="target.url"
        :to="target.url"
        class="text-n-blue-11 hover:underline"
      >
        {{ target.label }}
      </router-link>
      <span v-if="hiddenTargetCount > 0" class="text-n-slate-11">
        {{
          t('CAPTAIN.COPILOT.APPROVAL.MORE_TARGETS', {
            count: hiddenTargetCount,
          })
        }}
      </span>
    </div>
    <div v-if="isAwaitingApproval" class="flex flex-row gap-2">
      <Button
        :label="t('CAPTAIN.COPILOT.APPROVAL.APPROVE')"
        size="sm"
        :is-loading="isSubmitting"
        :disabled="isSubmitting"
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
