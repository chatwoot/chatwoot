<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, maxLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import FormInput from '../../../components/Form/Input.vue';
import SubmitButton from '../../../components/Button/SubmitButton.vue';
import AuthBackround from '../../../components/AuthBackground/AuthBackground.vue';
import { generateOTP, verifyOTP, resendOTP, checkOTPStatus } from '../../../api/auth';

export default {
  name: 'OTPVerification',
  components: {
    FormInput,
    SubmitButton,
    AuthBackround,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      email: '',
      otpCode: '',
      isVerificationInProgress: false,
      isResendingOTP: false,
      countdown: 0,
      countdownInterval: null,
      expiresAt: null,
      error: '',
      isAlreadyVerified: false,
      showUserNotFoundRedirect: false,
      redirectCountdown: -1,
      redirectInterval: null,
      redirectMessage: '',
      redirectUrl: '',
    };
  },
  validations() {
    return {
      otpCode: {
        required,
        minLength: minLength(6),
        maxLength: maxLength(6),
      },
    };
  },
  mounted() {
    // Get email from query params or route params
    this.email = this.$route.query.email || '';
    
    if (!this.email) {
      this.$router.push('/app/auth/signup');
      return;
    }

    // Check OTP status first before generating new OTP
    this.checkUserVerificationStatus();
  },
  beforeUnmount() {
    this.clearCountdown();
    this.clearRedirectCountdown();
  },
  methods: {
    // Helper method to check if user is verified based on response
    isUserVerified(response) {
      return response?.status === 'verified';
    },

    // Helper method to check if user not found
    isUserNotFound(response) {
      return response?.status === 'user_not_found';
    },

    // Universal redirect method with countdown
    startRedirectWithCountdown(message, url, seconds = 5) {
      this.redirectMessage = message;
      this.redirectUrl = url;
      this.redirectCountdown = seconds;
      this.clearRedirectCountdown(); // Clear any existing countdown
      
      this.redirectInterval = setInterval(() => {
        this.redirectCountdown--;
        if (this.redirectCountdown <= 0) {
          this.clearRedirectCountdown();
          this.$router.push(url);
        }
      }, 1000);
    },

    async checkUserVerificationStatus() {
      try {
        const response = await checkOTPStatus({ email: this.email });
        
        if (this.isUserVerified(response)) {
          // User is already verified, show countdown and redirect
          this.isAlreadyVerified = true;
          this.startRedirectWithCountdown(
            this.$t('OTP_VERIFICATION.REDIRECT.ALREADY_VERIFIED'),
            '/app/login'
          );
          return;
        }
        
        // User not verified, proceed with OTP generation
        this.handleGenerateOTP();
      } catch (error) {
        const errorData = error.response?.data;
        
        if (this.isUserVerified(errorData)) {
          this.isAlreadyVerified = true;
          this.startRedirectWithCountdown(
            this.$t('OTP_VERIFICATION.REDIRECT.ALREADY_VERIFIED'),
            '/app/login'
          );
        } else if (this.isUserNotFound(errorData)) {
          this.showUserNotFoundRedirect = true;
          this.startRedirectWithCountdown(
            this.$t('OTP_VERIFICATION.REDIRECT.USER_NOT_FOUND'),
            '/app/auth/signup'
          );
        } else {
          // If status check fails, still try to generate OTP
          this.handleGenerateOTP();
        }
      }
    },

    async handleGenerateOTP() {
      if (this.isAlreadyVerified) return;
      
      try {
        const response = await generateOTP({ email: this.email });
        this.expiresAt = new Date(response.expires_at);
        this.startCountdown();
        
        // Check if this is an existing active OTP or new OTP
        if (response.status === 'otp_already_active') {
          useAlert(this.$t('OTP_VERIFICATION.MESSAGES.CODE_ALREADY_ACTIVE'));
        } else {
          useAlert(this.$t('OTP_VERIFICATION.MESSAGES.CODE_SENT'));
        }
      } catch (error) {
        const errorData = error.response?.data;
        
        if (this.isUserVerified(errorData)) {
          this.isAlreadyVerified = true;
          this.startRedirectWithCountdown(
            this.$t('OTP_VERIFICATION.REDIRECT.ALREADY_VERIFIED_GENERATE'),
            '/app/login'
          );
        } else if (this.isUserNotFound(errorData)) {
          this.showUserNotFoundRedirect = true;
          this.startRedirectWithCountdown(
            this.$t('OTP_VERIFICATION.REDIRECT.USER_NOT_FOUND'),
            '/app/auth/signup'
          );
        } else {
          this.error = errorData?.message || this.$t('OTP_VERIFICATION.ERRORS.FAILED_TO_GENERATE');
        }
      }
    },
    
    async verifyCode() {
      if (this.isAlreadyVerified) return;
      
      this.v$.$touch();
      if (this.v$.$invalid) return;

      this.isVerificationInProgress = true;
      this.error = '';

      try {
        await verifyOTP({ 
          email: this.email, 
          code: this.otpCode.trim() 
        });
        useAlert(this.$t('OTP_VERIFICATION.MESSAGES.VERIFICATION_SUCCESS'));
        this.$router.push('/app/login');
      } catch (error) {
        const errorData = error.response?.data;
        
        if (this.isUserVerified(errorData)) {
          this.isAlreadyVerified = true;
          this.startRedirectWithCountdown(
            this.$t('OTP_VERIFICATION.REDIRECT.ALREADY_VERIFIED_VERIFY'),
            '/app/login'
          );
        } else if (this.isUserNotFound(errorData)) {
          this.showUserNotFoundRedirect = true;
          this.startRedirectWithCountdown(
            this.$t('OTP_VERIFICATION.REDIRECT.USER_NOT_FOUND'),
            '/app/auth/signup'
          );
        } else {
          this.error = this.$t('OTP_VERIFICATION.ERRORS.INVALID_CODE');
        }
      } finally {
        this.isVerificationInProgress = false;
      }
    },

    async resendCode() {
      if (this.countdown > 0 || this.isAlreadyVerified) return;

      this.isResendingOTP = true;
      this.error = '';

      try {
        const response = await resendOTP({ email: this.email });
        this.expiresAt = new Date(response.expires_at);
        this.startCountdown();
        useAlert(this.$t('OTP_VERIFICATION.MESSAGES.CODE_RESENT'));
        this.otpCode = ''; // Clear previous code
      } catch (error) {
        const errorData = error.response?.data;
        
        if (this.isUserVerified(errorData)) {
          this.isAlreadyVerified = true;
          this.startRedirectWithCountdown(
            this.$t('OTP_VERIFICATION.REDIRECT.ALREADY_VERIFIED_RESEND'),
            '/app/login'
          );
        } else if (this.isUserNotFound(errorData)) {
          this.showUserNotFoundRedirect = true;
          this.startRedirectWithCountdown(
            this.$t('OTP_VERIFICATION.REDIRECT.USER_NOT_FOUND'),
            '/app/auth/signup'
          );
        } else {
          // Handle cooldown error
          if (errorData?.retry_after_seconds) {
            this.error = this.$t('OTP_VERIFICATION.REDIRECT.COOLDOWN_MESSAGE', { seconds: errorData.retry_after_seconds });
          } else {
            this.error = errorData?.message || errorData?.error || this.$t('OTP_VERIFICATION.ERRORS.FAILED_TO_RESEND');
          }
        }
      } finally {
        this.isResendingOTP = false;
      }
    },

    startCountdown() {
      this.clearCountdown();
      this.updateCountdown();
      this.countdownInterval = setInterval(this.updateCountdown, 1000);
    },

    updateCountdown() {
      if (!this.expiresAt) return;
      
      const now = new Date();
      const timeLeft = Math.max(0, Math.floor((this.expiresAt - now) / 1000));
      this.countdown = timeLeft;
      
      if (timeLeft <= 0) {
        this.clearCountdown();
      }
    },

    clearCountdown() {
      if (this.countdownInterval) {
        clearInterval(this.countdownInterval);
        this.countdownInterval = null;
      }
    },

    formatTime(seconds) {
      const minutes = Math.floor(seconds / 60);
      const secs = seconds % 60;
      return `${minutes}:${secs.toString().padStart(2, '0')}`;
    },

    clearRedirectCountdown() {
      if (this.redirectInterval) {
        clearInterval(this.redirectInterval);
        this.redirectInterval = null;
      }
    },
  },
};
</script>

