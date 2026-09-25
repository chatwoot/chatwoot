<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';

import Button from 'dashboard/components-next/button/Button.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';
import ContactCustomAttributes from 'dashboard/components-next/Contacts/ContactsSidebar/ContactCustomAttributes.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';

const props = defineProps({
  contact: { type: Object, required: true },
});

const FORM_ERRORS_PREFIX = 'CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.FORM';

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('contacts/getUIFlags');

const panelRef = ref(null);
const contactsFormRef = ref(null);
const contactData = ref({});
const jobTitle = ref('');

const isUpdating = computed(() => uiFlags.value.isUpdating);
const isFormInvalid = computed(() => contactsFormRef.value?.isFormInvalid);

const open = () => {
  contactData.value = { ...props.contact };
  jobTitle.value = props.contact.additionalAttributes?.jobTitle || '';
  panelRef.value?.open();
};

const close = () => panelRef.value?.close();

const handleFormUpdate = updatedData => {
  Object.assign(contactData.value, updatedData);
};

const showUpdateError = error => {
  if (error instanceof DuplicateContactException) {
    const field = error.data.includes('email')
      ? 'EMAIL_ADDRESS'
      : 'PHONE_NUMBER';
    useAlert(t(`${FORM_ERRORS_PREFIX}.${field}.DUPLICATE`));
  } else if (error instanceof ExceptionWithMessage) {
    useAlert(error.data);
  } else {
    useAlert(t(`${FORM_ERRORS_PREFIX}.ERROR_MESSAGE`));
  }
};

const handleConfirm = async () => {
  if (isFormInvalid.value) return;

  const { id, name, email, phoneNumber, companyId, additionalAttributes } =
    contactData.value;
  try {
    await store.dispatch('contacts/update', {
      id,
      name,
      email,
      phoneNumber,
      companyId,
      additionalAttributes: {
        ...additionalAttributes,
        jobTitle: jobTitle.value.trim(),
      },
    });
    useAlert(t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.SUCCESS_MESSAGE'));
    close();
  } catch (error) {
    showUpdateError(error);
  }
};

defineExpose({ open });
</script>

<template>
  <SidePanel
    ref="panelRef"
    width="2xl"
    :title="t('CONTACTS_LAYOUT.DETAIL.EDIT.TITLE')"
  >
    <div class="flex flex-col gap-8">
      <ContactsForm
        ref="contactsFormRef"
        :contact-data="contactData"
        is-details-view
        @update="handleFormUpdate"
      />

      <section class="flex flex-col gap-2">
        <span class="py-1 text-sm font-medium text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.DETAIL.EDIT.WORK') }}
        </span>
        <Input
          v-model="jobTitle"
          :placeholder="t('CONTACTS_LAYOUT.DETAIL.EDIT.JOB_TITLE_PLACEHOLDER')"
          :disabled="isUpdating"
          class="w-full sm:w-1/2"
        />
      </section>

      <section class="flex flex-col gap-4">
        <h4 class="mb-0 text-heading-3 text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.DETAIL.EDIT.ATTRIBUTES') }}
        </h4>
        <ContactCustomAttributes :selected-contact="contact" />
      </section>
    </div>

    <template #footer>
      <div class="flex items-center justify-end w-full gap-3">
        <Button
          :label="t('DIALOG.BUTTONS.CANCEL')"
          variant="faded"
          color="slate"
          type="button"
          @click="close"
        />
        <Button
          :label="t('CONTACTS_LAYOUT.DETAIL.EDIT.SAVE')"
          color="blue"
          type="button"
          :disabled="isFormInvalid || isUpdating"
          :is-loading="isUpdating"
          @click="handleConfirm"
        />
      </div>
    </template>
  </SidePanel>
</template>
