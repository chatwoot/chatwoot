<template>
  <div v-if="globalConfig.brandName" class="px-0 py-3 flex justify-center">
    <a
      :href="brandRedirectURL"
      rel="noreferrer noopener nofollow"
      target="_blank"
      class="branding--link justify-center"
    >
      <img
        class="branding--image"
        :alt="globalConfig.brandName"
        :src="globalConfig.logoThumbnail"
      />
      <span>
        {{ useInstallationName($t('POWERED_BY'), globalConfig.brandName) }}
      </span>
    </a>
  </div>
  <div v-else class="p-3" />
</template>

<script>
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

const {
  LOGO_THUMBNAIL: logoThumbnail,
  BRAND_NAME: brandName,
  WIDGET_BRAND_URL: widgetBrandURL,
} = window.globalConfig || {};

export default {
  mixins: [globalConfigMixin],
  data() {
    return {
      globalConfig: {
        brandName,
        logoThumbnail,
        widgetBrandURL,
      },
    };
  },
  computed: {
    brandRedirectURL() {
      try {
        const referrerHost = this.$store.getters['appConfig/getReferrerHost'];
        const baseURL = `${this.globalConfig.widgetBrandURL}?utm_source=${
          referrerHost ? 'widget_branding' : 'survey_branding'
        }`;
        if (referrerHost) {
          return `${baseURL}&utm_referrer=${referrerHost}`;
        }
        return baseURL;
      } catch (e) {
        // Suppressing the error as getter is not defined in some cases
      }
      return '';
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.branding--image {
  margin-right: $space-smaller;
  max-width: $space-slab;
  max-height: $space-slab;
}

.branding--link {
  color: $color-light-gray;
  cursor: pointer;
  display: inline-flex;
  filter: grayscale(1);
  font-size: $font-size-small;
  opacity: 0.9;
  text-decoration: none;

  &:hover {
    filter: grayscale(0);
    opacity: 1;
    color: $color-gray;
  }
}
</style>
