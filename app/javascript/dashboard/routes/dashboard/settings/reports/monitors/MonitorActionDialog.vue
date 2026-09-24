<script setup>
import { computed, onBeforeUnmount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import MonitorsAPI from 'dashboard/api/monitors';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['saved', 'changed']);
const { t, te } = useI18n();
const { accountId } = useAccount();
const dialog = ref(null);
const monitor = ref(null);
const action = ref('');
const newName = ref('');
const newCondition = ref('');
const actionError = ref('');
const resumeMode = ref('catch_up');
const isSaving = ref(false);
let isActive = true;
onBeforeUnmount(() => {
  isActive = false;
});
const actionLabel = computed(() =>
  t(`MONITORS.${action.value.toUpperCase() || 'EDIT'}`)
);

const open = (nextAction, targetMonitor) => {
  if (isSaving.value) return;
  action.value = nextAction;
  monitor.value = { ...targetMonitor };
  newName.value = targetMonitor.name;
  newCondition.value = targetMonitor.condition;
  actionError.value = '';
  resumeMode.value = 'catch_up';
  dialog.value.open();
};
const close = () => dialog.value?.close();
const saveAction = async () => {
  if (isSaving.value) return;
  isSaving.value = true;
  actionError.value = '';
  const requestedAccount = accountId.value;
  const { id, collection_version: collectionVersion } = monitor.value;
  try {
    if (action.value === 'delete') {
      await MonitorsAPI.delete(id);
    } else if (action.value === 'resume') {
      await MonitorsAPI.resume(id, {
        mode: resumeMode.value,
        collection_version: collectionVersion,
      });
    } else {
      await MonitorsAPI.update(
        id,
        action.value === 'edit'
          ? {
              name: newName.value.trim(),
              condition: newCondition.value.trim(),
              collection_version: collectionVersion,
            }
          : { paused: true }
      );
    }
    if (!isActive || requestedAccount !== accountId.value) return;
    close();
    emit('saved', action.value);
  } catch (failure) {
    if (!isActive || requestedAccount !== accountId.value) return;
    const key = `MONITORS.ERRORS.${failure.response?.data?.error}`;
    actionError.value = t(te(key) ? key : 'MONITORS.ERRORS.save_failed');
    if (failure.response?.data?.error === 'monitor_changed') {
      close();
      emit('changed', actionError.value);
    }
  } finally {
    isSaving.value = false;
  }
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialog"
    :title="actionLabel"
    :confirm-button-label="
      action === 'edit' ? t('MONITORS.UPDATE') : actionLabel
    "
    :is-loading="isSaving"
    :disable-confirm-button="
      isSaving ||
      (action === 'edit' && (!newName.trim() || !newCondition.trim()))
    "
    @confirm="saveAction"
  >
    <div v-if="action === 'edit'" class="flex flex-col gap-4">
      <Input v-model="newName" :label="t('MONITORS.NAME')" maxlength="100" />
      <TextArea
        id="monitor-edit-condition"
        v-model="newCondition"
        :label="t('MONITORS.MONITOR_DESCRIPTION')"
        :placeholder="t('MONITORS.CONDITION_PLACEHOLDER')"
        :max-length="2000"
        custom-text-area-class="min-h-24"
        show-character-count
      />
      <p class="m-0 text-sm text-n-slate-11">{{ t('MONITORS.EDIT_HELP') }}</p>
    </div>
    <fieldset v-else-if="action === 'resume'" class="flex flex-col gap-4">
      <legend class="mb-4 text-sm text-n-slate-11">
        {{ t('MONITORS.RESUME_HELP') }}
      </legend>
      <label
        class="flex cursor-pointer items-start gap-3 rounded-lg border border-n-weak p-4"
      >
        <input
          v-model="resumeMode"
          type="radio"
          value="catch_up"
          name="monitor-resume-mode"
          class="mt-1"
        />
        <span class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">{{
            t('MONITORS.RESUME_CATCH_UP')
          }}</span>
          <span class="text-sm text-n-slate-11">{{
            t('MONITORS.RESUME_CATCH_UP_HELP')
          }}</span>
        </span>
      </label>
      <label
        class="flex cursor-pointer items-start gap-3 rounded-lg border border-n-weak p-4"
      >
        <input
          v-model="resumeMode"
          type="radio"
          value="from_now"
          name="monitor-resume-mode"
          class="mt-1"
        />
        <span class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">{{
            t('MONITORS.RESUME_FROM_NOW')
          }}</span>
          <span class="text-sm text-n-slate-11">{{
            t('MONITORS.RESUME_FROM_NOW_HELP')
          }}</span>
        </span>
      </label>
    </fieldset>
    <p v-else class="text-sm text-n-slate-11">
      {{
        t(action === 'delete' ? 'MONITORS.DELETE_HELP' : 'MONITORS.PAUSE_HELP')
      }}
    </p>
    <p v-if="actionError" role="alert" class="mt-4 text-sm text-n-ruby-11">
      {{ actionError }}
    </p>
  </Dialog>
</template>
