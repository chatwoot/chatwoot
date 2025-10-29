<script>
import { mapGetters } from 'vuex';
import wootConstants from 'dashboard/constants/globals';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  data() {
    return {
      helpCenterDocsURL: wootConstants.HELP_CENTER_DOCS_URL,
      upgradeFeature: [
        {
          key: 1,
          title: this.$t('HELP_CENTER.UPGRADE_PAGE.FEATURES.PORTALS.TITLE'),
          icon: 'book-copy',
          description: this.$t(
            'HELP_CENTER.UPGRADE_PAGE.FEATURES.PORTALS.DESCRIPTION'
          ),
        },
        {
          key: 2,
          title: this.$t('HELP_CENTER.UPGRADE_PAGE.FEATURES.LOCALES.TITLE'),
          icon: 'globe-line',
          description: this.$t(
            'HELP_CENTER.UPGRADE_PAGE.FEATURES.LOCALES.DESCRIPTION'
          ),
        },
        {
          key: 3,
          title: this.$t('HELP_CENTER.UPGRADE_PAGE.FEATURES.SEO.TITLE'),
          icon: 'heart-handshake',
          description: this.$t(
            'HELP_CENTER.UPGRADE_PAGE.FEATURES.SEO.DESCRIPTION'
          ),
        },
        {
          key: 4,
          title: this.$t('HELP_CENTER.UPGRADE_PAGE.FEATURES.API.TITLE'),
          icon: 'search-check',
          description: this.$t(
            'HELP_CENTER.UPGRADE_PAGE.FEATURES.API.DESCRIPTION'
          ),
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud', // Pending change text
    }),
  },
  methods: {
    openBillingPage() {
      this.$router.push({
        name: 'billing_settings_index',
        params: { accountId: this.accountId },
      });
    },
    openHelpCenterDocs() {
      window.open(this.helpCenterDocsURL, '_blank');
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col gap-12 sm:gap-16 items-center justify-center py-0 px-4 md:px-0 w-full min-h-screen max-w-full overflow-auto bg-white dark:bg-slate-900"
  >
    <div class="flex flex-col justify-start sm:justify-center gap-6">
      <div class="flex flex-col gap-1.5 items-start sm:items-center">
        <h1
          class="text-slate-900 dark:text-white text-left sm:text-center text-4xl sm:text-5xl mb-6 font-semibold"
        >
          {{ $t('HELP_CENTER.UPGRADE_PAGE.TITLE') }}
        </h1>
        <p
          class="max-w-2xl text-base font-normal leading-6 text-left sm:text-center text-slate-700 dark:text-slate-200"
        >
          {{
            isOnChatwootCloud
              ? $t('HELP_CENTER.UPGRADE_PAGE.DESCRIPTION')
              : $t('HELP_CENTER.UPGRADE_PAGE.SELF_HOSTED_DESCRIPTION')
          }}
        </p>
      </div>
      <div
        v-if="isOnChatwootCloud"
        class="flex flex-row gap-3 justify-start items-center sm:justify-center"
      >
        <NextButton
          outline
          :label="$t('HELP_CENTER.UPGRADE_PAGE.BUTTON.LEARN_MORE')"
          @click="openHelpCenterDocs"
        />
        <NextButton
          :label="$t('HELP_CENTER.UPGRADE_PAGE.BUTTON.UPGRADE')"
          @click="openBillingPage"
        />
      </div>
    </div>
    <div
      class="grid grid-cols-1 sm:grid-cols-2 gap-6 sm:gap-16 w-full max-w-2xl overflow-auto"
    >
      <div
        v-for="feature in upgradeFeature"
        :key="feature.key"
        class="w-64 min-w-full"
      >
        <div class="flex gap-2 flex-row">
          <div>
            <fluent-icon
              :icon="feature.icon"
              icon-lib="lucide"
              :size="26"
              class="mt-px text-slate-800 dark:text-slate-25"
            />
          </div>
          <div>
            <h5 class="font-semibold text-lg text-slate-800 dark:text-slate-25">
              {{ feature.title }}
            </h5>
            <p class="text-sm leading-6 text-slate-700 dark:text-slate-100">
              {{ feature.description }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
