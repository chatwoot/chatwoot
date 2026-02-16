<script setup>
import { computed, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n, I18nT } from 'vue-i18n';
import whatsappSettingsAPI from 'dashboard/api/whatsappSettings';
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Icon from 'next/icon/Icon.vue';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const accountWhatsappSettings = ref(null);
const isLoadingSettings = ref(true);

const PROVIDER_TYPES = {
  WHATSAPP: 'whatsapp',
  TWILIO: 'twilio',
  WHATSAPP_CLOUD: 'whatsapp_cloud',
  WHATSAPP_EMBEDDED: 'whatsapp_embedded',
  WHATSAPP_MANUAL: 'whatsapp_manual',
  THREE_SIXTY_DIALOG: '360dialog',
};

// Load account WhatsApp settings on mount
const loadAccountWhatsappSettings = async () => {
  try {
    const response = await whatsappSettingsAPI.get();
    accountWhatsappSettings.value = response.data;
  } catch (error) {
    accountWhatsappSettings.value = null;
  } finally {
    isLoadingSettings.value = false;
  }
};

onMounted(() => {
  loadAccountWhatsappSettings();
});

// Check account-level settings first, then fall back to global config
const hasWhatsappAppId = computed(() => {
  // Priority 1: Account-level settings
  if (accountWhatsappSettings.value?.app_id) {
    return true;
  }

  // Priority 2: Global config
  return (
    window.chatwootConfig?.whatsappAppId &&
    window.chatwootConfig.whatsappAppId !== 'none'
  );
});

const selectedProvider = computed(() => route.query.provider);

const showProviderSelection = computed(() => !selectedProvider.value);

const showConfiguration = computed(() => Boolean(selectedProvider.value));

const availableProviders = computed(() => [
  {
    key: PROVIDER_TYPES.WHATSAPP,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_DESC'),
    icon: 'i-woot-whatsapp',
  },
  {
    key: PROVIDER_TYPES.TWILIO,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO_DESC'),
    icon: 'i-woot-twilio',
  },
]);

const selectProvider = providerValue => {
  router.push({
    name: route.name,
    params: route.params,
    query: { provider: providerValue },
  });
};

const shouldShowCloudWhatsapp = provider => {
  return (
    provider === PROVIDER_TYPES.WHATSAPP_MANUAL ||
    (provider === PROVIDER_TYPES.WHATSAPP && !hasWhatsappAppId.value)
  );
};

const handleManualLinkClick = () => {
  selectProvider(PROVIDER_TYPES.WHATSAPP_MANUAL);
};
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <!-- Rate Limit Warning Banner -->
    <Banner color="amber" class="mb-6">
      <div class="flex items-start gap-3">
        <Icon
          icon="i-lucide-alert-triangle"
          class="size-5 flex-shrink-0 mt-0.5"
        />
        <div>
          <h4 class="font-medium mb-1">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.RATE_LIMIT_WARNING.TITLE') }}
          </h4>
          <p class="text-sm mb-2">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.RATE_LIMIT_WARNING.DESCRIPTION') }}
          </p>
          <ul class="text-sm list-disc list-inside mb-2 space-y-0.5">
            <li>
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.RATE_LIMIT_WARNING.TIPS.TIP_1') }}
            </li>
            <li>
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.RATE_LIMIT_WARNING.TIPS.TIP_2') }}
            </li>
            <li>
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.RATE_LIMIT_WARNING.TIPS.TIP_3') }}
            </li>
          </ul>
          <p class="text-xs opacity-80">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.RATE_LIMIT_WARNING.FOOTER') }}
          </p>
        </div>
      </div>
    </Banner>

    <div v-if="showProviderSelection">
      <div class="mb-10 text-left">
        <h1 class="mb-2 text-lg font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.TITLE') }}
        </h1>
        <p class="text-sm leading-relaxed text-n-slate-11">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.DESCRIPTION') }}
        </p>
      </div>

      <div class="flex gap-6 justify-start">
        <ChannelSelector
          v-for="provider in availableProviders"
          :key="provider.key"
          :title="provider.title"
          :description="provider.description"
          :icon="provider.icon"
          @click="selectProvider(provider.key)"
        />
      </div>
    </div>

    <div v-else-if="showConfiguration">
      <div class="px-6 py-5 rounded-2xl border border-n-weak">
        <!-- Show embedded signup if app ID is configured -->
        <div
          v-if="
            hasWhatsappAppId && selectedProvider === PROVIDER_TYPES.WHATSAPP
          "
        >
          <WhatsappEmbeddedSignup />

          <!-- Manual setup fallback option -->
          <div class="pt-6 mt-6 border-t border-n-weak">
            <I18nT
              keypath="INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.MANUAL_FALLBACK"
              tag="p"
              class="text-sm text-n-slate-11"
            >
              <template #link>
                <a
                  href="#"
                  class="underline text-n-brand"
                  @click.prevent="handleManualLinkClick"
                >
                  {{
                    $t(
                      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.MANUAL_LINK_TEXT'
                    )
                  }}
                </a>
              </template>
            </I18nT>
          </div>
        </div>

        <!-- Show manual setup -->
        <CloudWhatsapp v-else-if="shouldShowCloudWhatsapp(selectedProvider)" />

        <!-- Other providers -->
        <Twilio
          v-else-if="selectedProvider === PROVIDER_TYPES.TWILIO"
          type="whatsapp"
        />
        <ThreeSixtyDialogWhatsapp
          v-else-if="selectedProvider === PROVIDER_TYPES.THREE_SIXTY_DIALOG"
        />
        <CloudWhatsapp v-else />
      </div>
    </div>
  </div>
</template>
