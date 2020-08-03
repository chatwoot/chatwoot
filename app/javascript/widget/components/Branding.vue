<template>
  <a
    v-if="globalConfig.brandName"
    class="branding"
    :href="`${globalConfig.widgetBrandURL}?utm_source=widget_branding`"
    rel="noreferrer noopener nofollow"
    target="_blank"
  >
    <img :alt="globalConfig.brandName" :src="globalConfig.logoThumbnail" />
    <span>
      {{ useInstallationName($t('POWERED_BY'), globalConfig.brandName) }}
    </span>
  </a>
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
  color: $color-light-gray;
  opacity: 0.9;
  display: flex;
  filter: grayscale(1);
  font-size: $font-size-small;
  justify-content: center;
  text-align: center;
  text-decoration: none;
  padding: $space-normal 0 $space-slab;
  cursor: pointer;

  &:hover {
    filter: grayscale(0);
    opacity: 1;
    color: $color-gray;
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
