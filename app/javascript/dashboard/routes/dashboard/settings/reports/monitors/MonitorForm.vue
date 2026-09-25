<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTimeoutPoll, useTimestamp } from '@vueuse/core';
import { useAccount } from 'dashboard/composables/useAccount';
import MonitorsAPI from 'dashboard/api/monitors';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ReportDrilldownCard from '../components/ReportDrilldownCard.vue';

const emit = defineEmits(['created']);

const PREVIEW_POLL_INTERVAL_MS = 1500;

const { t, te } = useI18n();
const { accountId } = useAccount();
const dialog = ref(null);
const name = ref('');
const condition = ref('');
const isSaving = ref(false);
const error = ref('');
const preview = ref(null);
const previewToken = ref(null);
const isPreviewing = ref(false);
const now = useTimestamp({ interval: 1000 });
const previewAvailableAt = ref(0);
// Bumped on every reset so a late response for an older condition is ignored.
let previewGeneration = 0;
let dialogGeneration = 0;

const previewCooldown = computed(() =>
  Math.max(0, Math.ceil((previewAvailableAt.value - now.value) / 1000))
);
const isValid = computed(() => name.value.trim() && condition.value.trim());
const canPreview = computed(
  () =>
    !!condition.value.trim() && !isPreviewing.value && !previewCooldown.value
);

const errorText = (code, fallback) => {
  const key = code && `MONITORS.ERRORS.${code.toUpperCase()}`;
  return t(key && (te(key) || te(key, 'en')) ? key : fallback);
};

const resetPreview = () => {
  previewGeneration += 1;
  previewToken.value = null;
  preview.value = null;
  isPreviewing.value = false;
};
const previewFailed = code => {
  error.value = errorText(code, 'MONITORS.PREVIEW_FAILED');
  resetPreview();
};
const setPreviewCooldown = seconds => {
  now.value = Date.now();
  previewAvailableAt.value = now.value + seconds * 1000;
};

const refreshPreview = async () => {
  const token = previewToken.value;
  if (!token) return;
  try {
    const { data } = await MonitorsAPI.previewStatus(token);
    if (token !== previewToken.value || data.status === 'pending') return;
    previewToken.value = null;
    isPreviewing.value = false;
    if (data.status === 'error') previewFailed(data.error);
    else preview.value = data;
  } catch {
    if (token === previewToken.value) previewFailed();
  }
};

const { pause, resume } = useTimeoutPoll(
  refreshPreview,
  PREVIEW_POLL_INTERVAL_MS
);
watch(previewToken, token => (token ? resume() : pause()));
watch(condition, resetPreview);
onBeforeUnmount(() => {
  dialogGeneration += 1;
  resetPreview();
});

const previewMatches = async () => {
  if (!canPreview.value) return;
  error.value = '';
  preview.value = null;
  isPreviewing.value = true;
  const requestedAccount = accountId.value;
  const generation = previewGeneration;
  try {
    const { data } = await MonitorsAPI.preview(condition.value);
    if (requestedAccount !== accountId.value) return;
    setPreviewCooldown(data.retry_after);
    if (generation !== previewGeneration) return;
    previewToken.value = data.token;
  } catch (failure) {
    if (requestedAccount !== accountId.value) return;
    const { error: code, retry_after: retryAfter } =
      failure.response?.data || {};
    if (code === 'preview_rate_limit') {
      setPreviewCooldown(retryAfter);
      if (generation === previewGeneration) resetPreview();
      return;
    }
    if (generation === previewGeneration) previewFailed(code);
  }
};

const open = (prefill = {}) => {
  dialogGeneration += 1;
  name.value = prefill.name || '';
  condition.value = prefill.condition || '';
  error.value = '';
  resetPreview();
  dialog.value.open();
};
const onClose = () => {
  dialogGeneration += 1;
  resetPreview();
};

const create = async () => {
  if (!isValid.value || isSaving.value) return;
  isSaving.value = true;
  error.value = '';
  const requestedAccount = accountId.value;
  const generation = dialogGeneration;
  try {
    const { data } = await MonitorsAPI.create({
      name: name.value.trim(),
      condition: condition.value.trim(),
    });
    if (requestedAccount !== accountId.value || generation !== dialogGeneration)
      return;
    dialog.value.close();
    emit('created', data);
  } catch (failure) {
    if (requestedAccount !== accountId.value || generation !== dialogGeneration)
      return;
    error.value = errorText(
      failure.response?.data?.error,
      'MONITORS.ERRORS.SAVE_FAILED'
    );
  } finally {
    isSaving.value = false;
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialog"
    overflow-y-auto
    :title="t('MONITORS.CREATE')"
    :confirm-button-label="t('MONITORS.CREATE')"
    :disable-confirm-button="!isValid || isSaving"
    :is-loading="isSaving"
    @confirm="create"
    @close="onClose"
  >
    <form class="flex flex-col gap-5" @submit.prevent="create">
      <Input
        v-model="name"
        :label="t('MONITORS.NAME')"
        :placeholder="t('MONITORS.NAME_PLACEHOLDER')"
        maxlength="100"
        autofocus
      />
      <TextArea
        id="monitor-condition"
        v-model="condition"
        :label="t('MONITORS.CONDITION')"
        :placeholder="t('MONITORS.CONDITION_PLACEHOLDER')"
        :max-length="2000"
        custom-text-area-class="min-h-24"
        show-character-count
      />
      <p class="m-0 text-sm text-n-slate-11">{{ t('MONITORS.CREATE_HELP') }}</p>
      <Button
        type="button"
        slate
        faded
        :label="t('MONITORS.PREVIEW')"
        :disabled="!canPreview"
        :is-loading="isPreviewing"
        @click="previewMatches"
      />
      <p v-if="previewCooldown" class="m-0 text-sm text-n-slate-11">
        {{ t('MONITORS.PREVIEW_COOLDOWN', { count: previewCooldown }) }}
      </p>
      <div v-if="preview" class="flex flex-col gap-2">
        <p class="text-sm text-n-slate-11">
          {{
            t('MONITORS.PREVIEW_HELP', {
              count: preview.payload.length,
              sampled: preview.sampled,
              excluded: preview.excluded,
            })
          }}
        </p>
        <ReportDrilldownCard
          v-for="record in preview.payload"
          :key="record.conversation.id"
          :record="record"
        />
      </div>
      <p v-if="error" role="alert" class="m-0 text-sm text-n-ruby-11">
        {{ error }}
      </p>
    </form>
  </Dialog>
</template>
