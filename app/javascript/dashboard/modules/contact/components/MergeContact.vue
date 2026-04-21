<script setup>
import { ref, computed } from 'vue';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { useI18n } from 'vue-i18n';

import MergeContactSummary from 'dashboard/modules/contact/components/MergeContactSummary.vue';
import ContactMergeForm from 'dashboard/components-next/Contacts/ContactsForm/ContactMergeForm.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  primaryContact: {
    type: Object,
    required: true,
  },
  isSearching: {
    type: Boolean,
    default: false,
  },
  isMerging: {
    type: Boolean,
    default: false,
  },
  searchResults: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['search', 'submit', 'cancel']);

const { t } = useI18n();

const parentContactId = ref(null);

const validationRules = {
  parentContactId: { required },
};

const v$ = useVuelidate(validationRules, { parentContactId });

const parentContact = computed(() => {
  if (!parentContactId.value) return null;
  return props.searchResults.find(
    contact => contact.id === parentContactId.value
  );
});

const parentContactName = computed(() => {
  return parentContact.value ? parentContact.value.name : '';
});

const primaryContactList = computed(() => {
  return props.searchResults.map(contact => ({
    id: contact.id,
    label: contact.name,
    value: contact.id,
    meta: {
      thumbnail: contact.thumbnail,
      email: contact.email,
      phoneNumber: contact.phone_number,
    },
  }));
});

const hasValidationError = computed(() => v$.value.parentContactId.$error);
const validationErrorMessage = computed(() => {
  if (v$.value.parentContactId.$error) {
    return t('MERGE_CONTACTS.FORM.CHILD_CONTACT.ERROR');
  }
  return '';
});

const onSearch = query => {
  emit('search', query);
};

const onSubmit = () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }
  emit('submit', parentContactId.value);
};

const onCancel = () => {
  emit('cancel');
};
</script>

<template>
  <form @submit.prevent="onSubmit">
    <ContactMergeForm
      :selected-contact="primaryContact"
      :primary-contact-id="parentContactId"
      :primary-contact-list="primaryContactList"
      :is-searching="isSearching"
      :has-error="hasValidationError"
      :error-message="validationErrorMessage"
      @update:primary-contact-id="parentContactId = $event"
      @search="onSearch"
    />
    <MergeContactSummary
      :primary-contact-name="primaryContact.name"
      :parent-contact-name="parentContactName"
    />
    <div class="flex justify-end gap-2 mt-6">
      <NextButton
        faded
        slate
        type="reset"
        :label="$t('MERGE_CONTACTS.FORM.CANCEL')"
        @click.prevent="onCancel"
      />
      <NextButton
        type="submit"
        :is-loading="isMerging"
        :label="$t('MERGE_CONTACTS.FORM.SUBMIT')"
      />
    </div>
  </form>
</template>
