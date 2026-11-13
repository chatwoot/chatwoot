<script setup>
import { computed, ref, watch } from 'vue';
import { useNow } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { formatDuration } from 'shared/helpers/timeHelper';
import CopilotRunsAPI from 'dashboard/api/captain/copilotRuns';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CopilotApprovalSummary from './CopilotApprovalSummary.vue';
import { APPROVAL_ACTION, APPROVAL_STATUS } from './constants';
import CopilotProgressBar from './CopilotProgressBar.vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
});

const NOTE_ACTIONS = [
  APPROVAL_ACTION.ADD_PRIVATE_NOTE,
  APPROVAL_ACTION.ADD_CONTACT_NOTE,
];

const store = useStore();
const { t } = useI18n();
const isSubmitting = ref(false);

const approval = computed(() => props.message.approval);
const status = computed(() => approval.value.status);
const isAwaitingApproval = computed(
  () => status.value === APPROVAL_STATUS.AWAITING
);
const isDeclined = computed(() =>
  [APPROVAL_STATUS.REJECTED, APPROVAL_STATUS.EXPIRED].includes(status.value)
);
// The change job writes its progress after each batch, so a just approved change starts at 0.
const progress = computed(
  () => approval.value.progress || { done: 0, total: approval.value.count }
);
const isApplying = computed(
  () => status.value === APPROVAL_STATUS.APPROVED && !progress.value.finished
);

const isReply = computed(
  () => approval.value.action === APPROVAL_ACTION.SEND_REPLY
);
const isNote = computed(() => NOTE_ACTIONS.includes(approval.value.action));
const approveLabel = computed(() => {
  if (isReply.value) return t('CAPTAIN.COPILOT.APPROVAL.CONFIRM.SEND_REPLY');
  if (isNote.value) return t('CAPTAIN.COPILOT.APPROVAL.CONFIRM.ADD_NOTE');
  return t('CAPTAIN.COPILOT.APPROVAL.APPROVE');
});
const bubbleClass = computed(() => {
  if (isDeclined.value) return 'bg-n-alpha-2 text-n-slate-11';
  return isReply.value
    ? 'bg-n-solid-blue text-n-slate-12'
    : 'bg-n-solid-amber text-n-amber-12';
});

// The approval expires on the server. The countdown only tells the agent how long they have.
const { now, pause } = useNow({ interval: 1000, controls: true });
watch(
  isAwaitingApproval,
  awaiting => {
    if (!awaiting) pause();
  },
  { immediate: true }
);
const timeLeft = computed(() =>
  formatDuration(
    Math.max(0, approval.value.expires_at - Math.floor(now.value / 1000))
  )
);

const outcome = computed(() => {
  if (status.value === APPROVAL_STATUS.REJECTED) {
    return {
      icon: 'i-lucide-circle-x',
      color: 'text-n-slate-11',
      label: t('CAPTAIN.COPILOT.APPROVAL.STATUS.REJECTED'),
    };
  }
  if (status.value === APPROVAL_STATUS.EXPIRED) {
    return {
      icon: 'i-lucide-timer-off',
      color: 'text-n-slate-11',
      label: t('CAPTAIN.COPILOT.APPROVAL.STATUS.EXPIRED'),
      detail: t('CAPTAIN.COPILOT.APPROVAL.EXPIRED_HINT'),
    };
  }
  const {
    applied: appliedCount,
    total,
    not_changed: notChanged,
  } = progress.value;
  const applied =
    notChanged > 0
      ? t('CAPTAIN.COPILOT.APPROVAL.APPLIED_OF', {
          applied: appliedCount,
          total,
        })
      : t('CAPTAIN.COPILOT.APPROVAL.APPLIED', { count: appliedCount });
  if (progress.value.stopped) {
    return {
      icon: 'i-lucide-circle-stop',
      color: 'text-n-slate-11',
      label: t('CAPTAIN.COPILOT.APPROVAL.STOPPED'),
      detail: applied,
    };
  }
  if (notChanged > 0) {
    return {
      icon: 'i-lucide-triangle-alert',
      color: 'text-n-amber-11',
      label: applied,
    };
  }
  return { icon: 'i-lucide-check', color: 'text-n-teal-10', label: applied };
});

