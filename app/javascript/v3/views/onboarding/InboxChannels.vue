<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import OnboardingBaseModal from './BaseModal.vue';
import ChannelItem from 'dashboard/components/widgets/ChannelItem.vue';
import PageHeader from '../../../dashboard/routes/dashboard/settings/SettingsSubPageHeader.vue';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const route = useRoute();
const selectedChannel = ref(null);

const globalConfig = computed(() => store.getters['globalConfig/get']);
const account = computed(() =>
  store.getters['accounts/getAccount'](store.getters.getCurrentAccountId)
);

const channelList = computed(() => {
  const { apiChannelName, apiChannelThumbnail } = globalConfig.value;
  return [
    { key: 'website', name: 'Website' },
    { key: 'facebook', name: 'Messenger' },
    { key: 'whatsapp', name: 'WhatsApp' },
    { key: 'sms', name: 'SMS' },
    { key: 'email', name: 'Email' },
    {
      key: 'api',
      name: apiChannelName || 'API',
      thumbnail: apiChannelThumbnail,
    },
    { key: 'telegram', name: 'Telegram' },
    { key: 'line', name: 'Line' },
    { key: 'instagram', name: 'Instagram' },
  ];
});

const selectChannel = channel => {
  selectedChannel.value = channel;
  const channelKey = typeof channel === 'string' ? channel : channel.key;
  if (!channelKey) {
    return;
  }
  router
    .push({
      name: 'onboarding_setup_inbox_configure',
      params: { channel: channelKey },
    })
    .catch(err => {});
};

const skipToNextStep = async () => {
  await store.dispatch('accounts/update', {
    onboarding_step: 'true',
  });
  const accountId = route.params.accountId;
  if (accountId) {
    window.location = `/app/accounts/${accountId}/dashboard`;
  } else {
    window.location = DEFAULT_REDIRECT_URL;
  }
};
</script>

<template>
  <OnboardingBaseModal
    :title="$t('INBOX_MGMT.ADD.AUTH.TITLE')"
    :subtitle="$t('INBOX_MGMT.ADD.AUTH.DESC_SHORT')"
  >
    <div class="space-y-6">
      <PageHeader :header-title="$t('INBOX_MGMT.ADD.AUTH.TITLE')" />

      <div class="grid">
        <ChannelItem
          v-for="channel in channelList"
          :key="channel.key"
          :channel="channel"
          :enabled-features="account.features"
          @channel-item-click="selectChannel(channel)"
        />
      </div>

      <button type="button" class="button clear w-39" @click="skipToNextStep">
        {{ $t('START_ONBOARDING.INVITE_TEAM.SKIP') }}
      </button>
    </div>

    <router-view v-slot="{ Component }">
      <transition name="fade">
        <component :is="Component" :key="$route.fullPath" />
      </transition>
    </router-view>
  </OnboardingBaseModal>
</template>

<style scoped>
.grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 1rem;
}

@media (max-width: 768px) {
  .grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
