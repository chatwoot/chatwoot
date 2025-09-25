<template>
  <woot-modal :show="show" :on-close="onClose">
    <div class="apple-auth-modal">
      <div class="modal-header">
        <h2 class="modal-title">
          {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.TITLE') }}
        </h2>
        <p class="modal-description">
          {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.DESCRIPTION') }}
        </p>
      </div>

      <div class="modal-content">
        <div class="provider-selection" v-if="!selectedProvider">
          <h3 class="section-title">
            {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.SELECT_PROVIDER') }}
          </h3>

          <div class="provider-grid">
            <button
              v-for="provider in availableProviders"
              :key="provider.id"
              class="provider-button"
              @click="selectProvider(provider)"
            >
              <div class="provider-icon">
                <i :class="provider.icon"></i>
              </div>
              <div class="provider-info">
                <h4 class="provider-name">{{ provider.name }}</h4>
                <p class="provider-description">{{ provider.description }}</p>
              </div>
            </button>
          </div>
        </div>

        <div class="auth-configuration" v-if="selectedProvider">
          <div class="selected-provider">
            <div class="provider-header">
              <div class="provider-icon large">
                <i :class="selectedProvider.icon"></i>
              </div>
              <div class="provider-details">
                <h3 class="provider-name">{{ selectedProvider.name }}</h3>
                <button class="change-provider" @click="changeProvider">
                  {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.CHANGE_PROVIDER') }}
                </button>
              </div>
            </div>
          </div>

          <form @submit.prevent="createAuthenticationMessage" class="auth-form">
            <div class="form-group">
              <label class="form-label">
                {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.MESSAGE_TEXT') }}
              </label>
              <textarea
                v-model="authMessage"
                class="form-input"
                rows="3"
                :placeholder="$t('APPLE_MESSAGES.AUTHENTICATION.MODAL.MESSAGE_PLACEHOLDER')"
              ></textarea>
            </div>

            <div class="form-group">
              <label class="form-label">
                {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.SUCCESS_URL') }}
              </label>
              <input
                v-model="successUrl"
                type="url"
                class="form-input"
                :placeholder="$t('APPLE_MESSAGES.AUTHENTICATION.MODAL.SUCCESS_URL_PLACEHOLDER')"
              />
            </div>

            <div class="form-group">
              <label class="form-label">
                {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.CANCEL_URL') }}
              </label>
              <input
                v-model="cancelUrl"
                type="url"
                class="form-input"
                :placeholder="$t('APPLE_MESSAGES.AUTHENTICATION.MODAL.CANCEL_URL_PLACEHOLDER')"
              />
            </div>

            <div class="form-group">
              <label class="checkbox-label">
                <input
                  v-model="requireEncryption"
                  type="checkbox"
                  class="checkbox"
                >
                <span class="checkmark"></span>
                {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.REQUIRE_ENCRYPTION') }}
              </label>
            </div>
          </form>
        </div>

        <div class="preview-section" v-if="selectedProvider">
          <h3 class="section-title">
            {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.PREVIEW') }}
          </h3>

          <div class="message-preview">
            <AppleAuthentication
              :oauth2-provider="selectedProvider.id"
              :redirect-uri="previewRedirectUri"
              :msp-id="mspId"
              :allow-cancel="!!cancelUrl"
            />
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button
          type="button"
          class="btn btn-secondary"
          @click="onClose"
        >
          {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.CANCEL') }}
        </button>

        <button
          type="button"
          class="btn btn-primary"
          :disabled="!canCreateMessage"
          @click="createAuthenticationMessage"
        >
          {{ $t('APPLE_MESSAGES.AUTHENTICATION.MODAL.CREATE_MESSAGE') }}
        </button>
      </div>
    </div>
  </woot-modal>
</template>

<script>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import AppleAuthentication from './AppleAuthentication.vue';

export default {
  components: {
    AppleAuthentication,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    mspId: {
      type: String,
      required: true,
    },
    conversationId: {
      type: String,
      required: true,
    },
  },
  emits: ['close', 'create'],
  setup(props, { emit }) {
    const { t } = useI18n();

    const selectedProvider = ref(null);
    const authMessage = ref('');
    const successUrl = ref('');
    const cancelUrl = ref('');
    const requireEncryption = ref(true);

    const availableProviders = ref([
      {
        id: 'google',
        name: 'Google',
        description: t('APPLE_MESSAGES.AUTHENTICATION.PROVIDERS.GOOGLE.DESCRIPTION'),
        icon: 'i-logos-google-icon',
      },
      {
        id: 'linkedin',
        name: 'LinkedIn',
        description: t('APPLE_MESSAGES.AUTHENTICATION.PROVIDERS.LINKEDIN.DESCRIPTION'),
        icon: 'i-logos-linkedin-icon',
      },
      {
        id: 'facebook',
        name: 'Facebook',
        description: t('APPLE_MESSAGES.AUTHENTICATION.PROVIDERS.FACEBOOK.DESCRIPTION'),
        icon: 'i-logos-facebook',
      },
    ]);

    const previewRedirectUri = computed(() => {
      return successUrl.value || `${window.location.origin}/apple_messages_for_business/${props.mspId}/oauth/callback`;
    });

    const canCreateMessage = computed(() => {
      return selectedProvider.value && authMessage.value.trim().length > 0;
    });

    const selectProvider = (provider) => {
      selectedProvider.value = provider;

      // Set default message if empty
      if (!authMessage.value) {
        authMessage.value = t('APPLE_MESSAGES.AUTHENTICATION.DEFAULT_MESSAGE', {
          provider: provider.name,
        });
      }
    };

    const changeProvider = () => {
      selectedProvider.value = null;
    };

    const createAuthenticationMessage = () => {
      if (!canCreateMessage.value) return;

      const messageData = {
        content_type: 'apple_authentication',
        content_data: {
          oauth2: {
            provider: selectedProvider.value.id,
            scope: getProviderScopes(selectedProvider.value.id),
            response_type: 'code',
            code_challenge_method: 'S256',
          },
          message: authMessage.value,
          success_url: successUrl.value,
          cancel_url: cancelUrl.value,
          require_encryption: requireEncryption.value,
        },
      };

      emit('create', messageData);
      onClose();
    };

    const getProviderScopes = (providerId) => {
      const scopes = {
        google: ['openid', 'profile', 'email'],
        linkedin: ['r_liteprofile', 'r_emailaddress'],
        facebook: ['public_profile', 'email'],
      };

      return scopes[providerId] || ['profile', 'email'];
    };

    const onClose = () => {
      // Reset form
      selectedProvider.value = null;
      authMessage.value = '';
      successUrl.value = '';
      cancelUrl.value = '';
      requireEncryption.value = true;

      emit('close');
    };

    // Watch for show prop changes to reset form
    watch(() => props.show, (newShow) => {
      if (!newShow) {
        // Reset form when modal is closed
        setTimeout(() => {
          selectedProvider.value = null;
          authMessage.value = '';
          successUrl.value = '';
          cancelUrl.value = '';
          requireEncryption.value = true;
        }, 300);
      }
    });

    return {
      selectedProvider,
      authMessage,
      successUrl,
      cancelUrl,
      requireEncryption,
      availableProviders,
      previewRedirectUri,
      canCreateMessage,
      selectProvider,
      changeProvider,
      createAuthenticationMessage,
      onClose,
    };
  },
};
</script>

<style scoped>
.apple-auth-modal {
  @apply w-full max-w-4xl;
}

.modal-header {
  @apply pb-6 border-b border-gray-200;
}

.modal-title {
  @apply text-2xl font-bold text-gray-900 mb-2;
}

.modal-description {
  @apply text-gray-600;
}

.modal-content {
  @apply py-6 space-y-6;
}

.section-title {
  @apply text-lg font-semibold text-gray-900 mb-4;
}

.provider-grid {
  @apply grid grid-cols-1 gap-4;
}

.provider-button {
  @apply flex items-center p-4 border border-gray-200 rounded-lg hover:border-blue-300 hover:bg-blue-50 transition-colors duration-200 text-left;
}

.provider-icon {
  @apply w-12 h-12 flex items-center justify-center text-2xl mr-4 flex-shrink-0;
}

.provider-icon.large {
  @apply w-16 h-16 text-3xl;
}

.provider-info {
  @apply flex-1;
}

.provider-name {
  @apply font-semibold text-gray-900 mb-1;
}

.provider-description {
  @apply text-sm text-gray-600;
}

.selected-provider {
  @apply bg-blue-50 border border-blue-200 rounded-lg p-4;
}

.provider-header {
  @apply flex items-center;
}

.provider-details {
  @apply ml-4;
}

.change-provider {
  @apply text-blue-600 hover:text-blue-700 text-sm;
}

.auth-form {
  @apply space-y-4;
}

.form-group {
  @apply space-y-2;
}

.form-label {
  @apply block text-sm font-medium text-gray-700;
}

.form-input {
  @apply w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500;
}

.checkbox-label {
  @apply flex items-center space-x-2 cursor-pointer;
}

.checkbox {
  @apply w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500;
}

.message-preview {
  @apply bg-gray-50 border border-gray-200 rounded-lg p-4;
}

.modal-footer {
  @apply pt-6 border-t border-gray-200 flex justify-end space-x-4;
}

.btn {
  @apply px-4 py-2 rounded-lg font-medium transition-colors duration-200;
}

.btn-secondary {
  @apply bg-gray-100 text-gray-700 hover:bg-gray-200;
}

.btn-primary {
  @apply bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed;
}
</style>