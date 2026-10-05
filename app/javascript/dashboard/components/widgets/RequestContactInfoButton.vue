<script setup>
import { computed, ref, watch } from 'vue';
import { useInbox } from 'dashboard/composables/useInbox';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
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

const capability = ref({});
const { isAWhatsAppCloudChannel } = useInbox();
const { run, abort, isPending } = useAbortableRequest();

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
    isPending.value ||
    isRequesting.value ||
    hasPendingRequest.value ||
    capability.value.reason === 'pending_request'
);

const tooltip = computed(() =>
  hasPendingRequest.value || capability.value.reason === 'pending_request'
    ? t('CONVERSATION.REQUEST_CONTACT_INFO.PENDING_ACTION')
    : t('CONVERSATION.REQUEST_CONTACT_INFO.ACTION')
);

const requestStates = computed(() =>
  (currentChat.value?.messages || [])
    .filter(message => message.content_attributes?.whatsapp_contact_info)
    .map(
      message =>
        `${message.id}:${message.status}:${message.content_attributes.whatsapp_contact_info.state}`
    )
    .join(',')
);

const fetchAvailability = async () => {
  abort();
  capability.value = {};
  const conversationId = currentChat.value?.id;
  if (
    !conversationId ||
    !isAWhatsAppCloudChannel.value ||
    currentContact.value.phone_number
  )
    return;

  try {
    const availability = await run(signal =>
      store.dispatch('getContactInfoRequestAvailability', {
        conversationId,
        signal,
      })
    );
    if (availability) capability.value = availability;
  } catch (error) {
    useAlert(error?.response?.data?.error || t('CONVERSATION.MESSAGE_ERROR'));
  }
};

watch(
  [
    currentChat,
    isAWhatsAppCloudChannel,
    () => currentContact.value.phone_number,
    () => currentChat.value?.can_reply,
    requestStates,
  ],
  fetchAvailability,
  { immediate: true }
);

const requestContactInfo = async () => {
  if (capability.value.delivery_mode === 'template') {
    emit('requestTemplate');
    return;
  }

  const conversationId = currentChat.value.id;
  isRequesting.value = true;
  try {
    await store.dispatch('requestContactInfo', conversationId);
  } catch (error) {
    if (currentChat.value.id !== conversationId) return;
    useAlert(error?.response?.data?.error || t('CONVERSATION.MESSAGE_ERROR'));
    fetchAvailability();
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
