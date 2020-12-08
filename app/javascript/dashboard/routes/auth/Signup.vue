<template>
  <div class="medium-10 column signup">
    <div class="text-center medium-12 signup--hero">
      <img
        :src="globalConfig.logo"
        :alt="globalConfig.installationName"
        class="hero--logo"
      />
      <h2 class="hero--title">
        {{ $t('REGISTER.TRY_WOOT') }}
      </h2>
    </div>
    <div class="row align-center">
      <div class="medium-5 column small-12">
        <ul class="signup--features">
          <li>
            <i class="ion-beer beer"></i>
            <span>{{ $t('REGISTER.FEATURES.UNLIMITED_INBOXES') }}</span>
          </li>
          <li>
            <i class="ion-stats-bars report"></i>
            <span>{{ $t('REGISTER.FEATURES.ROBUST_REPORTING') }}</span>
          </li>
          <li>
            <i class="ion-chatbox-working canned"></i>
            <span>{{ $t('REGISTER.FEATURES.CANNED_RESPONSES') }}</span>
          </li>
          <li>
            <i class="ion-loop uptime"></i>
            <span>{{ $t('REGISTER.FEATURES.AUTO_ASSIGNMENT') }}</span>
          </li>
          <li>
            <i class="ion-locked secure"></i>
            <span>{{ $t('REGISTER.FEATURES.SECURITY') }}</span>
          </li>
        </ul>
      </div>
      <div class="medium-5 column small-12">
        <form class="signup--box login-box " @submit.prevent="submit()">
          <div class="column log-in-form">
            <label :class="{ error: $v.credentials.name.$error }">
              {{ $t('REGISTER.ACCOUNT_NAME.LABEL') }}
              <input
                v-model.trim="credentials.name"
                type="text"
                :placeholder="$t('REGISTER.ACCOUNT_NAME.PLACEHOLDER')"
                @input="$v.credentials.name.$touch"
              />
              <span v-if="$v.credentials.name.$error" class="message">
                {{ $t('REGISTER.ACCOUNT_NAME.ERROR') }}
              </span>
            </label>
            <label :class="{ error: $v.credentials.email.$error }">
              {{ $t('REGISTER.EMAIL.LABEL') }}
              <input
                v-model.trim="credentials.email"
                type="email"
                :placeholder="$t('REGISTER.EMAIL.PLACEHOLDER')"
                @input="$v.credentials.email.$touch"
              />
              <span v-if="$v.credentials.email.$error" class="message">
                {{ $t('REGISTER.EMAIL.ERROR') }}
              </span>
            </label>
            <woot-submit-button
              :disabled="
                $v.credentials.name.$invalid ||
                  $v.credentials.email.$invalid ||
                  register.showLoading
              "
              :button-text="$t('REGISTER.SUBMIT')"
              :loading="register.showLoading"
              button-class="large expanded"
            >
            </woot-submit-button>
            <p class="accept--terms" v-html="termsLink"></p>
          </div>
        </form>
        <div class="column text-center sigin--footer">
          <span>Already have an account?</span>
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
  </div>
</template>

<script>
import { required, minLength, email } from 'vuelidate/lib/validators';
import Auth from '../../api/auth';
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
  data() {
    return {
      credentials: {
        name: '',
        email: '',
      },
      register: {
        message: '',
        showLoading: false,
      },
      error: '',
    };
  },
  validations: {
    credentials: {
      name: {
        required,
        minLength: minLength(4),
      },
      email: {
        required,
        email,
      },
    },
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
    termsLink() {
      return this.$t('REGISTER.TERMS_ACCEPT')
        .replace('https://www.chatwoot.com/terms', this.globalConfig.termsURL)
        .replace(
          'https://www.chatwoot.com/privacy-policy',
          this.globalConfig.privacyURL
        );
    },
  },
  methods: {
    showAlert(message) {
      // Reset loading, current selected agent
      this.register.showLoading = false;
      bus.$emit('newToastMessage', message);
    },
    submit() {
      this.register.showLoading = true;
      Auth.register(this.credentials)
        .then(res => {
          if (res.status === 200) {
            window.location = '/';
          }
        })
        .catch(error => {
          let errorMessage = this.$t('REGISTER.API.ERROR_MESSAGE');
          if (error.response && error.response.data.message) {
            errorMessage = error.response.data.message;
          }
          this.showAlert(errorMessage);
        });
    },
  },
};
</script>