const linkRow = computed(() => {
  if (progress.value.finished && progress.value.not_changed > 0) {
    return {
      links: progress.value.not_changed_targets || [],
      total: progress.value.not_changed,
      notChanged: true,
    };
  }
  return { links: approval.value.targets || [], total: approval.value.count };
});

const warning = computed(() => {
  const { warning: key, count } = approval.value;
  return key && t(`CAPTAIN.COPILOT.APPROVAL.WARNINGS.${key}`, { count }, count);
});

const coverage = computed(() => approval.value.coverage);

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
      <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
        <CopilotApprovalSummary
          v-if="isAwaitingApproval"
          :approval="approval"
          emphasis
        />
        <template v-else-if="isApplying">
          <Spinner :size="16" class="flex-shrink-0 text-n-slate-9" />
          <span class="tabular-nums">
            {{
              t('CAPTAIN.COPILOT.APPROVAL.PROGRESS', {
                done: progress.done,
                total: progress.total,
              })
            }}
          </span>
        </template>
        <template v-else>
          <Icon
            :icon="outcome.icon"
            class="flex-shrink-0 size-4"
            :class="outcome.color"
          />
          <span class="font-medium">{{ outcome.label }}</span>
          <span v-if="outcome.detail" class="text-n-slate-11">
            {{ outcome.detail }}
          </span>
        </template>
      </div>
      <CopilotApprovalSummary v-if="!isAwaitingApproval" :approval="approval" />
    </div>
    <p
      v-if="approval.content"
      class="self-end max-w-[90%] px-3 py-2 m-0 rounded-xl rounded-ee-sm whitespace-pre-wrap break-words"
      :class="bubbleClass"
    >
      {{ approval.content }}
    </p>
    <!-- Links get a shorter line height from the global link style, so the row lines up text by its baseline. -->
    <div class="flex flex-wrap items-baseline gap-x-2 gap-y-1">
      <span v-if="linkRow.notChanged" class="text-n-amber-11">
        {{
          t('CAPTAIN.COPILOT.APPROVAL.NOT_CHANGED', { count: linkRow.total })
        }}
      </span>
      <router-link
        v-for="link in linkRow.links"
        :key="link.url"
        :to="link.url"
        class="text-n-blue-11 hover:underline"
      >
        {{ link.label }}
      </router-link>
      <span
        v-if="linkRow.links.length && linkRow.total > linkRow.links.length"
        class="text-n-slate-11"
      >
        {{
          t('CAPTAIN.COPILOT.APPROVAL.MORE_TARGETS', {
            count: linkRow.total - linkRow.links.length,
          })
        }}
      </span>
    </div>
    <template v-if="isAwaitingApproval">
      <p v-if="warning" class="flex gap-1.5 m-0 text-n-amber-11">
        <Icon
          icon="i-lucide-triangle-alert"
          class="flex-shrink-0 size-4 mt-0.5"
        />
        {{ warning }}
      </p>
      <p v-if="coverage" class="flex gap-1.5 m-0 text-n-amber-11">
        <Icon
          icon="i-lucide-triangle-alert"
          class="flex-shrink-0 size-4 mt-0.5"
        />
        {{
          t('CAPTAIN.COPILOT.APPROVAL.PARTIAL_REVIEW', {
            reviewed: coverage.reviewed,
            total: coverage.total,
            remaining: coverage.total - coverage.reviewed,
          })
        }}
      </p>
      <div class="flex flex-wrap items-center gap-2">
        <Button
          :label="approveLabel"
          :icon="isReply ? 'i-lucide-send' : ''"
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
        <span
          v-if="approval.expires_at"
          class="flex items-center gap-1 text-xs ms-auto text-n-slate-11 tabular-nums"
        >
          <Icon icon="i-lucide-clock" class="size-3.5" />
          {{ t('CAPTAIN.COPILOT.APPROVAL.EXPIRES_IN', { time: timeLeft }) }}
        </span>
      </div>
    </template>
    <CopilotProgressBar
      v-else-if="isApplying"
      :done="progress.done"
      :total="progress.total"
    />
  </div>
</template>
