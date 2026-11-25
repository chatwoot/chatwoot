<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Select from 'dashboard/components-next/select/Select.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const WINDOW = 'assignee_within_window';
const MAX_WINDOW_HOURS = 8760;

const store = useStore();
const { t } = useI18n();

const owner = ref('agent_bot');
const hours = ref('');
const isSaving = ref(false);

const syncFromInbox = () => {
  owner.value = props.inbox.reopen_owner || 'agent_bot';
  hours.value = props.inbox.reopen_owner_window_hours ?? '';
};
syncFromInbox();

watch(
  () => [
    props.inbox.id,
    props.inbox.reopen_owner,
    props.inbox.reopen_owner_window_hours,
  ],
  syncFromInbox
);

const options = computed(() => [
  {
    value: 'agent_bot',
    label: t('INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.OPTIONS.AGENT_BOT'),
  },
  {
    value: 'assignee',
    label: t('INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.OPTIONS.ASSIGNEE'),
  },
  {
    value: WINDOW,
    label: t(
      'INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.OPTIONS.ASSIGNEE_WITHIN_WINDOW'
    ),
  },
]);

const isWindow = computed(() => owner.value === WINDOW);

const hoursValue = computed(() => Number(hours.value));
const hoursEmpty = computed(() => String(hours.value).trim() === '');
const hoursValid = computed(
  () =>
    !hoursEmpty.value &&
    Number.isInteger(hoursValue.value) &&
    hoursValue.value >= 1 &&
    hoursValue.value <= MAX_WINDOW_HOURS
);

const hasChanges = computed(() => {
  if (owner.value !== (props.inbox.reopen_owner || 'agent_bot')) return true;
  return (
    isWindow.value && hoursValue.value !== props.inbox.reopen_owner_window_hours
  );
});

// An empty field is not an error yet: it is where the window starts.
const showHoursError = computed(() => !hoursEmpty.value && !hoursValid.value);

const canSave = computed(
  () =>
    hasChanges.value && !isSaving.value && (!isWindow.value || hoursValid.value)
);

const save = async () => {
  if (!canSave.value) return;
  isSaving.value = true;
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      reopen_owner: owner.value,
      ...(isWindow.value && { reopen_owner_window_hours: hoursValue.value }),
    });
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    syncFromInbox();
    useAlert(t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div
    class="flex flex-col gap-3 p-4 rounded-xl outline outline-1 -outline-offset-1 outline-n-weak"
  >
    <div class="flex flex-col gap-1">
      <h4 class="text-heading-3 text-n-slate-12">
        {{ $t('INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.TITLE') }}
      </h4>
      <p class="text-body-main text-n-slate-11">
        {{ $t('INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.DESCRIPTION') }}
      </p>
    </div>

    <Select
      v-model="owner"
      :options="options"
      :aria-label="$t('INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.TITLE')"
    />

    <Input
      v-if="isWindow"
      v-model="hours"
      type="number"
      min="1"
      :max="String(MAX_WINDOW_HOURS)"
      :label="$t('INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.HOURS_LABEL')"
      :message="
        showHoursError
          ? $t('INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.HOURS_ERROR')
          : $t('INBOX_MGMT.ASSIGNMENT.REOPEN_OWNER.HOURS_HELP')
      "
      :message-type="showHoursError ? 'error' : 'info'"
      class="max-w-xs"
    />

    <div class="flex justify-end">
      <NextButton
        :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :disabled="!canSave"
        :is-loading="isSaving"
        @click="save"
      />
    </div>
  </div>
</template>
