<script setup>
import { ref, computed } from 'vue';
import ForwardToOption from './emailChannels/ForwardToOption.vue';
import Microsoft from './emailChannels/Microsoft.vue';
import Google from './emailChannels/Google.vue';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';
import PageHeader from '../../SettingsSubPageHeader.vue';

import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

const provider = ref('');

const getters = useStoreGetters();
const { t } = useI18n();

const globalConfig = getters['globalConfig/get'];
const isAChatwootInstance = getters['globalConfig/isAChatwootInstance'];

const emailProviderList = computed(() => {
  return [
    {
      title: t('INBOX_MGMT.EMAIL_PROVIDERS.MICROSOFT.TITLE'),
      description: t('INBOX_MGMT.EMAIL_PROVIDERS.MICROSOFT.DESCRIPTION'),
      isEnabled: !!globalConfig.value.azureAppId,
      key: 'microsoft',
      icon: 'i-woot-outlook',
    },
    {
      title: t('INBOX_MGMT.EMAIL_PROVIDERS.GOOGLE.TITLE'),
      description: t('INBOX_MGMT.EMAIL_PROVIDERS.GOOGLE.DESCRIPTION'),
      isEnabled: !!window.chatwootConfig.googleOAuthClientId,
      key: 'google',
      icon: 'i-woot-gmail',
    },
    {
      title: t('INBOX_MGMT.EMAIL_PROVIDERS.OTHER_PROVIDERS.TITLE'),
      description: t('INBOX_MGMT.EMAIL_PROVIDERS.OTHER_PROVIDERS.DESCRIPTION'),
      isEnabled: true,
      key: 'other_provider',
      icon: 'i-woot-mail',
    },
  ].filter(providerConfig => {
    if (isAChatwootInstance.value) {
      return true;
    }
    return providerConfig.isEnabled;
  });
});

function onClick(emailProvider) {
  if (emailProvider.isEnabled) {
    provider.value = emailProvider.key;
  }
}
</script>

<template>
  <div v-if="!provider" class="h-full w-full p-6 col-span-6">
    <PageHeader
      class="max-w-4xl"
      :header-title="$t('INBOX_MGMT.ADD.EMAIL_PROVIDER.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.EMAIL_PROVIDER.DESCRIPTION')"
    />
    <div class="grid max-w-3xl grid-cols-4 gap-6 mx-0 mt-6">
      <ChannelSelector
        v-for="emailProvider in emailProviderList"
        :key="emailProvider.key"
        :title="emailProvider.title"
        :description="emailProvider.description"
        :icon="emailProvider.icon"
        :disabled="!emailProvider.isEnabled"
        @click="() => onClick(emailProvider)"
      />
    </div>
  </div>
  <Microsoft v-else-if="provider === 'microsoft'" />
  <Google v-else-if="provider === 'google'" />
  <ForwardToOption v-else-if="provider === 'other_provider'" />
</template>
