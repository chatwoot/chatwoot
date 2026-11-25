<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n, I18nT } from 'vue-i18n';
import Twilio from './Twilio.vue';
import ThreeSixtyDialogWhatsapp from './360DialogWhatsapp.vue';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappManualSetup from './WhatsappManualSetup.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';
import WhatsappAccessRequestDialog from '../components/WhatsappAccessRequestDialog.vue';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';
import BaileysWhatsapp from './BaileysWhatsapp.vue';
import ZapiWhatsapp from './ZapiWhatsapp.vue';
import SessionWhatsapp from './session/SessionWhatsapp.vue';
import WhatsappLegacyProviderBanner from '../components/WhatsappLegacyProviderBanner.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useWhatsappSessionProviders } from 'dashboard/composables/useWhatsappSessionProviders';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { META_RESTRICTION_STATUS_URL } from 'dashboard/constants/globals';

const props = defineProps({
  mode: {
    type: String,
    default: 'create',
    validator: value => ['create', 'convert'].includes(value),
  },
  inbox: {
    type: Object,
    default: null,
  },
});

const isConvertMode = computed(() => props.mode === 'convert');

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const accessRequestDialogRef = ref(null);
const {
  isCloudFeatureEnabled,
  isOnChatwootCloud,
  isMetaInboxCreationDisabled,
} = useAccount();

// Latched by the child once it triggers the post-success router.replace.
// Suppresses rendering during the navigation tail so the parent doesn't
// briefly re-render against the new route's query params (which would clear
// `route.query.provider` and flash the provider picker between the success
// toast and the unmount).
const isLeaving = ref(false);
const handleEmbeddedSignupLeaving = () => {
  isLeaving.value = true;
};

const PROVIDER_TYPES = {
  WHATSAPP: 'whatsapp',
  TWILIO: 'twilio',
  WHATSAPP_CLOUD: 'whatsapp_cloud',
  WHATSAPP_EMBEDDED: 'whatsapp_embedded',
  WHATSAPP_MANUAL: 'whatsapp_manual',
  THREE_SIXTY_DIALOG: '360dialog',
  BAILEYS: 'baileys',
  ZAPI: 'zapi',
  NATIVE: 'native',
  UAZAPI: 'uazapi',
};

// Upstream's own gate for the access-request card: the app id alone says embedded signup
// exists on this installation. The fork's check below is the stricter one, and decides
// whether the flow can actually run.
const hasWhatsappAppId = computed(() => {
  return (
    window.chatwootConfig?.whatsappAppId &&
    window.chatwootConfig.whatsappAppId !== 'none'
  );
});

const hasEmbeddedSignupConfig = computed(() => {
  const { whatsappAppId, whatsappConfigurationId } =
    window.chatwootConfig ?? {};
  return (
    whatsappAppId &&
    whatsappAppId !== 'none' &&
    whatsappConfigurationId &&
    whatsappConfigurationId !== 'none'
  );
});

const selectedProvider = computed(() => route.query.provider);

const INBOX_PROVIDER_TO_KEY = {
  whatsapp_cloud: PROVIDER_TYPES.WHATSAPP,
  default: PROVIDER_TYPES.THREE_SIXTY_DIALOG,
  baileys: PROVIDER_TYPES.BAILEYS,
  zapi: PROVIDER_TYPES.ZAPI,
  native: PROVIDER_TYPES.NATIVE,
  uazapi: PROVIDER_TYPES.UAZAPI,
};

const currentProviderKey = computed(() => {
  if (!props.inbox?.provider) return null;
  return INBOX_PROVIDER_TO_KEY[props.inbox.provider] || null;
});

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
    hasEmbeddedSignupConfig.value &&
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

const PROVIDER_CATALOG = computed(() => [
  // The order the picker shows them in: the official API first, then the connection by QR
  // code on the installation's own server, the other official route, the paid QR APIs, and
  // the frozen Baileys last. Providers the server does not offer drop out without moving
  // the rest.
  {
    key: PROVIDER_TYPES.WHATSAPP,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'),
    description: isWhatsappEmbeddedSignupDisabled.value
      ? t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_MANUAL_SETUP_DESC')
      : t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_DESC'),
    icon: 'i-woot-whatsapp',
  },
  {
    key: PROVIDER_TYPES.NATIVE,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.NATIVE'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.NATIVE_DESC'),
    icon: 'i-woot-whatsapp-native',
  },
  {
    key: PROVIDER_TYPES.TWILIO,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO_DESC'),
    icon: 'i-woot-twilio',
  },
  {
    key: PROVIDER_TYPES.UAZAPI,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.UAZAPI'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.UAZAPI_DESC'),
    icon: 'i-woot-uazapi',
  },
  {
    key: PROVIDER_TYPES.ZAPI,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.ZAPI'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.ZAPI_DESC'),
    icon: 'i-woot-zapi',
  },
  {
    key: PROVIDER_TYPES.BAILEYS,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.BAILEYS'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.BAILEYS_DESC'),
    icon: 'i-woot-baileys',
  },
  {
    key: PROVIDER_TYPES.THREE_SIXTY_DIALOG,
    title: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.360_DIALOG'),
    description: t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.360_DIALOG_DESC'),
    icon: 'i-woot-whatsapp',
  },
]);

