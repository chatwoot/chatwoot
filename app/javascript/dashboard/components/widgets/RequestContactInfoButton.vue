<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import NextButton from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['requestTemplate']);

const store = useStore();
const { t } = useI18n();

const currentChat = useMapGetter('getSelectedChat');
const contactById = useMapGetter('contacts/getContact');

const isRequesting = ref(false);

const capability = computed(
  () => currentChat.value?.contact_info_request || {}
);

const currentContact = computed(() => {
  const senderId = currentChat.value?.meta?.sender?.id;
  if (!senderId) return {};
  return contactById.value(senderId);
});

const hasPendingRequest = computed(() =>
  (currentChat.value?.messages || []).some(message => {
    const contactInfo = message.content_attributes?.whatsapp_contact_info || {};
    return (
      contactInfo.type === 'request' &&
      contactInfo.state === 'pending' &&
      message.status !== 'failed'
    );
  })
);

const showButton = computed(
  () =>
    !currentContact.value.phone_number &&
    (capability.value.available ||
      capability.value.reason === 'pending_request')
);

const isDisabled = computed(
  () =>
    isRequesting.value ||
    hasPendingRequest.value ||
    capability.value.reason === 'pending_request'
);

const tooltip = computed(() =>
  hasPendingRequest.value
    ? t('CONVERSATION.REQUEST_CONTACT_INFO.PENDING_ACTION')
    : t('CONVERSATION.REQUEST_CONTACT_INFO.ACTION')
);

const requestContactInfo = async () => {
  if (capability.value.delivery_mode === 'template') {
    emit('requestTemplate');
    return;
  }

  isRequesting.value = true;
  try {
    await store.dispatch('requestContactInfo', currentChat.value.id);
  } catch (error) {
    useAlert(error?.response?.data?.error || t('CONVERSATION.MESSAGE_ERROR'));
  } finally {
    isRequesting.value = false;
  }
};
</script>

<template>
  <NextButton
    v-if="showButton"
    v-tooltip.top-end="tooltip"
    icon="i-ph-address-book"
    slate
    faded
    sm
    :disabled="isDisabled"
    :is-loading="isRequesting"
    @click="requestContactInfo"
  />
  <template v-else />
</template>
