<script>
import NextButton from 'dashboard/components-next/button/Button.vue';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import { mapGetters } from 'vuex';
import MessageFormatter from 'shared/helpers/MessageFormatter';

const BANNER_COLOR_CLASSES = {
  info: 'bg-n-brand text-white dark:text-white',
  warning: 'bg-n-amber-5 text-n-amber-12',
  error: 'bg-n-ruby-3 text-n-ruby-12',
};

const BUTTON_COLOR_MAP = {
  info: 'blue',
  warning: 'amber',
  error: 'ruby',
};

export default {
  components: { NextButton },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    dismissedBannerIds() {
      return (
        LocalStorage.get(LOCAL_STORAGE_KEYS.DISMISSED_PLATFORM_BANNERS) || []
      );
    },
    visibleBanners() {
      const banners = this.globalConfig.activePlatformBanners || [];
      return banners.filter(
        banner => !this.dismissedBannerIds.includes(banner.id)
      );
    },
  },
  methods: {
    bannerClasses(bannerType) {
      return BANNER_COLOR_CLASSES[bannerType] || BANNER_COLOR_CLASSES.warning;
    },
    formattedMessage(message) {
      return new MessageFormatter(message).formattedMessage;
    },
    buttonColor(bannerType) {
      return BUTTON_COLOR_MAP[bannerType] || 'amber';
    },
    dismissBanner(bannerId) {
      let dismissedIds =
        LocalStorage.get(LOCAL_STORAGE_KEYS.DISMISSED_PLATFORM_BANNERS) || [];
      if (dismissedIds instanceof Array) {
        dismissedIds.push(bannerId);
      } else {
        dismissedIds = [bannerId];
      }
      LocalStorage.set(
        LOCAL_STORAGE_KEYS.DISMISSED_PLATFORM_BANNERS,
        dismissedIds
      );
      this.$forceUpdate();
    },
  },
};
</script>

<template>
  <div
    v-for="banner in visibleBanners"
    :key="banner.id"
    class="status-banner flex items-center justify-center h-12 gap-4 px-4 py-3 text-xs"
    :class="bannerClasses(banner.banner_type)"
  >
    <span
      v-dompurify-html="formattedMessage(banner.banner_message)"
      class="flex items-center"
    />
    <div class="flex gap-1">
      <NextButton
        xs
        icon="i-lucide-circle-x"
        :color="buttonColor(banner.banner_type)"
        :label="$t('GENERAL_SETTINGS.DISMISS')"
        @click="dismissBanner(banner.id)"
      />
    </div>
  </div>
</template>

<style scoped>
.status-banner :deep(a) {
  @apply ml-1 underline text-xs text-current;
}

.status-banner :deep(p) {
  @apply m-0;
}
</style>
