<template>
  <div class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.SHOPIFY_SETTINGS')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.SHOPIFY_SETTINGS_DESCRIPTION')"
    >
      <div v-if="shopifyStore" class="space-y-4">
        <div class="flex items-center gap-2">
          <span class="font-medium">Shop Domain:</span>
          <span>{{ shopifyStore.shop || 'Not available' }}</span>
        </div>
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-lg font-medium">{{ $t('INBOX_MGMT.SETTINGS_POPUP.SHOPIFY_CHAT_BOT') }}</h3>
            <p class="text-sm text-slate-600">{{ $t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_CHAT_BOT') }}</p>
          </div>
          <div class="flex gap-2">
            <woot-button
              variant="primary"
              @click="openThemeEditor"
            >
              {{ $t('INBOX_MGMT.SETTINGS_POPUP.ENABLE_CHAT_BOT') }}
            </woot-button>
          </div>
        </div>
      </div>
      <div v-else class="text-slate-600">
        {{ $t('INBOX_MGMT.SETTINGS_POPUP.NO_SHOPIFY_STORE') }}
      </div>
    </SettingsSection>
  </div>
</template>

<script>
import SettingsSection from '../../../../../components/SettingsSection.vue';
import { useAlert } from 'dashboard/composables';

export default {
  components: {
    SettingsSection,
  },
  props: {
    inbox: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      shopifyStore: null,
      isUpdating: false,
    };
  },
  async mounted() {
    try {
      const response = await this.$store.dispatch('dashassistShopify/getStoreByInboxId', this.inbox.id);
      console.log('Shopify store response:', response);
      this.shopifyStore = response;
      console.log('Updated shopifyStore:', this.shopifyStore);
    } catch (error) {
      console.error('Error fetching Shopify store:', error);
    }
  },
  methods: {
    openThemeEditor() {
      if (!this.shopifyStore?.shop) return;
      const themeEditorUrl = `https://${this.shopifyStore.shop}/admin/themes/current/editor?context=apps&activateAppId=6937eb7509b3075817543a75cf8bc3af/app-embed`;
      window.open(themeEditorUrl, '_blank');
    },
    async toggleChatBot() {
      if (!this.shopifyStore) return;
      
      this.isUpdating = true;
      try {
        const response = await this.$store.dispatch('dashassistShopify/toggleChatBot', {
          storeId: this.shopifyStore.id,
          enabled: !this.shopifyStore.chat_bot_enabled
        });
        console.log('Toggle chat bot response:', response);
        this.shopifyStore = response;
        useAlert(this.$t('INBOX_MGMT.SETTINGS_POPUP.CHAT_BOT_UPDATED'));
      } catch (error) {
        console.error('Error toggling chat bot:', error);
        useAlert(this.$t('INBOX_MGMT.SETTINGS_POPUP.CHAT_BOT_UPDATE_ERROR'));
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script> 