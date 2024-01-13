<template>
  <div
    v-if="globalConfig.brandName && !disableBranding"
    class="px-0 py-3 flex justify-center"
  >
    <a
      :href="brandRedirectURL"
      rel="noreferrer noopener nofollow"
      target="_blank"
      class="branding--link justify-center items-center leading-3"
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
  props: {
    disableBranding: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      globalConfig: {
        brandName,
        logoThumbnail,
        widgetBrandURL,
      },
    };
  },
  props: {
    disableBranding: {
      type: Boolean,
      default: false,
    },
  },,
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
