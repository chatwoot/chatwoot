<template>
  <div class="w-full">
    <img :src="globalConfig.logoThumbnail" class="hero--logo" />
    <div class="header--wrap">
      <span class="hero--title">
        {{ title }}
      </span>
      <h6 class="hero-sub--title">
        {{ subTitle }}
      </h6>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
export default {
  mixins: [globalConfigMixin],
  props: {
    title: {
      type: String,
      default: '',
    },
    subTitle: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },
};
</script>

<style lang="scss" scoped>
.hero--logo {
  width: 60px;
}

.header--wrap {
  margin: var(--space-large) 0 var(--space-large) 0;
}

.hero--title {
  font-size: var(--font-size-giga);
  font-weight: var(--font-weight-bold);
}

.hero-sub--title {
  font-size: var(--font-size-small);
  color: var(--b-500);
}
</style>
