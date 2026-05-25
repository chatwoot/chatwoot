<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { useHelpCenterGenerationStore } from 'dashboard/stores/helpCenterGeneration';
import { ONBOARDING_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import OnboardingLayout from './OnboardingLayout.vue';
import OnboardingSection from './OnboardingSection.vue';
import InboxChannelsDialog from './InboxChannelsDialog.vue';
import ChannelRow from './ChannelRow.vue';
import WebWidgetCreationStatus from './WebWidgetCreationStatus.vue';
import HelpCenterCreationStatus from './HelpCenterCreationStatus.vue';
import { useChannelConnect } from './useChannelConnect';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { accountId, currentAccount, finishOnboarding } = useAccount();
const { isEnterprise } = useConfig();
const { connectViaOAuth } = useChannelConnect();

const helpCenterGenerationId = computed(
  () => currentAccount.value?.custom_attributes?.help_center_generation_id
);

const isSubmitting = ref(false);

const integrations = useMapGetter('integrations/getAppIntegrations');

const FEATURED_APP_IDS = ['slack', 'linear'];

const featuredApps = computed(() =>
  FEATURED_APP_IDS.map(id =>
    integrations.value.find(item => item.id === id)
  ).filter(Boolean)
);

// Brand-info socials are populated by the website branding service after
// signup. Keys here mirror SocialLinkParser::SOCIAL_DOMAIN_MAP.
const SOCIAL_PLATFORMS = {
  whatsapp: { label: 'WhatsApp', channelType: 'Channel::Whatsapp' },
  facebook: { label: 'Facebook', channelType: 'Channel::FacebookPage' },
  line: { label: 'Line', channelType: 'Channel::Line' },
  instagram: { label: 'Instagram', channelType: 'Channel::Instagram' },
  telegram: { label: 'Telegram', channelType: 'Channel::Telegram' },
  tiktok: { label: 'TikTok', channelType: 'Channel::Tiktok' },
};

const extractHandle = ({ type, url }) => {
  try {
    const { pathname } = new URL(url);
    const path = pathname.replace(/^\/+|\/+$/g, '');
    if (type === 'whatsapp') {
      const digits = path.replace(/\D/g, '');
      return digits ? `+${digits}` : '';
    }
    if (type === 'line') return path;
    return path.startsWith('@') ? path : `@${path}`;
  } catch {
    return '';
  }
};

const brandSocials = computed(
  () => currentAccount.value?.custom_attributes?.brand_info?.socials || []
);

const connectedChannels = computed(() =>
  brandSocials.value
    .filter(social => SOCIAL_PLATFORMS[social.type] && social.url)
    .map(social => ({
      type: social.type,
      handle: extractHandle(social),
      label: SOCIAL_PLATFORMS[social.type].label,
      inbox: { channel_type: SOCIAL_PLATFORMS[social.type].channelType },
    }))
);

// Mailbox provider inferred from the signup domain's MX records by the website
// branding service. Values mirror Channel::Email#provider so ChannelIcon can
// render the matching Gmail/Outlook brand.
const EMAIL_PROVIDERS = {
  google: { label: 'Gmail' },
  microsoft: { label: 'Outlook' },
};

const detectedEmailChannel = computed(() => {
  const brandInfo = currentAccount.value?.custom_attributes?.brand_info;
  const provider = brandInfo?.email_provider;
  if (!EMAIL_PROVIDERS[provider]) return null;

  const email = brandInfo?.email;
  return {
    type: 'email',
    handle: email || '',
    label: EMAIL_PROVIDERS[provider].label,
    inbox: { channel_type: 'Channel::Email', provider },
  };
});

const displayedChannels = computed(() =>
  [detectedEmailChannel.value, ...connectedChannels.value].filter(Boolean)
);

const remainingChannels = computed(() => {
  const connectedTypes = new Set(connectedChannels.value.map(c => c.type));
  return Object.entries(SOCIAL_PLATFORMS)
    .filter(([type]) => !connectedTypes.has(type))
    .slice(0, 3)
    .map(([type, { label, channelType }]) => ({
      type,
      label,
      inbox: { channel_type: channelType },
    }));
});

const channelsDialogRef = ref(null);

const connectedChannelTypes = computed(() => [
  ...connectedChannels.value.map(c => c.type),
  // Live Chat / website inbox is always created during account setup.
  'website',
]);

onMounted(() => {
  store.dispatch('integrations/get');
  useHelpCenterGenerationStore().hydrate(helpCenterGenerationId.value);
  useTrack(ONBOARDING_EVENTS.INBOX_SETUP_VISITED);
});

const completeOnboarding = async event => {
  if (isSubmitting.value) return;

  isSubmitting.value = true;
  try {
    // Declare the step we're completing so the controller only clears it when
    // the stored step still matches (idempotent). setUser then refreshes the
    // auth store so the router guard sees the cleared step and lets us in.
    await finishOnboarding({ onboarding_step: 'inbox_setup' });
    useTrack(event);
    await store.dispatch('setUser');
    router.push({ name: 'home', params: { accountId: accountId.value } });
  } catch {
    useAlert(t('ONBOARDING_INBOX_SETUP.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const handleContinue = () =>
  completeOnboarding(ONBOARDING_EVENTS.INBOX_SETUP_COMPLETED);
const handleSkip = () =>
  completeOnboarding(ONBOARDING_EVENTS.INBOX_SETUP_SKIPPED);
const openChannelsDialog = () => channelsDialogRef.value?.open();

// Gmail and Outlook connect via OAuth; other channels are no-ops for now (only
// email channels carry an inbox provider).
const connectChannel = channel => connectViaOAuth(channel.inbox?.provider);
</script>

<template>
  <OnboardingLayout
    :greeting="t('ONBOARDING_INBOX_SETUP.GREETING')"
    :subtitle="t('ONBOARDING_INBOX_SETUP.SUBTITLE')"
    :continue-label="t('ONBOARDING_INBOX_SETUP.CONTINUE')"
    :skip-label="t('ONBOARDING_INBOX_SETUP.SKIP')"
    :is-loading="isSubmitting"
    @continue="handleContinue"
    @skip="handleSkip"
  >
    <template #greeting-icon>
      <Icon icon="i-lucide-wrench" class="size-4 text-n-slate-7" />
    </template>

    <OnboardingSection
      :title="t('ONBOARDING_INBOX_SETUP.CREATED_FOR_YOU.TITLE')"
      icon="i-lucide-sparkles"
    >
      <WebWidgetCreationStatus />
      <HelpCenterCreationStatus v-if="isEnterprise && helpCenterGenerationId" />
    </OnboardingSection>

    <OnboardingSection
      :title="t('ONBOARDING_INBOX_SETUP.CHANNELS.TITLE')"
      icon="i-lucide-inbox"
    >
      <ChannelRow
        v-for="(channel, index) in displayedChannels"
        :key="channel.type"
        :channel="channel"
        :class="{ 'border-t border-n-weak': index > 0 }"
        @connect="connectChannel"
      />
      <div
        class="flex items-center justify-between gap-3 px-3 py-3"
        :class="{ 'border-t border-n-weak': displayedChannels.length > 0 }"
      >
        <div class="flex items-center gap-2 min-w-0">
          <Icon
            icon="i-lucide-info"
            class="size-4 text-n-slate-9 flex-shrink-0"
          />
          <span class="text-sm text-n-slate-11">
            {{ t('ONBOARDING_INBOX_SETUP.CHANNELS.MORE_CHANNELS_NOTE') }}
          </span>
        </div>
        <div
          v-if="remainingChannels.length"
          class="flex items-center gap-2 flex-shrink-0"
        >
          <div class="flex items-center gap-1">
            <ChannelIcon
              v-for="channel in remainingChannels"
              :key="channel.type"
              :inbox="channel.inbox"
              use-image
              class="size-4"
            />
          </div>
          <span class="w-px h-4 bg-n-weak" />
          <button
            type="button"
            class="text-sm font-medium text-n-blue-11 hover:underline"
            @click="openChannelsDialog"
          >
            {{ t('ONBOARDING_INBOX_SETUP.CHANNELS.VIEW_ALL') }}
          </button>
        </div>
      </div>
    </OnboardingSection>

    <OnboardingSection
      :title="t('ONBOARDING_INBOX_SETUP.APPS.TITLE')"
      icon="i-lucide-blocks"
      bare
    >
      <div class="grid grid-cols-2 gap-3">
        <div
          v-for="app in featuredApps"
          :key="app.id"
          class="border border-n-weak rounded-xl bg-n-surface-1 p-3 flex flex-col gap-2"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <img
                :src="`/dashboard/images/integrations/${app.id}.png`"
                :alt="app.name"
                class="size-5 object-contain block dark:hidden"
              />
              <img
                :src="`/dashboard/images/integrations/${app.id}-dark.png`"
                :alt="app.name"
                class="size-5 object-contain hidden dark:block"
              />
              <span class="text-sm font-medium text-n-slate-12">
                {{ app.name }}
              </span>
            </div>
            <span v-if="app.enabled" class="text-sm text-n-slate-11">
              {{ t('INTEGRATION_APPS.STATUS.ENABLED') }}
            </span>
            <button
              v-else
              type="button"
              class="text-sm font-medium text-n-blue-11 hover:underline"
            >
              {{ t('INTEGRATION_APPS.CONFIGURE') }}
            </button>
          </div>
          <p class="text-xs leading-relaxed text-n-slate-11">
            {{ app.description }}
          </p>
        </div>
      </div>
    </OnboardingSection>
  </OnboardingLayout>
  <InboxChannelsDialog
    ref="channelsDialogRef"
    :connected-types="connectedChannelTypes"
    @continue="handleContinue"
    @skip="handleSkip"
  />
</template>
