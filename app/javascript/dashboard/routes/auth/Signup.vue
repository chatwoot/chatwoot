<template>
  <div class="medium-10 column signup">
    <div class="text-center medium-12 signup--hero">
      <img
        src="~dashboard/assets/images/woot-logo.svg"
        alt="Woot-logo"
        class="hero--logo"
      />
      <h2 class="hero--title">
        {{ $t('REGISTER.TRY_WOOT') }}
      </h2>
    </div>
    <div class="row align-center">
      <div class="medium-5 column">
        <ul class="signup--features">
          <li><i class="ion-beer beer"></i>Unlimited Facebook Pages</li>
          <li><i class="ion-stats-bars report"></i>Robust Reporting</li>
          <li><i class="ion-chatbox-working canned"></i>Canned Responses</li>
          <li><i class="ion-loop uptime"></i>Auto Assignment</li>
          <li><i class="ion-locked secure"></i>Enterprise level security</li>
        </ul>
      </div>
      <div class="medium-5 column">
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
            <p class="accept--terms" v-html="$t('REGISTER.TERMS_ACCEPT')"></p>
          </div>
        </form>
        <div class="column text-center sigin--footer">
          <span>Already have an account?</span>
          <router-link to="/app/login">
            {{ $t('LOGIN.TITLE') }}
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global bus */

import { required, minLength, email } from 'vuelidate/lib/validators';
import Auth from '../../api/auth';

export default {
  data() {
    return {
      // We need to initialize the component with any
      // properties that will be used in it
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
