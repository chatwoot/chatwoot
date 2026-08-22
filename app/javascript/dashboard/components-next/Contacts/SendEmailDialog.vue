<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import ConversationsAPI from 'dashboard/api/conversations';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  contactId: { type: [String, Number], required: true },
  contactEmail: { type: String, default: '' },
});

const emit = defineEmits(['close', 'sent']);

const { t } = useI18n();

const dialogRef = ref(null);
const isSending = ref(false);

const emailInboxes = useMapGetter('inboxes/getEmailInboxes');
const inboxOptions = computed(() =>
  (emailInboxes.value || []).map(i => ({ value: i.id, label: i.name }))
);

const state = ref({
  inboxId: null,
  subject: '',
  message: '',
  ccEmails: '',
  bccEmails: '',
});

const canSend = computed(
  () =>
    state.value.inboxId &&
    state.value.message.trim().length > 0 &&
    props.contactEmail
);

const open = () => dialogRef.value?.open();
const close = () => dialogRef.value?.close();

defineExpose({ open, close });

const handleSend = async () => {
  if (!canSend.value) return;
  isSending.value = true;
  try {
    await ConversationsAPI.sendEmail({
      inbox_id: state.value.inboxId,
      contact_id: props.contactId,
      subject: state.value.subject,
      message: state.value.message,
      cc_emails: state.value.ccEmails
        .split(',')
        .map(s => s.trim())
        .filter(Boolean),
      bcc_emails: state.value.bccEmails
        .split(',')
        .map(s => s.trim())
        .filter(Boolean),
    });
    useAlert(t('CONTACTS_LAYOUT.SEND_EMAIL.SUCCESS'));
    emit('sent');
    state.value = {
      inboxId: null,
      subject: '',
      message: '',
      ccEmails: '',
      bccEmails: '',
    };
    close();
  } catch (error) {
    useAlert(
      error?.response?.data?.error || t('CONTACTS_LAYOUT.SEND_EMAIL.ERROR')
    );
  } finally {
    isSending.value = false;
  }
};
</script>

<template>
  <Dialog ref="dialogRef" @close="emit('close')">
    <template #header>
      <h3 class="text-lg font-medium text-n-slate-12">
        {{ t('CONTACTS_LAYOUT.SEND_EMAIL.TITLE') }}
      </h3>
    </template>
    <div class="flex flex-col gap-4 p-1">
      <p class="text-sm text-n-slate-11">
        {{ t('CONTACTS_LAYOUT.SEND_EMAIL.INFO', { email: contactEmail }) }}
      </p>

      <div class="flex flex-col gap-1">
        <label class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.SEND_EMAIL.INBOX') }}
        </label>
        <ComboBox
          v-model="state.inboxId"
          :options="inboxOptions"
          :placeholder="t('CONTACTS_LAYOUT.SEND_EMAIL.INBOX_PLACEHOLDER')"
        />
      </div>

      <Input
        v-model="state.subject"
        :label="t('CONTACTS_LAYOUT.SEND_EMAIL.SUBJECT')"
        :placeholder="t('CONTACTS_LAYOUT.SEND_EMAIL.SUBJECT_PLACEHOLDER')"
      />

      <div class="flex flex-col gap-1">
        <label class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.SEND_EMAIL.MESSAGE') }}
        </label>
        <textarea
          v-model="state.message"
          rows="6"
          class="w-full px-3 py-2 text-sm rounded-lg bg-n-alpha-black2 text-n-slate-12 border border-n-weak outline-none focus:border-n-brand resize-y"
          :placeholder="t('CONTACTS_LAYOUT.SEND_EMAIL.MESSAGE_PLACEHOLDER')"
        />
      </div>

      <Input
        v-model="state.ccEmails"
        :label="t('CONTACTS_LAYOUT.SEND_EMAIL.CC')"
        :placeholder="t('CONTACTS_LAYOUT.SEND_EMAIL.CC_PLACEHOLDER')"
      />
      <Input
        v-model="state.bccEmails"
        :label="t('CONTACTS_LAYOUT.SEND_EMAIL.BCC')"
        :placeholder="t('CONTACTS_LAYOUT.SEND_EMAIL.BCC_PLACEHOLDER')"
      />

      <div class="flex gap-3 justify-end">
        <Button
          variant="faded"
          color="slate"
          :label="t('CONTACTS_LAYOUT.SEND_EMAIL.CANCEL')"
          @click="close"
        />
        <Button
          :label="t('CONTACTS_LAYOUT.SEND_EMAIL.SEND')"
          :disabled="!canSend || isSending"
          :is-loading="isSending"
          @click="handleSend"
        />
      </div>
    </div>
  </Dialog>
</template>
