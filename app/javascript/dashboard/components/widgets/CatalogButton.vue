<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import CatalogSendModal from './conversation/CatalogSendModal.vue';
import CatalogItemsAPI from '../../api/catalogItems';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const showCatalogModal = ref(false);
const isSubmitting = ref(false);

const currentChat = computed(() => store.getters.getSelectedChat);
const accountId = computed(() => store.getters.getCurrentAccountId);

const openCatalogModal = () => {
  showCatalogModal.value = true;
};

const closeCatalogModal = () => {
  showCatalogModal.value = false;
};

const handleSubmit = async catalogData => {
  isSubmitting.value = true;
  try {
    await CatalogItemsAPI.send(
      accountId.value,
      props.conversationId,
      catalogData.productIds
    );
    useAlert(t('CATALOG_SEND.SUCCESS'));
    closeCatalogModal();
  } catch (error) {
    const errorMessage = error.response?.data?.error || t('CATALOG_SEND.ERROR');
    useAlert(errorMessage);
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="relative">
    <NextButton
      v-tooltip.top-end="$t('CATALOG_SEND.BUTTON_TEXT')"
      icon="i-ph-package"
      slate
      faded
      sm
      @click="openCatalogModal"
    />
    <woot-modal v-model:show="showCatalogModal" :on-close="closeCatalogModal">
      <CatalogSendModal
        :show="showCatalogModal"
        :current-chat="currentChat"
        :is-submitting="isSubmitting"
        @cancel="closeCatalogModal"
        @submit="handleSubmit"
        @update:show="showCatalogModal = $event"
      />
    </woot-modal>
  </div>
</template>
