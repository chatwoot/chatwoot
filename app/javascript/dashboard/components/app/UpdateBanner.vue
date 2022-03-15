<template>
  <banner
    v-if="shouldShowBanner"
    class="update-banner"
    color-scheme="primary"
    :banner-message="bannerMessage"
    href-link="https://github.com/chatwoot/chatwoot/releases"
    :href-link-text="$t('GENERAL_SETTINGS.LEARN_MORE')"
    has-close-button
    @close="dismissUpdateBanner"
  />
</template>
<script>
import Banner from 'dashboard/components/ui/Banner.vue';
import LocalStorage from '../../helper/localStorage';
import { mapGetters } from 'vuex';
import adminMixin from 'dashboard/mixins/isAdmin';

const semver = require('semver');
const dismissedUpdates = new LocalStorage('dismissedUpdates');

export default {
  components: {
    Banner,
  },
  mixins: [adminMixin],
  props: {
    latestChatwootVersion: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    hasAnUpdateAvailable() {
      if (!semver.valid(this.latestChatwootVersion)) {
        return false;
      }
      return semver.lt(
        this.globalConfig.appVersion,
        this.latestChatwootVersion
      );
    },
    bannerMessage() {
      return this.$t('GENERAL_SETTINGS.UPDATE_CHATWOOT', {
        latestChatwootVersion: this.latestChatwootVersion,
      });
    },
    shouldShowBanner() {
      return (
        this.globalConfig.displayManifest &&
        this.hasAnUpdateAvailable &&
        !this.isVersionNotificationDismissed(this.latestChatwootVersion) &&
        this.isAdmin
      );
    },
  },
  methods: {
    isVersionNotificationDismissed(version) {
      return dismissedUpdates.get().includes(version);
    },
    dismissUpdateBanner() {
      let updatedDismissedItems = dismissedUpdates.get();
      if (updatedDismissedItems instanceof Array) {
        updatedDismissedItems.push(this.latestChatwootVersion);
      } else {
        updatedDismissedItems = [this.latestChatwootVersion];
      }
      dismissedUpdates.store(updatedDismissedItems);
      this.latestChatwootVersion = this.globalConfig.appVersion;
    },
  },
};
</script>
