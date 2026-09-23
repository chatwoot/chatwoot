<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useIntervalFn, useTimestamp } from '@vueuse/core';
import { useAccount } from 'dashboard/composables/useAccount';
import MonitorsAPI from 'dashboard/api/monitors';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ReportDrilldownCard from '../components/ReportDrilldownCard.vue';

const props = defineProps({ initialCondition: { type: String, default: '' } });
const emit = defineEmits(['created']);
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
const previewCooldown = computed(() =>
  Math.max(0, Math.ceil((previewAvailableAt.value - now.value) / 1000))
);
let previewPolling = null;
let previewGeneration = 0;
const isValid = computed(() => name.value.trim() && condition.value.trim());
watch(
  () => props.initialCondition,
  value => {
    condition.value = value;
  }
);

function resetPreview() {
  previewGeneration += 1;
  previewPolling?.pause();
  previewToken.value = null;
  preview.value = null;
  isPreviewing.value = false;
}
const previewFailed = code => {
  const key = `MONITORS.ERRORS.${code}`;
  error.value = t(te(key) ? key : 'MONITORS.ERRORS.fetch_failed');
  resetPreview();
};
async function refreshPreview() {
  const token = previewToken.value;
  if (!token) return;
  try {
    const { data } = await MonitorsAPI.previewStatus(token);
    if (token !== previewToken.value) return;
    if (data.status === 'pending') return;
    previewPolling.pause();
    isPreviewing.value = false;
    if (data.status === 'error') previewFailed(data.error);
    else preview.value = data;
  } catch {
    if (token === previewToken.value) previewFailed('fetch_failed');
  }
}
previewPolling = useIntervalFn(refreshPreview, 1500, {
  immediate: false,
});
watch(condition, resetPreview);
watch(accountId, () => {
  previewAvailableAt.value = 0;
  resetPreview();
});
onBeforeUnmount(resetPreview);

function setPreviewCooldown(seconds) {
  now.value = Date.now();
  previewAvailableAt.value = now.value + seconds * 1000;
}

const previewMatches = async () => {
  if (!condition.value.trim() || isPreviewing.value || previewCooldown.value) {
    return;
  }
  error.value = '';
  preview.value = null;
  isPreviewing.value = true;
  const requestedCondition = condition.value;
  const requestedAccount = accountId.value;
  const generation = previewGeneration;
  try {
    const { data } = await MonitorsAPI.preview(requestedCondition);
    if (requestedAccount !== accountId.value) return;
    setPreviewCooldown(data.retry_after);
    if (generation !== previewGeneration) return;
    previewToken.value = data.token;
    previewPolling.resume();
  } catch (failure) {
    if (requestedAccount !== accountId.value) return;
    if (failure.response?.data?.error === 'preview_rate_limit') {
      setPreviewCooldown(failure.response.data.retry_after);
      if (generation === previewGeneration) resetPreview();
      return;
    }
    if (generation === previewGeneration) {
      previewFailed(failure.response?.data?.error);
    }
  }
};

const open = () => {
  condition.value = props.initialCondition;
  name.value = '';
  error.value = '';
  resetPreview();
  dialog.value.open();
};

const create = async () => {
  if (!isValid.value || isSaving.value) return;
  isSaving.value = true;
  error.value = '';
  const requestedAccount = accountId.value;
  try {
    const { data } = await MonitorsAPI.create({
      name: name.value.trim(),
      condition: condition.value.trim(),
    });
    if (requestedAccount !== accountId.value) return;
    dialog.value.close();
    emit('created', data);
  } catch (failure) {
    const key = `MONITORS.ERRORS.${failure.response?.data?.error}`;
    error.value = t(te(key) ? key : 'MONITORS.ERRORS.save_failed');
  } finally {
    isSaving.value = false;
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialog"
    :title="t('MONITORS.CREATE')"
    :confirm-button-label="t('MONITORS.CREATE')"
    :disable-confirm-button="!isValid || isSaving"
    :is-loading="isSaving"
    @confirm="create"
    @close="resetPreview"
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
        :disabled="!condition.trim() || isPreviewing || previewCooldown > 0"
        :is-loading="isPreviewing"
        @click="previewMatches"
      />
      <p v-if="previewCooldown" class="m-0 text-sm text-n-slate-11">
        {{ t('MONITORS.PREVIEW_COOLDOWN', { seconds: previewCooldown }) }}
      </p>
      <div v-if="preview" class="flex flex-col gap-2">
        <p class="text-sm text-n-slate-11">
          {{
            t('MONITORS.PREVIEW_HELP', {
              matches: preview.payload.length,
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
