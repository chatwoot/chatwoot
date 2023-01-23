<template>
  <main class="medium-12 column login">
    <section class="text-center medium-12 login__hero align-self-top">
      <img
        :src="globalConfig.logo"
        :alt="globalConfig.installationName"
        class="hero__logo"
      />
      <h2 class="hero__title">
        {{ $t('LOGIN.LOGIN_WAIT') }}
      </h2>
    </section>
  </main>
</template>

<script>
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import { mapGetters } from 'vuex';

export default {
  mixins: [globalConfigMixin],
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
  },
};
</script>
