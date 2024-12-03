<script setup>
import OnboardingFeatureCard from './OnboardingFeatureCard.vue';
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
  <div
    class="min-h-screen lg:max-w-5xl max-w-4xl mx-auto grid grid-cols-2 grid-rows-[auto_1fr_1fr] auto-rows-min gap-4 p-8 w-full font-inter overflow-auto"
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
      to="settings_inbox_new"
      :title="$t('ONBOARDING.ALL_CONVERSATION.TITLE')"
      :description="$t('ONBOARDING.ALL_CONVERSATION.DESCRIPTION')"
      :link-text="$t('ONBOARDING.ALL_CONVERSATION.NEW_LINK')"
    />
    <OnboardingFeatureCard
      image-src="/dashboard/images/onboarding/teams.png"
      image-alt="Teams"
      to="settings_teams_new"
      :title="$t('ONBOARDING.TEAM_MEMBERS.TITLE')"
      :description="$t('ONBOARDING.TEAM_MEMBERS.DESCRIPTION')"
      :link-text="$t('ONBOARDING.TEAM_MEMBERS.NEW_LINK')"
    />
    <OnboardingFeatureCard
      image-src="/dashboard/images/onboarding/canned-responses.png"
      image-alt="Canned responses"
      to="canned_list"
      :title="$t('ONBOARDING.CANNED_RESPONSES.TITLE')"
      :description="$t('ONBOARDING.CANNED_RESPONSES.DESCRIPTION')"
      :link-text="$t('ONBOARDING.CANNED_RESPONSES.NEW_LINK')"
    />
    <OnboardingFeatureCard
      image-src="/dashboard/images/onboarding/labels.png"
      image-alt="Labels"
      to="labels_list"
      :title="$t('ONBOARDING.LABELS.TITLE')"
      :description="$t('ONBOARDING.LABELS.DESCRIPTION')"
      :link-text="$t('ONBOARDING.LABELS.NEW_LINK')"
    />
  </div>
</template>
