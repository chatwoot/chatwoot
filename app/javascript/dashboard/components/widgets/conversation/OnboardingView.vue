<script setup>
import OnboardingFeatureCard from './OnboardingFeatureCard.vue';
import OnboardingIllustration from './OnboardingIllustration.vue';
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters } from 'dashboard/composables/store';

const getters = useStoreGetters();
const { t } = useI18n();
const globalConfig = computed(() => getters['globalConfig/get'].value);
const currentUser = computed(() => getters.getCurrentUser.value);

const greetingMessage = computed(() => {
  const hours = new Date().getHours();
  let translationKey;
  if (hours < 12) {
    translationKey = 'ONBOARDING.GREETING_MORNING';
  } else if (hours < 18) {
    translationKey = 'ONBOARDING.GREETING_AFTERNOON';
  } else {
    translationKey = 'ONBOARDING.GREETING_EVENING';
  }
  return t(translationKey, {
    name: currentUser.value.name,
    installationName: globalConfig.value.installationName,
  });
});
</script>

<template>
  <!--
    Columns follow the panel's own width, not the viewport: this view sits
    between the sidebar and the conversation list, so `md:`/`lg:` breakpoints
    would still squash the cards on a wide screen with a narrow panel.
    `auto-fit` drops to a single column once a track can no longer hold 18rem.
  -->
  <div
    class="min-h-full lg:max-w-5xl max-w-4xl mx-auto grid grid-cols-[repeat(auto-fit,minmax(min(18rem,100%),1fr))] grid-rows-[auto] auto-rows-fr gap-4 p-8 w-full font-inter"
  >
    <div class="col-span-full self-start">
      <p
        class="text-xl font-semibold text-n-slate-12 font-interDisplay tracking-[0.3px]"
      >
        {{ greetingMessage }}
      </p>
      <p class="text-n-slate-11 max-w-2xl text-base">
        {{
          $t('ONBOARDING.DESCRIPTION', {
            installationName: globalConfig.installationName,
          })
        }}
      </p>
    </div>
    <OnboardingFeatureCard
      to="settings_inbox_new"
      :title="$t('ONBOARDING.ALL_CONVERSATION.TITLE')"
      :description="$t('ONBOARDING.ALL_CONVERSATION.DESCRIPTION')"
      :link-text="$t('ONBOARDING.ALL_CONVERSATION.NEW_LINK')"
    >
      <OnboardingIllustration name="omnichannel" />
    </OnboardingFeatureCard>
    <OnboardingFeatureCard
      to="settings_teams_new"
      :title="$t('ONBOARDING.TEAM_MEMBERS.TITLE')"
      :description="$t('ONBOARDING.TEAM_MEMBERS.DESCRIPTION')"
      :link-text="$t('ONBOARDING.TEAM_MEMBERS.NEW_LINK')"
    >
      <OnboardingIllustration name="teams" />
    </OnboardingFeatureCard>
    <OnboardingFeatureCard
      to="canned_list"
      :title="$t('ONBOARDING.CANNED_RESPONSES.TITLE')"
      :description="$t('ONBOARDING.CANNED_RESPONSES.DESCRIPTION')"
      :link-text="$t('ONBOARDING.CANNED_RESPONSES.NEW_LINK')"
    >
      <OnboardingIllustration name="cannedResponses" />
    </OnboardingFeatureCard>
    <OnboardingFeatureCard
      to="labels_list"
      :title="$t('ONBOARDING.LABELS.TITLE')"
      :description="$t('ONBOARDING.LABELS.DESCRIPTION')"
      :link-text="$t('ONBOARDING.LABELS.NEW_LINK')"
    >
      <OnboardingIllustration name="labels" />
    </OnboardingFeatureCard>
  </div>
</template>
