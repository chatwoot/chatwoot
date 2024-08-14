<script>
import { mapGetters } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import OnboardingFeatureCard from './OnboardingFeatureCard.vue';

export default {
  components: {
    OnboardingFeatureCard,
  },
  setup() {
    const { accountScopedUrl } = useAccount();
    return {
      accountScopedUrl,
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      currentUser: 'getCurrentUser',
    }),
    greetingMessage() {
      const hours = new Date().getHours();
      let translationKey;
      if (hours < 12) {
        translationKey = 'ONBOARDING.GREETING_MORNING';
      } else if (hours < 18) {
        translationKey = 'ONBOARDING.GREETING_AFTERNOON';
      } else {
        translationKey = 'ONBOARDING.GREETING_EVENING';
      }
      return this.$t(translationKey, {
        name: this.currentUser.name,
        installationName: this.globalConfig.installationName,
      });
    },
    newAgentURL() {
      return this.accountScopedUrl('settings/agents/list');
    },
    newLabelsURL() {
      return this.accountScopedUrl('settings/labels/list');
    },
    newChannelsURL() {
      return this.accountScopedUrl('settings/inboxes/new');
    },
    newCannedResponsesURL() {
      return this.accountScopedUrl('settings/canned-response/list');
    },
  },
};
</script>

<template>
  <div
    class="min-h-screen max-w-4xl mx-auto grid grid-cols-2 grid-rows-[auto_1fr_1fr] gap-4 p-8 w-full font-inter overflow-auto"
  >
    <div class="col-span-full self-start">
      <p
        class="text-xl font-semibold text-slate-900 dark:text-white font-interDisplay tracking-[0.3px]"
      >
        {{ greetingMessage }}
      </p>
      <p class="text-slate-600 dark:text-slate-400 max-w-2xl text-base">
        {{
          $t('ONBOARDING.DESCRIPTION', {
            installationName: globalConfig.installationName,
          })
        }}
      </p>
    </div>
    <OnboardingFeatureCard
      image-src="/dashboard/images/onboarding/omnichannel-inbox.png"
      image-alt="Omnichannel"
      :title="$t('ONBOARDING.ALL_CONVERSATION.TITLE')"
      :description="$t('ONBOARDING.ALL_CONVERSATION.DESCRIPTION')"
      :link="newChannelsURL"
      :link-text="$t('ONBOARDING.ALL_CONVERSATION.NEW_LINK')"
    />
    <OnboardingFeatureCard
      image-src="/dashboard/images/onboarding/teams.png"
      image-alt="Teams"
      :title="$t('ONBOARDING.TEAM_MEMBERS.TITLE')"
      :description="$t('ONBOARDING.TEAM_MEMBERS.DESCRIPTION')"
      :link="newAgentURL"
      :link-text="$t('ONBOARDING.TEAM_MEMBERS.NEW_LINK')"
    />
    <OnboardingFeatureCard
      image-src="/dashboard/images/onboarding/canned-responses.png"
      image-alt="Canned responses"
      :title="$t('ONBOARDING.CANNED_RESPONSES.TITLE')"
      :description="$t('ONBOARDING.CANNED_RESPONSES.DESCRIPTION')"
      :link="newCannedResponsesURL"
      :link-text="$t('ONBOARDING.CANNED_RESPONSES.NEW_LINK')"
    />
    <OnboardingFeatureCard
      image-src="/dashboard/images/onboarding/labels.png"
      image-alt="Labels"
      :title="$t('ONBOARDING.LABELS.TITLE')"
      :description="$t('ONBOARDING.LABELS.DESCRIPTION')"
      :link="newLabelsURL"
      :link-text="$t('ONBOARDING.LABELS.NEW_LINK')"
    />
  </div>
</template>
