<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n, I18nT } from 'vue-i18n';
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { META_RESTRICTION_STATUS_URL } from 'dashboard/constants/globals';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const {
  isCloudFeatureEnabled,
  isOnChatwootCloud,
  isMetaInboxCreationDisabled,
} = useAccount();

const PROVIDER_TYPES = {
  WHATSAPP: 'whatsapp',
  TWILIO: 'twilio',
  WHATSAPP_CLOUD: 'whatsapp_cloud',
  WHATSAPP_EMBEDDED: 'whatsapp_embedded',
  WHATSAPP_MANUAL: 'whatsapp_manual',
  THREE_SIXTY_DIALOG: '360dialog',
};

const hasWhatsappAppId = computed(() => {
  return (
    window.chatwootConfig?.whatsappAppId &&
    window.chatwootConfig.whatsappAppId !== 'none'
  );
});

const selectedProvider = computed(() => route.query.provider);

const showProviderSelection = computed(() => !selectedProvider.value);

const showConfiguration = computed(() => Boolean(selectedProvider.value));
const isWhatsappEmbeddedSignupDisabled = computed(
  () => isMetaInboxCreationDisabled.value
);

const isWhatsappEmbeddedSignupFeatureEnabled = computed(
  () =>
    !isOnChatwootCloud.value ||
    isCloudFeatureEnabled(FEATURE_FLAGS.WHATSAPP_EMBEDDED_SIGNUP_FLOW)
);

const shouldShowWhatsappEmbeddedSignup = computed(() => {
  return (
    selectedProvider.value === PROVIDER_TYPES.WHATSAPP &&
    hasWhatsappAppId.value &&
    isWhatsappEmbeddedSignupFeatureEnabled.value
  );
});

const shouldShowEmbeddedSignupAccessRequest = computed(() => {
  return (
    selectedProvider.value === PROVIDER_TYPES.WHATSAPP &&
    isOnChatwootCloud.value &&
    hasWhatsappAppId.value &&
    !isWhatsappEmbeddedSignupFeatureEnabled.value &&
    !isWhatsappEmbeddedSignupDisabled.value
  );
});

const availableProviders = computed(() => [
  {
    key: PROVIDER_TYPES.WHATSAPP,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'),
    description: isWhatsappEmbeddedSignupDisabled.value
      ? t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_MANUAL_SETUP_DESC')
      : t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_DESC'),
    icon: 'i-woot-whatsapp',
  },
  {
    key: PROVIDER_TYPES.TWILIO,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO_DESC'),
    icon: 'i-woot-twilio',
  },
]);

const providerSelectionDescription = computed(() =>
  isWhatsappEmbeddedSignupDisabled.value
    ? t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.RESTRICTION_DESCRIPTION')
    : t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.DESCRIPTION')
);

const selectProvider = providerValue => {
  const targetProvider =
    providerValue === PROVIDER_TYPES.WHATSAPP &&
    isWhatsappEmbeddedSignupDisabled.value
      ? PROVIDER_TYPES.WHATSAPP_MANUAL
      : providerValue;

  router.push({
    name: route.name,
    params: route.params,
    query: { provider: targetProvider },
  });
};

const shouldShowCloudWhatsapp = provider => {
  return (
    provider === PROVIDER_TYPES.WHATSAPP_MANUAL ||
    (provider === PROVIDER_TYPES.WHATSAPP &&
      !shouldShowWhatsappEmbeddedSignup.value)
  );
};

const handleManualLinkClick = () => {
  selectProvider(PROVIDER_TYPES.WHATSAPP_MANUAL);
};

const requestEmbeddedSignupAccess = () => {
  window.$chatwoot?.toggle();
};
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <div v-if="showProviderSelection">
      <div class="mb-10 text-left">
        <h1 class="mb-2 text-lg font-medium text-n-slate-12">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.TITLE') }}
        </h1>
        <p class="text-sm leading-relaxed text-n-slate-11">
          {{ providerSelectionDescription }}
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
        <div v-if="shouldShowWhatsappEmbeddedSignup">
          <WhatsappEmbeddedSignup
            :is-disabled="isWhatsappEmbeddedSignupDisabled"
            :show-restriction-alert="isWhatsappEmbeddedSignupDisabled"
            :restriction-status-url="META_RESTRICTION_STATUS_URL"
          />

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
        <div v-else-if="shouldShowCloudWhatsapp(selectedProvider)">
          <div
            v-if="shouldShowEmbeddedSignupAccessRequest"
            class="w-full p-4 mb-6 border rounded-xl border-n-weak bg-n-solid-2"
          >
            <div class="flex flex-col gap-4 sm:flex-row sm:items-start">
              <div
                class="flex items-center justify-center flex-shrink-0 rounded-lg size-9 bg-n-blue-3"
              >
                <Icon icon="i-woot-whatsapp" class="size-5 text-n-slate-10" />
              </div>
              <div class="flex-1 min-w-0 text-start">
                <div class="font-medium text-n-slate-12">
                  {{
                    $t(
                      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.TITLE'
                    )
                  }}
                </div>
                <p class="mt-1 text-sm leading-5 text-n-slate-11">
                  {{
                    $t(
                      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.DESCRIPTION'
                    )
                  }}
                </p>
                <p class="mt-2 text-xs leading-5 text-n-slate-10">
                  {{
                    $t(
                      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.FOOTNOTE'
                    )
                  }}
                </p>
              </div>
              <Button
                solid
                blue
                sm
                class="self-start flex-shrink-0 sm:mt-0.5"
                icon="i-lucide-life-buoy"
                :label="
                  $t(
                    'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.BUTTON'
                  )
                "
                @click="requestEmbeddedSignupAccess"
              />
            </div>
          </div>
          <Banner
            v-if="isWhatsappEmbeddedSignupDisabled"
            color="amber"
            class="w-full mb-6"
          >
            <div class="flex items-start gap-3 text-start">
              <Icon
                icon="i-lucide-triangle-alert"
                class="flex-shrink-0 size-4 mt-0.5"
              />
              <span>
                {{
                  $t('INBOX_MGMT.ADD.WHATSAPP.API.MANUAL_RESTRICTION_WARNING')
                }}
                <a
                  :href="META_RESTRICTION_STATUS_URL"
                  class="link underline"
                  rel="noopener noreferrer nofollow"
                  target="_blank"
                >
                  {{ $t('INBOX_MGMT.ADD.WHATSAPP.API.STATUS_LINK') }}
                </a>
              </span>
            </div>
          </Banner>
          <CloudWhatsapp />
        </div>

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
