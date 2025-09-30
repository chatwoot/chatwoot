<script>
import { ref, computed, onMounted } from 'vue';

export default {
  props: {
    oauth2Provider: {
      type: String,
      required: true,
    },
    redirectUri: {
      type: String,
      required: true,
    },
    state: {
      type: String,
      default: null,
    },
    allowCancel: {
      type: Boolean,
      default: true,
    },
    mspId: {
      type: String,
      required: true,
    },
  },
  emits: ['authSuccess', 'authError', 'authCancel'],
  setup(props, { emit }) {

    const isProcessing = ref(false);
    const errorMessage = ref('');
    const authResult = ref(null);
    const authWindow = ref(null);

    const handleAuthSuccess = result => {
      authResult.value = result;
      emit('authSuccess', result);
    };

    const handleAuthError = error => {
      errorMessage.value = error;
      emit('authError', error);
    };

    const checkAuthenticationResult = async () => {
      // Poll for authentication result
      // This would typically be implemented with WebSockets or Server-Sent Events
      // For now, we'll use a simple polling mechanism
      let attempts = 0;
      const maxAttempts = 30; // 30 seconds

      const pollResult = setInterval(async () => {
        attempts += 1;

        try {
          const response = await fetch(
            `/apple_messages_for_business/${props.mspId}/oauth/status?state=${props.state}`
          );
          const result = await response.json();

          if (result.authenticated) {
            clearInterval(pollResult);
            handleAuthSuccess(result);
          } else if (result.error) {
            clearInterval(pollResult);
            handleAuthError(result.error);
          } else if (attempts >= maxAttempts) {
            clearInterval(pollResult);
            handleAuthError('Authentication timeout');
          }
        } catch (error) {
          if (attempts >= maxAttempts) {
            clearInterval(pollResult);
            handleAuthError('Failed to check authentication status');
          }
        }
      }, 1000);
    };

    const monitorAuthWindow = () => {
      const checkClosed = setInterval(() => {
        if (authWindow.value && authWindow.value.closed) {
          clearInterval(checkClosed);

          // Check for authentication result
          checkAuthenticationResult();
        }
      }, 1000);

      // Listen for messages from the auth window
      const messageHandler = event => {
        if (event.origin !== window.location.origin) return;

        if (event.data.type === 'apple_auth_success') {
          clearInterval(checkClosed);
          handleAuthSuccess(event.data.result);
          window.removeEventListener('message', messageHandler);
        } else if (event.data.type === 'apple_auth_error') {
          clearInterval(checkClosed);
          handleAuthError(event.data.error);
          window.removeEventListener('message', messageHandler);
        }
      };

      window.addEventListener('message', messageHandler);

      // Cleanup after 10 minutes
      setTimeout(() => {
        clearInterval(checkClosed);
        window.removeEventListener('message', messageHandler);
        if (authWindow.value && !authWindow.value.closed) {
          authWindow.value.close();
        }
      }, 600000);
    };

    const providerName = computed(() => {
      const providers = {
        google: 'Google',
        linkedin: 'LinkedIn',
        facebook: 'Facebook',
      };
      return (
        providers[props.oauth2Provider.toLowerCase()] || props.oauth2Provider
      );
    });

    const startAuthentication = async () => {
      try {
        isProcessing.value = true;
        errorMessage.value = '';

        // Create authentication request
        const response = await fetch(
          `/apple_messages_for_business/${props.mspId}/oauth/landing/create`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')
                ?.content,
            },
            body: JSON.stringify({
              provider: props.oauth2Provider,
              redirect_uri: props.redirectUri,
              state: props.state,
            }),
          }
        );

        const data = await response.json();

        if (data.error) {
          throw new Error(data.error);
        }

        // Open authentication window
        const authUrl = data.landing_page_url;
        const windowFeatures =
          'width=500,height=600,scrollbars=yes,resizable=yes';

        authWindow.value = window.open(authUrl, 'apple_auth', windowFeatures);

        // Monitor authentication window
        monitorAuthWindow();
      } catch (error) {
        errorMessage.value = error.message;
        emit('authError', error.message);
      } finally {
        isProcessing.value = false;
      }
    };

    const cancelAuthentication = () => {
      if (authWindow.value && !authWindow.value.closed) {
        authWindow.value.close();
      }
      emit('authCancel');
    };

    onMounted(() => {
      // Auto-start authentication if configured
      if (props.autoStart) {
        startAuthentication();
      }
    });

    return {
      isProcessing,
      errorMessage,
      authResult,
      providerName,
      startAuthentication,
      cancelAuthentication,
    };
  },
};
</script>

