<script setup>
import { computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';
import BaseAttachmentBubble from './BaseAttachment.vue';

import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';

const { attachments } = useMessageContext();

const $store = useStore();
const { t } = useI18n();

const attachment = computed(() => {
  return attachments.value[0];
});

const phoneNumber = computed(() => {
  return attachment.value.fallbackTitle;
});

const contactName = computed(() => {
  const { meta } = attachment.value ?? {};
  const { firstName, lastName } = meta ?? {};
  return `${firstName ?? ''} ${lastName ?? ''}`.trim();
});

const formattedPhoneNumber = computed(() => {
  return phoneNumber.value.replace(/\s|-|[A-Za-z]/g, '');
});

const rawPhoneNumber = computed(() => {
  return phoneNumber.value.replace(/\D/g, '');
});

function getContactObject() {
  const contactItem = {
    name: contactName.value,
    phone_number: `+${rawPhoneNumber.value}`,
  };
  return contactItem;
}

async function filterContactByNumber(searchCandidate) {
  const query = {
    attribute_key: 'phone_number',
    filter_operator: 'equal_to',
    values: [searchCandidate],
    attribute_model: 'standard',
    custom_attribute_type: '',
  };

  const queryPayload = { payload: [query] };
  const contacts = await $store.dispatch('contacts/filter', {
    queryPayload,
    resetState: false,
  });
  return contacts.shift();
}

function openContactNewTab(contactId) {
  const accountId = window.location.pathname.split('/')[3];
  const url = `/app/accounts/${accountId}/contacts/${contactId}`;
  window.open(url, '_blank');
}

async function addContact() {
  try {
    let contact = await filterContactByNumber(rawPhoneNumber);
    if (!contact) {
      contact = await $store.dispatch('contacts/create', getContactObject());
      useAlert(t('CONTACT_FORM.SUCCESS_MESSAGE'));
    }
    openContactNewTab(contact.id);
  } catch (error) {
    if (error instanceof DuplicateContactException) {
      if (error.data.includes('phone_number')) {
        useAlert(t('CONTACT_FORM.FORM.PHONE_NUMBER.DUPLICATE'));
      }
    } else if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
    } else {
      useAlert(t('CONTACT_FORM.ERROR_MESSAGE'));
    }
  }
}

const action = computed(() => ({
  label: t('CONVERSATION.SAVE_CONTACT'),
  onClick: addContact,
}));
</script>

<template>
  <BaseAttachmentBubble
    icon="i-teenyicons-user-circle-solid"
    icon-bg-color="bg-[#D6409F]"
    sender-translation-key="CONVERSATION.SHARED_ATTACHMENT.CONTACT"
    :title="contactName"
    :content="phoneNumber"
    :action="formattedPhoneNumber ? action : null"
  />
</template>
