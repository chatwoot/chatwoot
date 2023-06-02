<template>
  <banner
    v-if="shouldShowBanner"
    color-scheme="alert"
    :banner-message="bannerMessage"
    :action-button-label="actionButtonMessage"
    has-close-button
    has-action-button
    @close="dismissUpdateBanner"
  />
</template>

<script>
import Banner from 'dashboard/components/ui/Banner.vue';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import { mapGetters } from 'vuex';
import adminMixin from 'dashboard/mixins/isAdmin';

export default {
  components: { Banner },
  mixins: [adminMixin],
  data() {
    return { userDismissedBanner: false };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    bannerMessage() {
      return this.$t('GENERAL_SETTINGS.PAYMENT_PENDING');
    },
    actionButtonMessage() {
      return this.$t('GENERAL_SETTINGS.OPEN_BILLING');
    },
    shouldShowBanner() {
      if (!this.isAdmin) {
        return false;
      }

      if (this.userDismissedBanner) {
        return false;
      }

      return true;
    },
  },
  methods: {
    isBannerDismissed(version) {
      const dismissedVersions =
        LocalStorage.get(LOCAL_STORAGE_KEYS.DISMISSED_PAYMENT) || [];
      return dismissedVersions.includes(version);
    },
    dismissUpdateBanner() {
      let updatedDismissedItems =
        LocalStorage.get(LOCAL_STORAGE_KEYS.DISMISSED_PAYMENT) || [];
      if (updatedDismissedItems instanceof Array) {
        updatedDismissedItems.push(this.latestChatwootVersion);
      } else {
        updatedDismissedItems = [this.latestChatwootVersion];
      }
      LocalStorage.set(
        LOCAL_STORAGE_KEYS.DISMISSED_PAYMENT,
        updatedDismissedItems
      );
      this.userDismissedBanner = true;
    },
  },
};
</script>
