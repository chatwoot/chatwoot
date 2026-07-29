<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { ONBOARDING_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import OnboardingLayout from './shared/OnboardingLayout.vue';
import OnboardingSection from './shared/OnboardingSection.vue';
import InboxChannelsDialog from './inbox-setup/InboxChannelsDialog.vue';
import InboxChannelsFooter from './inbox-setup/InboxChannelsFooter.vue';
import ChannelRow from './inbox-setup/ChannelRow.vue';
import WebWidgetCreationStatus from './inbox-setup/WebWidgetCreationStatus.vue';
import HelpCenterCreationStatus from './inbox-setup/HelpCenterCreationStatus.vue';
import { CHANNEL_TYPES } from 'dashboard/helper/inbox';
import { useChannelConnect } from './inbox-setup/useChannelConnect';
import { useDetectedChannels } from './inbox-setup/useDetectedChannels';
import { DIALOG_CHANNELS } from './inbox-setup/constants';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { accountId, currentAccount, finishOnboarding } = useAccount();
const { isEnterprise } = useConfig();
const { connectViaOAuth, connectWhatsapp } = useChannelConnect();

const helpCenterGenerationId = computed(
  () => currentAccount.value?.custom_attributes?.help_center_generation_id
);

const isSubmitting = ref(false);

const inboxes = useMapGetter('inboxes/getInboxes');

const {
  displayedChannels,
  remainingChannels,
  connectedInbox,
  hasDetectedChannels,
} = useDetectedChannels();

const channelsDialogRef = ref(null);

// The initial inboxes fetch happens in WebWidgetCreationStatus, which polls
// `inboxes/get` from its own mount — no need to dispatch it here too.
onMounted(() => {
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
const refetchInboxes = () => store.dispatch('inboxes/get');

// WhatsApp connects via Meta's embedded-signup popup; the DIALOG_CHANNELS open
// the channels dialog preselected to their in-dialog step; the rest go through
// the redirect OAuth flow (Gmail/Outlook keyed by email provider, Instagram by
// channel type).
const connectChannel = channel => {
  if (channel.type === CHANNEL_TYPES.WHATSAPP) {
    connectWhatsapp();
    return;
  }
  if (DIALOG_CHANNELS.includes(channel.type)) {
    channelsDialogRef.value?.open(channel.type);
    return;
  }
  connectViaOAuth(channel.inbox?.provider || channel.type);
};
</script>

<template>
  <div>
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
        <div class="divide-y divide-n-weak">
          <WebWidgetCreationStatus />
          <HelpCenterCreationStatus
            v-if="isEnterprise && helpCenterGenerationId"
          />
        </div>
      </OnboardingSection>

      <OnboardingSection
        :title="t('ONBOARDING_INBOX_SETUP.CHANNELS.TITLE')"
        icon="i-lucide-inbox"
      >
        <div
          v-if="hasDetectedChannels"
          class="flex items-center gap-2 p-3 border-b border-dashed border-n-strong"
        >
          <Icon
            icon="i-lucide-lightbulb"
            class="size-4 text-n-slate-11 flex-shrink-0"
          />
          <span class="flex-1 min-w-0 text-body-main text-n-slate-11">
            {{ t('ONBOARDING_INBOX_SETUP.CHANNELS.HEADER') }}
          </span>
        </div>
        <ChannelRow
          v-for="channel in displayedChannels"
          :key="channel.type"
          :channel="channel"
          :connected-inbox="connectedInbox(channel)"
          @connect="connectChannel"
        />
        <InboxChannelsFooter
          :remaining-channels="remainingChannels"
          @view-all="openChannelsDialog"
        />
      </OnboardingSection>
    </OnboardingLayout>
    <InboxChannelsDialog
      ref="channelsDialogRef"
      :inboxes="inboxes"
      @connected="refetchInboxes"
    />
  </div>
</template>
