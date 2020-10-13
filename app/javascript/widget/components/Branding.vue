<template>
  <div v-if="globalConfig.brandName" class="branding">
    <a
      :href="`${globalConfig.widgetBrandURL}?utm_source=widget_branding`"
      rel="noreferrer noopener nofollow"
      target="_blank"
    >
      <img :alt="globalConfig.brandName" :src="globalConfig.logoThumbnail" />
      <span>
        {{ useInstallationName($t('POWERED_BY'), globalConfig.brandName) }}
      </span>
    </a>
  </div>
  <div v-else class="brand--alternative" />
</template>

<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.branding {
  align-items: center;
  display: flex;
  justify-content: center;
  padding: $space-normal 0 $space-slab;
  text-align: center;

  a {
    color: $color-light-gray;
    cursor: pointer;
    display: flex;
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

  img {
    margin-right: $space-smaller;
    max-width: $space-slab;
    max-height: $space-slab;
  }
}
.brand--alternative {
  padding: $space-slab;
}
</style>