// The cloud family, which this dashboard has always known statically. 360Dialog is
// intentionally hidden in create mode (URL-reachable only) but offered in convert mode
// where it is a valid target.
const CREATE_PICKER_KEYS = [PROVIDER_TYPES.WHATSAPP, PROVIDER_TYPES.TWILIO];
const CONVERT_PICKER_KEYS = [
  PROVIDER_TYPES.WHATSAPP,
  PROVIDER_TYPES.THREE_SIXTY_DIALOG,
];

// Every session provider comes from the catalog instead, legacy included: eligibility is
// per installation (a connector has to be deployed for `native`, and the deprecation
// withdraws the legacy ones) and per account, and the server is what knows both. Offering
// a choice it would then refuse is worse than not offering it, and withdrawing one
// becomes a server-side change.
const {
  creatableProviders,
  unavailableProviders,
  descriptorFor,
  fetchProviders,
} = useWhatsappSessionProviders();
onMounted(fetchProviders);

const creatableSessionKeys = computed(() =>
  creatableProviders.value.map(({ key }) => key)
);
const selectedDescriptor = computed(() =>
  descriptorFor(selectedProvider.value)
);

// The catalog is what knows a provider is still in beta, so the badge follows the server
// rather than a literal in the label: ending the beta is one field on the descriptor.
// The cloud providers have no descriptor here and answer false, which is what they are.
const isBetaProvider = key => Boolean(descriptorFor(key)?.beta);
// Legacy the same way: the catalog says so, and a provider's withdrawal is a server change.
const isLegacyProvider = key => Boolean(descriptorFor(key)?.legacy);

const unavailableSessionKeys = computed(() =>
  unavailableProviders.value.map(({ key }) => key)
);
const isUnavailableProvider = key => unavailableSessionKeys.value.includes(key);

// Why a provider on the list cannot be opened now: the translated reason, followed by
// what the server last saw go wrong (the statement to run, for a missing schema or
// database), which is technical and stays as the server wrote it.
const unavailableDescription = key => {
  const detail = descriptorFor(key)?.unavailable_detail;
  const reason = t(
    'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.NATIVE_CONNECTOR_NOT_RUNNING'
  );
  return detail ? `${reason} ${detail}` : reason;
};

const availableProviders = computed(() => {
  const allowed = [
    ...(isConvertMode.value ? CONVERT_PICKER_KEYS : CREATE_PICKER_KEYS),
    ...creatableSessionKeys.value,
    ...unavailableSessionKeys.value,
  ];
  return PROVIDER_CATALOG.value
    .filter(p => allowed.includes(p.key))
    .filter(p => !isConvertMode.value || p.key !== currentProviderKey.value);
});

// What this screen could actually open, not only what the catalog offers the account: a
// conversion leaves out the inbox's own provider, so a native inbox being converted to a
// legacy one has no native target to recommend.
const isNativeAvailable = computed(
  () =>
    !isUnavailableProvider(PROVIDER_TYPES.NATIVE) &&
    availableProviders.value.some(({ key }) => key === PROVIDER_TYPES.NATIVE)
);

const currentProviderLabel = computed(() => {
  if (!isConvertMode.value || !currentProviderKey.value) return '';
  return (
    PROVIDER_CATALOG.value.find(({ key }) => key === currentProviderKey.value)
      ?.title || ''
  );
});

const isValidSelectedProvider = computed(() => {
  if (!selectedProvider.value) return false;
  // In create mode, allow the embedded-signup manual fallback link and the
  // legacy-URL path to 360Dialog even though neither is in the picker.
  if (!isConvertMode.value) {
    if (selectedProvider.value === PROVIDER_TYPES.WHATSAPP_MANUAL) return true;
    if (selectedProvider.value === PROVIDER_TYPES.THREE_SIXTY_DIALOG)
      return true;
  }
  // Listed so the picker can say why, never opened: `?provider=native` typed by hand
  // while no connector runs stays on the picker.
  if (isUnavailableProvider(selectedProvider.value)) return false;
  return availableProviders.value.some(
    ({ key }) => key === selectedProvider.value
  );
});

const showProviderSelection = computed(
  () => !isLeaving.value && !isValidSelectedProvider.value
);
const showConfiguration = computed(
  () => !isLeaving.value && isValidSelectedProvider.value
);

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

const isManualSetup = computed(
  () =>
    showConfiguration.value && shouldShowCloudWhatsapp(selectedProvider.value)
);

const handleManualLinkClick = () => {
  selectProvider(PROVIDER_TYPES.WHATSAPP_MANUAL);
};

const requestEmbeddedSignupAccess = () => {
  accessRequestDialogRef.value.open();
};
</script>