<template>
  <div class="apple-authentication-bubble">
    <div class="auth-container">
      <div class="auth-header">
        <div class="auth-icon">
          <i class="i-ph-key-duotone text-2xl" />
        </div>
        <div class="auth-content">
          <h3 class="auth-title">
            {{ $t('APPLE_MESSAGES.AUTHENTICATION.TITLE') }}
          </h3>
          <p class="auth-description">
            {{
              $t('APPLE_MESSAGES.AUTHENTICATION.DESCRIPTION', {
                provider: providerName,
              })
            }}
          </p>
        </div>
      </div>

      <div class="auth-actions">
        <button
          v-if="!isProcessing"
          class="auth-button primary"
          @click="startAuthentication"
        >
          <i class="i-ph-sign-in mr-2" />
          {{
            $t('APPLE_MESSAGES.AUTHENTICATION.SIGN_IN', {
              provider: providerName,
            })
          }}
        </button>

        <button
          v-if="!isProcessing && allowCancel"
          class="auth-button secondary"
          @click="cancelAuthentication"
        >
          {{ $t('APPLE_MESSAGES.AUTHENTICATION.CANCEL') }}
        </button>

        <div v-if="isProcessing" class="auth-loading">
          <div class="loading-spinner" />
          <span>{{ $t('APPLE_MESSAGES.AUTHENTICATION.PROCESSING') }}</span>
        </div>
      </div>

      <div v-if="errorMessage" class="auth-error">
        <i class="i-ph-warning-circle mr-2" />
        {{ errorMessage }}
      </div>

      <div v-if="authResult" class="auth-success">
        <i class="i-ph-check-circle mr-2" />
        {{
          $t('APPLE_MESSAGES.AUTHENTICATION.SUCCESS', {
            name: authResult.user.name,
          })
        }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.apple-authentication-bubble {
  @apply bg-white rounded-lg shadow-md p-4 max-w-sm mx-auto;
}

.auth-container {
  @apply space-y-4;
}

.auth-header {
  @apply flex items-start space-x-3;
}

.auth-icon {
  @apply w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 flex-shrink-0;
}

.auth-content {
  @apply flex-1;
}

.auth-title {
  @apply text-lg font-semibold text-gray-900 mb-1;
}

.auth-description {
  @apply text-sm text-gray-600 leading-relaxed;
}

.auth-actions {
  @apply flex flex-col space-y-2;
}

.auth-button {
  @apply px-4 py-2 rounded-lg font-medium transition-colors duration-200 flex items-center justify-center;
}

.auth-button.primary {
  @apply bg-blue-600 text-white hover:bg-blue-700;
}

.auth-button.secondary {
  @apply bg-gray-100 text-gray-700 hover:bg-gray-200;
}

.auth-loading {
  @apply flex items-center justify-center space-x-2 py-2 text-gray-600;
}

.loading-spinner {
  @apply w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full animate-spin;
}

.auth-error {
  @apply flex items-center space-x-2 text-red-600 text-sm bg-red-50 p-3 rounded-lg;
}

.auth-success {
  @apply flex items-center space-x-2 text-green-600 text-sm bg-green-50 p-3 rounded-lg;
}
</style>
