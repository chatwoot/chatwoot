<script>
import { mapGetters } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';

export default {
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
    greeting() {
      const time = new Date();
      const hours = time.getHours();
      if (hours < 12) return 'Good morning';
      if (hours < 18) return 'Good afternoon';
      return 'Good evening';
    },
    greetingMessage() {
      return `👋 ${this.greeting}, ${this.currentUser.name}. Welcome to ${this.globalConfig.installationName}.`;
    },
    newInboxURL() {
      return this.accountScopedUrl('settings/inboxes/new');
    },
    newAgentURL() {
      return this.accountScopedUrl('settings/agents/list');
    },
    newLabelsURL() {
      return this.accountScopedUrl('settings/labels/list');
    },
  },
};
</script>

<template>
  <div
    class="min-h-screen grid grid-cols-2 grid-rows-[auto_1fr_1fr] gap-4 p-8 w-full font-inter bg-white dark:bg-slate-900 overflow-auto"
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
    <div
      class="h-full w-full bg-gradient-to-b from-slate-50 dark:from-slate-800 to-white dark:to-slate-900 border border-slate-100 dark:border-white/10 rounded-lg p-4 flex flex-col"
    >
      <img
        src="~dashboard/assets/images/onboarding/omnichannel.png"
        alt="Omnichannel"
        class="h-32 w-auto mx-auto"
      />
      <div class="mt-auto">
        <p
          class="text-base text-slate-800 dark:text-slate-100 font-interDisplay font-semibold tracking-[0.3px]"
        >
          {{ $t('ONBOARDING.ALL_CONVERSATION.TITLE') }}
        </p>
        <p class="text-slate-600 dark:text-slate-400 text-sm">
          {{ $t('ONBOARDING.ALL_CONVERSATION.DESCRIPTION') }}
        </p>
      </div>
    </div>
    <div
      class="h-full w-full bg-gradient-to-b from-slate-50 dark:from-slate-800 to-white dark:to-slate-900 border border-slate-100 dark:border-white/10 rounded-lg p-4 flex flex-col"
    >
      <img
        src="~dashboard/assets/images/onboarding/teams.png"
        alt="Teams"
        class="h-36 w-auto mx-auto"
      />
      <div class="mt-auto">
        <p
          class="text-base text-slate-800 dark:text-slate-100 font-interDisplay font-semibold tracking-[0.3px]"
        >
          {{ $t('ONBOARDING.TEAM_MEMBERS.TITLE') }}
        </p>
        <p class="text-slate-600 dark:text-slate-400 text-sm">
          {{ $t('ONBOARDING.TEAM_MEMBERS.DESCRIPTION') }}
        </p>
        <router-link
          :to="newLabelsURL"
          class="no-underline text-woot-500 text-sm"
        >
          {{ $t('ONBOARDING.TEAM_MEMBERS.NEW_LINK') }} <span>→</span>
        </router-link>
      </div>
    </div>
    <div
      class="h-full w-full bg-gradient-to-b from-slate-50 dark:from-slate-800 to-white dark:to-slate-900 border border-slate-100 dark:border-white/10 rounded-lg p-4 flex flex-col"
    >
      <img
        src="~dashboard/assets/images/onboarding/inboxes.png"
        alt="Connect inboxes"
        class="h-44 w-auto mx-auto"
      />
      <div class="mt-auto">
        <p
          class="text-base text-slate-800 dark:text-slate-100 font-interDisplay font-semibold tracking-[0.3px]"
        >
          {{ $t('ONBOARDING.INBOXES.TITLE') }}
        </p>
        <p class="text-slate-600 dark:text-slate-400 text-sm">
          {{ $t('ONBOARDING.INBOXES.DESCRIPTION') }}
        </p>
        <router-link
          :to="newLabelsURL"
          class="no-underline text-woot-500 text-sm"
        >
          {{ $t('ONBOARDING.INBOXES.NEW_LINK') }} <span>→</span>
        </router-link>
      </div>
    </div>
    <div
      class="h-full w-full bg-gradient-to-b from-slate-50 dark:from-slate-800 to-white dark:to-slate-900 border border-slate-100 dark:border-white/10 rounded-lg p-4 flex flex-col"
    >
      <img
        src="~dashboard/assets/images/onboarding/labels.png"
        alt="Labels"
        class="h-36 w-auto mx-auto"
      />
      <div class="mt-auto">
        <p
          class="text-base text-slate-800 dark:text-slate-100 font-interDisplay font-semibold tracking-[0.3px]"
        >
          {{ $t('ONBOARDING.LABELS.TITLE') }}
        </p>
        <p class="text-slate-600 dark:text-slate-400 text-sm">
          {{ $t('ONBOARDING.LABELS.DESCRIPTION') }}
        </p>
        <router-link
          :to="newLabelsURL"
          class="no-underline text-woot-500 text-sm"
        >
          {{ $t('ONBOARDING.LABELS.NEW_LINK') }} <span>→</span>
        </router-link>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.onboarding-wrap {
  display: flex;
  font-size: var(--font-size-small);
  justify-content: center;
  overflow: auto;
  text-align: left;
}

.onboarding {
  height: 100vh;
  overflow: auto;
}

.scroll-wrap {
  padding: var(--space-larger) 8.5rem;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.features-item {
  margin-bottom: var(--space-large);
}

.conversation--title {
  margin-left: var(--space-minus-smaller);
}

.page-title {
  font-size: var(--font-size-big);
  font-weight: var(--font-weight-bold);
  margin-bottom: var(--space-one);
}

.block-title {
  font-weight: var(--font-weight-bold);
  margin-bottom: var(--space-smaller);
  margin-left: var(--space-minus-large);
}

.intro-body {
  margin-bottom: var(--space-small);
  line-height: 1.5;
}

.onboarding--link {
  color: var(--w-500);
  font-weight: var(--font-weight-medium);
  text-decoration: underline;
}

.emoji {
  width: var(--space-large);
  display: inline-block;
}
</style>
