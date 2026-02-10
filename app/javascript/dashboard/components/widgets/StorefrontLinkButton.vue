<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import StorefrontLinksAPI from '../../api/storefrontLinks';
import MessageAPI from '../../api/inbox/message';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const isLoading = ref(false);

const currentChat = computed(() => store.getters.getSelectedChat);
const accountId = computed(() => store.getters.getCurrentAccountId);
const contactId = computed(() => currentChat.value?.meta?.sender?.id);

const generateAndSendLink = async () => {
  if (!contactId.value) {
    useAlert(t('STOREFRONT_LINK.NO_CONTACT'));
    return;
  }

  isLoading.value = true;
  try {
    const { data } = await StorefrontLinksAPI.create(accountId.value, {
      contactId: contactId.value,
      conversationId: props.conversationId,
    });

    const messageContent = `${t('STOREFRONT_LINK.MESSAGE_PREFIX')} ${data.storefront_url}`;

    await MessageAPI.create({
      conversationId: props.conversationId,
      message: messageContent,
      private: false,
    });

    useAlert(t('STOREFRONT_LINK.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error.response?.data?.error || t('STOREFRONT_LINK.ERROR');
    useAlert(errorMessage);
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <NextButton
    v-tooltip.top-end="$t('STOREFRONT_LINK.BUTTON_TEXT')"
    icon="i-ph-storefront"
    slate
    faded
    sm
    :loading="isLoading"
    @click="generateAndSendLink"
  />
</template>
