<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, maxLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import FormInput from '../../../components/Form/Input.vue';
import SubmitButton from '../../../components/Button/SubmitButton.vue';
import AuthBackround from '../../../components/AuthBackground/AuthBackground.vue';
import { generateOTP, verifyOTP, resendOTP } from '../../../api/auth';

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
      this.$router.push('/auth/signup');
      return;
    }

    // Auto-generate OTP on mount
    this.handleGenerateOTP();
  },
  beforeUnmount() {
    this.clearCountdown();
  },
  methods: {
    async handleGenerateOTP() {
      try {
        const response = await generateOTP({ email: this.email });
        this.expiresAt = new Date(response.expires_at);
        this.startCountdown();
        useAlert('OTP sent to your email address');
      } catch (error) {
        this.error = 'Failed to generate OTP. Please try again.';
      }
    },
    
    async verifyCode() {
      this.v$.$touch();
      if (this.v$.$invalid) return;

      this.isVerificationInProgress = true;
      this.error = '';

      try {
        await verifyOTP({ 
          email: this.email, 
          code: this.otpCode.trim() 
        });
        useAlert('Email verified successfully!');
        this.$router.push('/auth/login?verified=true');
      } catch (error) {
        this.error = error.response?.data?.error || 'Invalid or expired OTP code';
      } finally {
        this.isVerificationInProgress = false;
      }
    },

    async resendCode() {
      if (this.countdown > 0) return;

      this.isResendingOTP = true;
      this.error = '';

      try {
        const response = await resendOTP({ email: this.email });
        this.expiresAt = new Date(response.expires_at);
        this.startCountdown();
        useAlert('OTP has been resent to your email');
        this.otpCode = ''; // Clear previous code
      } catch (error) {
        this.error = error.response?.data?.error || 'Failed to resend OTP';
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

    goToSignup() {
      this.$router.push('/auth/signup');
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
                Verify Your Email
              </h2>
              <p class="mt-2 text-center text-sm text-slate-600 dark:text-slate-400">
                We've sent a verification code to
              </p>
              <p class="text-center text-sm font-medium text-slate-900 dark:text-woot-50">
                {{ email }}
              </p>
            </div>

            <form class="space-y-6" @submit.prevent="verifyCode">
              <div v-if="error" class="rounded-md bg-red-50 p-4 dark:bg-red-900/20">
                <div class="text-sm text-red-700 dark:text-red-400">
                  {{ error }}
                </div>
              </div>

              <div>
                <FormInput
                  v-model.trim="otpCode"
                  :class="{ error: v$.otpCode.$error }"
                  :error="v$.otpCode.$error ? 'Please enter a valid 6-digit code' : ''"
                  :placeholder="'Enter 6-digit code'"
                  data-testid="otp-code-input"
                  type="text"
                  maxlength="6"
                  class="text-center text-2xl tracking-widest"
                  @input="otpCode = otpCode.replace(/[^0-9]/g, '').slice(0, 6)"
                />
              </div>

              <div>
                <SubmitButton
                  :disabled="v$.otpCode.$invalid"
                  :loading="isVerificationInProgress"
                  button-text="Verify Email"
                  class="w-full"
                  data-testid="verify-email-button"
                />
              </div>

              <div class="text-center space-y-3">
                <div class="text-sm text-slate-600 dark:text-slate-400">
                  Didn't receive the code?
                </div>
                
                <div v-if="countdown > 0" class="text-sm text-slate-500 dark:text-slate-500">
                  Resend available in {{ formatTime(countdown) }}
                </div>
                
                <button
                  v-else
                  :disabled="isResendingOTP"
                  class="text-sm text-woot-600 hover:text-woot-500 disabled:opacity-50"
                  type="button"
                  @click="resendCode"
                >
                  <span v-if="isResendingOTP">Sending...</span>
                  <span v-else>Resend Code</span>
                </button>
              </div>

              <div class="text-center">
                <button
                  class="text-sm text-slate-600 hover:text-slate-500 dark:text-slate-400"
                  type="button"
                  @click="goToSignup"
                >
                  ← Back to Sign Up
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