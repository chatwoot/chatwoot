<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import MessageFormatter from 'shared/helpers/MessageFormatter';
import Banner from 'dashboard/components-next/banner/Banner.vue';

const BANNER_COLOR_MAP = {
  info: 'blue',
  warning: 'amber',
  error: 'ruby',
};

const { t } = useI18n();
const globalConfig = useMapGetter('globalConfig/get');

const dismissedBannerIds = ref(
  LocalStorage.get(LOCAL_STORAGE_KEYS.DISMISSED_PLATFORM_BANNERS) || []
);

const dismissKey = banner => `${banner.id}-${banner.updated_at}`;

const visibleBanners = computed(() => {
  const banners = globalConfig.value?.activePlatformBanners || [];
  return banners.filter(
    banner => !dismissedBannerIds.value.includes(dismissKey(banner))
  );
});

const formattedMessage = message =>
  new MessageFormatter(message).formattedMessage;

const bannerColor = bannerType => BANNER_COLOR_MAP[bannerType] || 'slate';

const dismissBanner = banner => {
  const key = dismissKey(banner);
  if (dismissedBannerIds.value.includes(key)) return;

  dismissedBannerIds.value.push(key);
  LocalStorage.set(
    LOCAL_STORAGE_KEYS.DISMISSED_PLATFORM_BANNERS,
    dismissedBannerIds.value
  );
};
</script>

<template>
  <Banner
    v-for="banner in visibleBanners"
    :key="banner.id"
    :color="bannerColor(banner.banner_type)"
    :action-label="t('GENERAL_SETTINGS.DISMISS')"
    class="!rounded-none !justify-center [&_.link]:underline [&_p]:m-0"
    @action="dismissBanner(banner)"
  >
    <span
      v-dompurify-html="formattedMessage(banner.banner_message)"
      class="text-xs"
    />
  </Banner>
</template>
