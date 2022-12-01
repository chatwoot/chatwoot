<template>
  <div class="row h-full">
    <div
      :class="
        `${showTestimonials ? 'large-6' : 'large-12'} signup-form--container`
      "
    >
      <div class="signup-form--content">
        <div class="signup--hero">
          <img
            :src="globalConfig.logo"
            :alt="globalConfig.installationName"
            class="hero--logo"
          />
          <h2 class="hero--title">
            {{ $t('REGISTER.TRY_WOOT') }}
          </h2>
        </div>
        <signup-form />
        <div class="auth-screen--footer">
          <span>{{ $t('REGISTER.HAVE_AN_ACCOUNT') }}</span>
          <router-link to="/app/login">
            {{
              useInstallationName(
                $t('LOGIN.TITLE'),
                globalConfig.installationName
              )
            }}
          </router-link>
        </div>
      </div>
    </div>
    <testimonials
      class="medium-6 testimonial--container"
      @resize-containers="resizeContainers"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import SignupForm from './components/Signup/Form.vue';
import Testimonials from './components/Testimonials/Index.vue';

export default {
  components: {
    SignupForm,
    Testimonials,
  },
  mixins: [globalConfigMixin],
  data() {
    return { showTestimonials: false };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },
  methods: {
    resizeContainers(hasTestimonials) {
      this.showTestimonials = hasTestimonials;
    },
  },
};
</script>
<style scoped lang="scss">
.signup-form--container {
  display: flex;
  align-items: center;
  height: 100%;
  min-height: 640px;
  overflow: auto;
}

.signup-form--content {
  padding: var(--space-jumbo);
  max-width: 600px;
  width: 100%;
}

.signup--hero {
  margin-bottom: var(--space-normal);

  .hero--logo {
    width: 160px;
  }

  .hero--title {
    margin-top: var(--space-medium);
    font-weight: var(--font-weight-light);
  }
}

.auth-screen--footer {
  font-size: var(--font-size-small);
}

@media screen and (max-width: 1200px) {
  .testimonial--container {
    display: none;
  }
  .signup-form--container {
    width: 100%;
    flex: 0 0 100%;
    max-width: 100%;
  }
  .signup-form--content {
    margin: 0 auto;
  }
}
</style>