<template>
  <div class="col-span-6 w-full h-full min-h-0 overflow-y-auto p-6">
    <WhatsappAccessRequestDialog ref="accessRequestDialogRef" />
    <div v-if="isManualSetup">
      <div
        v-if="shouldShowEmbeddedSignupAccessRequest"
        class="w-full p-5 mb-6 border rounded-xl border-n-weak bg-n-surface-2 text-start"
      >
        <div class="flex flex-wrap items-center gap-3">
          <div
            class="flex items-center justify-center flex-shrink-0 rounded-lg size-7 bg-n-slate-3"
          >
            <Icon icon="i-woot-whatsapp" class="size-5 text-n-slate-11" />
          </div>
          <span class="flex-1 min-w-0 text-heading-2 text-n-slate-12">
            {{
              $t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.TITLE')
            }}
          </span>
          <Button
            solid
            blue
            sm
            class="flex-shrink-0"
            icon="i-lucide-life-buoy"
            :label="
              $t(
                'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.BUTTON'
              )
            "
            @click="requestEmbeddedSignupAccess"
          />
        </div>
        <p class="mt-2 ms-10 max-w-3xl text-body-main text-n-slate-11">
          {{
            $t(
              'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.DESCRIPTION'
            )
          }}
        </p>
      </div>
      <Banner
        v-if="
          isWhatsappEmbeddedSignupDisabled &&
          selectedProvider === PROVIDER_TYPES.WHATSAPP_MANUAL
        "
        color="amber"
        class="w-full mb-6"
      >
        <div class="flex items-start gap-3 text-start">
          <Icon
            icon="i-lucide-triangle-alert"
            class="flex-shrink-0 size-4 mt-0.5"
          />
          <span>
            {{ $t('INBOX_MGMT.ADD.WHATSAPP.API.MANUAL_RESTRICTION_WARNING') }}
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
      <!-- The guided setup creates an inbox. Converting keeps the fork's form, which knows the inbox it is converting. -->
      <CloudWhatsapp v-if="isConvertMode" :mode="mode" :inbox="inbox" />
      <WhatsappManualSetup v-else />
    </div>

    <div v-else-if="showProviderSelection">
      <div class="mb-10 text-left">
        <h1 class="mb-2 text-lg font-medium text-n-slate-12">
          {{
            isConvertMode
              ? $t('INBOX_MGMT.CONVERT.SELECT_PROVIDER_TITLE')
              : $t('INBOX_MGMT.ADD.WHATSAPP.SELECT_PROVIDER.TITLE')
          }}
        </h1>
        <p class="text-sm leading-relaxed text-n-slate-11">
          {{
            isConvertMode
              ? $t('INBOX_MGMT.CONVERT.SELECT_PROVIDER_DESCRIPTION', {
                  inboxName: inbox?.name,
                  currentProvider: currentProviderLabel,
                })
              : providerSelectionDescription
          }}
        </p>
      </div>

      <div
        class="grid max-w-3xl grid-cols-1 gap-6 xs:grid-cols-2 sm:grid-cols-3"
      >
        <ChannelSelector
          v-for="provider in availableProviders"
          :key="provider.key"
          :title="provider.title"
          :description="
            isUnavailableProvider(provider.key)
              ? unavailableDescription(provider.key)
              : provider.description
          "
          :icon="provider.icon"
          :is-beta="isBetaProvider(provider.key)"
          :is-legacy="isLegacyProvider(provider.key)"
          :disabled="isUnavailableProvider(provider.key)"
          @click="selectProvider(provider.key)"
        />
      </div>
    </div>

    <div v-else-if="showConfiguration">
      <WhatsappLegacyProviderBanner
        v-if="isLegacyProvider(selectedProvider)"
        :native-available="isNativeAvailable"
        class="mb-4"
        @use-native="selectProvider(PROVIDER_TYPES.NATIVE)"
      />
      <div class="px-6 py-5 rounded-2xl border border-n-weak">
        <!-- Show embedded signup if app ID is configured -->
        <div v-if="shouldShowWhatsappEmbeddedSignup">
          <WhatsappEmbeddedSignup
            :mode="mode"
            :inbox="inbox"
            :is-disabled="isWhatsappEmbeddedSignupDisabled"
            :show-restriction-alert="isWhatsappEmbeddedSignupDisabled"
            :restriction-status-url="META_RESTRICTION_STATUS_URL"
            @leaving="handleEmbeddedSignupLeaving"
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

        <!-- Other providers -->
        <Twilio
          v-else-if="selectedProvider === PROVIDER_TYPES.TWILIO"
          type="whatsapp"
        />
        <ThreeSixtyDialogWhatsapp
          v-else-if="selectedProvider === PROVIDER_TYPES.THREE_SIXTY_DIALOG"
          :mode="mode"
          :inbox="inbox"
        />
        <BaileysWhatsapp
          v-else-if="selectedProvider === PROVIDER_TYPES.BAILEYS"
          :mode="mode"
          :inbox="inbox"
        />
        <ZapiWhatsapp
          v-else-if="selectedProvider === PROVIDER_TYPES.ZAPI"
          :mode="mode"
          :inbox="inbox"
        />
        <SessionWhatsapp
          v-else-if="selectedDescriptor && !selectedDescriptor.legacy"
          :descriptor="selectedDescriptor"
          :mode="mode"
          :inbox="inbox"
        />
      </div>
    </div>
  </div>
</template>
