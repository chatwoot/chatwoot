<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CartModal from './conversation/CartModal.vue';
import CartsAPI from '../../api/carts';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const showCartModal = ref(false);
const isSubmitting = ref(false);

const currentChat = computed(() => store.getters.getSelectedChat);
const accountId = computed(() => store.getters.getCurrentAccountId);

const openCartModal = () => {
  showCartModal.value = true;
};

const closeCartModal = () => {
  showCartModal.value = false;
};

const handleSubmit = async cartData => {
  isSubmitting.value = true;
  try {
    await CartsAPI.create(accountId.value, props.conversationId, cartData);
    useAlert(t('CART.SUCCESS'));
    closeCartModal();
  } catch (error) {
    const errorMessage = error.response?.data?.error || t('CART.ERROR');
    useAlert(errorMessage);
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="relative">
    <NextButton
      v-tooltip.top-end="$t('CART.BUTTON_TEXT')"
      icon="i-ph-shopping-cart"
      slate
      faded
      sm
      @click="openCartModal"
    />
    <woot-modal v-model:show="showCartModal" :on-close="closeCartModal">
      <CartModal
        :show="showCartModal"
        :current-chat="currentChat"
        :is-submitting="isSubmitting"
        @cancel="closeCartModal"
        @submit="handleSubmit"
        @update:show="showCartModal = $event"
      />
    </woot-modal>
  </div>
</template>
