<template>
  <div class="columns onboarding-wrap">
    <div class="onboarding">
      <div class="scroll-wrap">
        <div class="features-item">
          <h1 class="page-title">
            <span>{{
              $t('ONBOARDING.TITLE', {
                installationName: globalConfig.installationName,
              })
            }}</span>
          </h1>
          <p class="intro-body">
            {{
              $t('ONBOARDING.DESCRIPTION', {
                installationName: globalConfig.installationName,
              })
            }}
          </p>
          <p>
            <a
              href="https://changelog.chatwoot.com"
              target="_blank"
              rel="noopener nofollow noreferrer"
              class="onboarding--link"
            >
              {{ $t('ONBOARDING.READ_LATEST_UPDATES') }}
            </a>
            <span>🎉</span>
          </p>
        </div>
        <div class="features-item">
          <h2 class="block-title">
            <span class="emoji">💬</span>
            <span class="conversation--title">{{
              $t('ONBOARDING.ALL_CONVERSATION.TITLE')
            }}</span>
          </h2>
          <p class="intro-body">
            {{ $t('ONBOARDING.ALL_CONVERSATION.DESCRIPTION') }}
          </p>
        </div>
        <div class="features-item">
          <h2 class="block-title">
            <span class="emoji">👥</span
            >{{ $t('ONBOARDING.TEAM_MEMBERS.TITLE') }}
          </h2>
          <p class="intro-body">
            {{ $t('ONBOARDING.TEAM_MEMBERS.DESCRIPTION') }}
          </p>
          <router-link :to="newAgentURL" class="onboarding--link">
            {{ $t('ONBOARDING.TEAM_MEMBERS.NEW_LINK') }}
          </router-link>
        </div>
        <div class="features-item">
          <h2 class="block-title">
            <span class="emoji">📥</span>{{ $t('ONBOARDING.INBOXES.TITLE') }}
          </h2>
          <p class="intro-body ">
            {{ $t('ONBOARDING.INBOXES.DESCRIPTION') }}
          </p>
          <router-link :to="newInboxURL" class="onboarding--link">
            {{ $t('ONBOARDING.INBOXES.NEW_LINK') }}
          </router-link>
        </div>
        <div class="features-item">
          <h2 class="block-title">
            <span class="emoji">🏷</span>{{ $t('ONBOARDING.LABELS.TITLE') }}
          </h2>
          <p class="intro-body ">
            {{ $t('ONBOARDING.LABELS.DESCRIPTION') }}
          </p>
          <router-link :to="newLabelsURL" class="onboarding--link">
            {{ $t('ONBOARDING.LABELS.NEW_LINK') }}
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import accountMixin from '../../../mixins/account';

export default {
  mixins: [accountMixin],
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    newInboxURL() {
      return this.addAccountScoping('settings/inboxes/new');
    },
    newAgentURL() {
      return this.addAccountScoping('settings/agents/list');
    },
    newLabelsURL() {
      return this.addAccountScoping('settings/labels/list');
    },
  },
};
</script>
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
  padding: var(--space-larger) 13.6rem;
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
