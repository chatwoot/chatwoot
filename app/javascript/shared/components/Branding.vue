<template>
  <div
    v-if="globalConfig.brandName && !disableBranding"
    class="px-0 pt-2 pb-3 flex justify-center brand-bg"
  >
    <a
      :href="brandRedirectURL"
      rel="noreferrer noopener nofollow"
      target="_blank"
      class="text-xs text-brand font-medium cursor-pointer inline-flex justify-center items-center leading-3 grayscale opacity-60 hover:opacity-100 hover:grayscale-0 shadow-inner"
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

.brand-bg {
  background: var(--brand-bgDark);
}

.text-brand {
  color: var(--brand-body);
}
</style>