<template>
  <div class="w-full h-full dark:bg-slate-900">
    <div class="flex h-full min-h-screen">
      <div class="flex flex-col md:flex-row *:md:flex-1 w-full">
        <AuthBackround />
        <div class="p-5 md:p-8 w-full overflow-auto flex items-center">
          <div class="w-full mx-auto max-w-md">
            <div class="mb-8">
              <h2 class="mt-6 text-3xl font-medium text-center text-slate-900 dark:text-woot-50">
                {{ $t('OTP_VERIFICATION.TITLE') }}
              </h2>
              <p class="mt-2 text-center text-sm text-slate-600 dark:text-slate-400">
                {{ $t('OTP_VERIFICATION.SUBTITLE') }}
              </p>
              <p class="text-center text-sm font-medium text-slate-900 dark:text-woot-50">
                {{ email }}
              </p>
            </div>

            <!-- Universal Redirect State -->
            <div v-if="isAlreadyVerified || showUserNotFoundRedirect" class="space-y-6">
              <div class="rounded-md p-4" :class="{
                'bg-green-50 dark:bg-green-900/20': isAlreadyVerified,
                'bg-red-50 dark:bg-red-900/20': showUserNotFoundRedirect
              }">
                <div class="flex">
                  <div class="flex-shrink-0">
                    <!-- Already Verified - Green Check -->
                    <svg v-if="isAlreadyVerified" class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.236 4.53L7.53 10.23a.75.75 0 00-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clip-rule="evenodd" />
                    </svg>
                    <!-- User Not Found - Red X -->
                    <svg v-else-if="showUserNotFoundRedirect" class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clip-rule="evenodd" />
                    </svg>
                    <!-- Default - Yellow Warning -->
                    <svg v-else class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path fill-rule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
                    </svg>
                  </div>
                  <div class="ml-3">
                    <h3 class="text-sm font-medium" :class="{
                      'text-green-800 dark:text-green-200': isAlreadyVerified,
                      'text-red-800 dark:text-red-200': showUserNotFoundRedirect
                    }">
                      {{ isAlreadyVerified ? $t('OTP_VERIFICATION.REDIRECT.TITLE_VERIFIED') : $t('OTP_VERIFICATION.REDIRECT.TITLE_NOT_FOUND') }}
                    </h3>
                    <div class="mt-2 text-sm" :class="{
                      'text-green-700 dark:text-green-300': isAlreadyVerified,
                      'text-red-700 dark:text-red-300': showUserNotFoundRedirect
                    }">
                      <p>
                        {{ redirectMessage }}. 
                        {{ $t('OTP_VERIFICATION.REDIRECT.COUNTDOWN_TEXT', { seconds: redirectCountdown }) }}
                      </p>
                    </div>
                    <div class="mt-4">
                      <div class="-mx-2 -my-1.5 flex">
                        <button
                          type="button"
                          class="rounded-md px-2 py-1.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-offset-2"
                          :class="{
                            'bg-green-50 text-green-800 hover:bg-green-100 focus:ring-green-600 focus:ring-offset-green-50 dark:bg-green-900/20 dark:text-green-200 dark:hover:bg-green-900/30': isAlreadyVerified,
                            'bg-red-50 text-red-800 hover:bg-red-100 focus:ring-red-600 focus:ring-offset-red-50 dark:bg-red-900/20 dark:text-red-200 dark:hover:bg-red-900/30': showUserNotFoundRedirect
                          }"
                          @click="$router.push(redirectUrl)"
                        >
                          {{ isAlreadyVerified ? $t('OTP_VERIFICATION.REDIRECT.BUTTON_LOGIN') : $t('OTP_VERIFICATION.REDIRECT.BUTTON_SIGNUP') }}
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- OTP Verification Form -->
            <form v-else class="space-y-6" @submit.prevent="verifyCode">
              <div v-if="error" class="rounded-md bg-red-50 p-4 dark:bg-red-900/20">
                <div class="text-sm text-red-700 dark:text-red-400">
                  {{ error }}
                </div>
              </div>

              <div>
                <FormInput
                  v-model.trim="otpCode"
                  name="otpCode"
                  :label="$t('OTP_VERIFICATION.OTP_CODE.LABEL')"
                  :has-error="v$.otpCode.$error"
                  :error-message="v$.otpCode.$error ? $t('OTP_VERIFICATION.OTP_CODE.ERROR') : ''"
                  :placeholder="$t('OTP_VERIFICATION.OTP_CODE.PLACEHOLDER')"
                  :disabled="isAlreadyVerified"
                  data-testid="otp-code-input"
                  type="text"
                  maxlength="6"
                  class="text-center text-2xl tracking-widest"
                  @input="otpCode = otpCode.replace(/[^0-9]/g, '').slice(0, 6)"
                />
              </div>

              <div>
                <SubmitButton
                  :disabled="v$.otpCode.$invalid || isAlreadyVerified"
                  :loading="isVerificationInProgress"
                  :button-text="$t('OTP_VERIFICATION.BUTTONS.VERIFY')"
                  class="w-full"
                  data-testid="verify-email-button"
                />
              </div>

              <div class="text-center space-y-3">
                <div class="text-sm text-slate-600 dark:text-slate-400">
                  {{ $t('OTP_VERIFICATION.MESSAGES.DIDNT_RECEIVE') }}
                </div>
                
                <div v-if="countdown > 0" class="text-sm text-slate-500 dark:text-slate-500">
                  {{ $t('OTP_VERIFICATION.MESSAGES.COUNTDOWN') }} {{ formatTime(countdown) }}
                </div>
                
                <button
                  v-else
                  :disabled="isResendingOTP || isAlreadyVerified"
                  class="text-sm text-woot-600 hover:text-woot-500 disabled:opacity-50"
                  type="button"
                  @click="resendCode"
                >
                  <span v-if="isResendingOTP">{{ $t('OTP_VERIFICATION.BUTTONS.RESENDING') }}</span>
                  <span v-else>{{ $t('OTP_VERIFICATION.BUTTONS.RESEND') }}</span>
                </button>
              </div>

              <div class="text-center">
                <button
                  class="text-sm text-slate-600 hover:text-slate-500 dark:text-slate-400"
                  type="button"
                  @click="$router.push('/app/auth/signup')"
                >
                  {{ $t('OTP_VERIFICATION.BUTTONS.BACK_TO_SIGNUP') }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Custom styles for OTP input */
</style>