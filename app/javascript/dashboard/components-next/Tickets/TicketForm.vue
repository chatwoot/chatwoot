<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';

import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import { TICKET_TYPES, TICKET_WAITING_ON_OPTIONS } from './constants';

const props = defineProps({
  ticket: {
    type: Object,
    default: null,
  },
  isSaving: {
    type: Boolean,
    default: false,
  },
  showCancel: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const toDateInputValue = value =>
  value ? format(new Date(value), 'yyyy-MM-dd') : '';

const form = reactive({
  subject: '',
  ticketType: '',
  dueAt: '',
  waitingOn: 'none',
  waitingNote: '',
});

const hasSubjectError = ref(false);

const resetForm = ticket => {
  form.subject = ticket?.subject || '';
  form.ticketType = ticket?.ticketType || '';
  form.dueAt = toDateInputValue(ticket?.dueAt);
  form.waitingOn = ticket?.waitingOn || 'none';
  form.waitingNote = ticket?.waitingNote || '';
  hasSubjectError.value = false;
};

resetForm(props.ticket);

watch(() => props.ticket, resetForm);

const typeOptions = computed(() =>
  TICKET_TYPES.map(value => ({
    value,
    label: t(`TICKETS.TYPE.${value.toUpperCase()}`),
  }))
);

const waitingOnOptions = computed(() =>
  TICKET_WAITING_ON_OPTIONS.map(value => ({
    value,
    label: t(`TICKETS.WAITING_ON.${value.toUpperCase()}`),
  }))
);

const isWaiting = computed(() => form.waitingOn && form.waitingOn !== 'none');

const onSubmit = () => {
  const subject = form.subject.trim();
  hasSubjectError.value = !subject;
  if (hasSubjectError.value) return;

  emit('submit', {
    subject,
    ticket_type: form.ticketType || null,
    due_at: form.dueAt || null,
    waiting_on: form.waitingOn || 'none',
    waiting_note: isWaiting.value ? form.waitingNote.trim() : '',
  });
};
</script>

<template>
  <form class="flex flex-col gap-3" @submit.prevent="onSubmit">
    <Input
      v-model="form.subject"
      size="sm"
      :label="t('TICKETS.FORM.SUBJECT')"
      :placeholder="t('TICKETS.FORM.SUBJECT_PLACEHOLDER')"
      :message="hasSubjectError ? t('TICKETS.FORM.SUBJECT_REQUIRED') : ''"
      :message-type="hasSubjectError ? 'error' : 'info'"
    />
    <div class="flex flex-col gap-1">
      <span class="text-heading-3 text-n-slate-12">
        {{ t('TICKETS.FORM.TYPE') }}
      </span>
      <ComboBox
        v-model="form.ticketType"
        :options="typeOptions"
        :placeholder="t('TICKETS.FORM.TYPE_PLACEHOLDER')"
      />
    </div>
    <Input
      v-model="form.dueAt"
      type="date"
      size="sm"
      :label="t('TICKETS.FORM.DUE_AT')"
    />
    <div class="flex flex-col gap-1">
      <span class="text-heading-3 text-n-slate-12">
        {{ t('TICKETS.FORM.WAITING_ON') }}
      </span>
      <ComboBox v-model="form.waitingOn" :options="waitingOnOptions" />
    </div>
    <Input
      v-if="isWaiting"
      v-model="form.waitingNote"
      size="sm"
      :label="t('TICKETS.FORM.WAITING_NOTE')"
      :placeholder="t('TICKETS.FORM.WAITING_NOTE_PLACEHOLDER')"
    />
    <div class="flex items-center justify-end gap-2">
      <Button
        v-if="showCancel"
        type="button"
        variant="ghost"
        color="slate"
        size="sm"
        :label="t('TICKETS.FORM.CANCEL')"
        @click="emit('cancel')"
      />
      <Button
        type="submit"
        size="sm"
        :is-loading="isSaving"
        :disabled="isSaving"
        :label="t('TICKETS.FORM.SAVE')"
      />
    </div>
  </form>
</template>
