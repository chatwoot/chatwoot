<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import OrderModal from './conversation/OrderModal.vue';
import OrdersAPI from '../../api/orders';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const showOrderModal = ref(false);
const isSubmitting = ref(false);

const currentChat = computed(() => store.getters.getSelectedChat);
const accountId = computed(() => store.getters.getCurrentAccountId);

const openOrderModal = () => {
  showOrderModal.value = true;
};

const closeOrderModal = () => {
  showOrderModal.value = false;
};

const handleSubmit = async orderData => {
  isSubmitting.value = true;
  try {
    await OrdersAPI.create(accountId.value, props.conversationId, orderData);
    useAlert(t('ORDER.SUCCESS'));
    closeOrderModal();
  } catch (error) {
    const errorMessage = error.response?.data?.error || t('ORDER.ERROR');
    useAlert(errorMessage);
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="relative">
    <NextButton
      v-tooltip.top-end="$t('ORDER.BUTTON_TEXT')"
      icon="i-ph-shopping-cart"
      slate
      faded
      sm
      @click="openOrderModal"
    />
    <woot-modal v-model:show="showOrderModal" :on-close="closeOrderModal">
      <OrderModal
        :show="showOrderModal"
        :current-chat="currentChat"
        :is-submitting="isSubmitting"
        @cancel="closeOrderModal"
        @submit="handleSubmit"
        @update:show="showOrderModal = $event"
      />
    </woot-modal>
  </div>
</template>
