<template>
  <woot-modal :show="show" :on-close="closeModal">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="header" />
      <form class="w-full" @submit.prevent="submit">
        <woot-input
          v-model.trim="app.name"
          :class="{ error: $v.app.name.$error }"
          class="w-full"
          :label="$t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.TITLE_LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.TITLE_PLACEHOLDER')
          "
          :error="
            $v.app.name.$error
              ? $t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.TITLE_ERROR')
              : null
          "
          data-testid="app-title"
          @input="$v.app.name.$touch"
        />
        <woot-input
          v-model.trim="app.base_url"
          :class="{ error: $v.app.base_url.$error }"
          class="w-full"
          :label="$t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.URL_LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.URL_PLACEHOLDER')
          "
          :error="
            $v.app.base_url.$error
              ? $t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.URL_ERROR')
              : null
          "
          data-testid="app-url"
          @input="$v.app.base_url.$touch"
        />
        <woot-input
          v-model.trim="app.api_key"
          :class="{ error: $v.app.api_key.$error }"
          class="w-full"
          :label="$t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.KEY_LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.KEY_PLACEHOLDER')
          "
          :error="
            $v.app.api_key.$error
              ? $t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.KEY_ERROR')
              : null
          "
          data-testid="app-url"
          @input="$v.app.api_key.$touch"
        />
        <woot-input
          v-model.trim="app.frontend_url"
          :class="{ error: $v.app.frontend_url.$error }"
          class="w-full"
          :label="$t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.FRONTEND_LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.FRONTEND_PLACEHOLDER')
          "
          :error="
            $v.app.frontend_url.$error
              ? $t('INTEGRATION_SETTINGS.CUSTOM_API.FORM.FRONTEND_ERROR')
              : null
          "
          data-testid="app-url"
          @input="$v.app.frontend_url.$touch"
        />
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <woot-button
            :is-loading="isLoading"
            :is-disabled="$v.$invalid"
            data-testid="label-submit"
          >
            {{ submitButtonLabel }}
          </woot-button>
          <woot-button class="button clear" @click.prevent="closeModal">
            {{ $t('INTEGRATION_SETTINGS.CUSTOM_API.CREATE.FORM_CANCEL') }}
          </woot-button>
        </div>
      </form>
    </div>
  </woot-modal>
</template>

<script>
import { required, url } from 'vuelidate/lib/validators';
import { useAlert } from 'dashboard/composables';

export default {
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    mode: {
      type: String,
      default: 'create',
    },
    selectedAppData: {
      type: Object,
      default: () => ({}),
    },
  },
  validations: {
    app: {
      name: { required },
      base_url: { required },
      api_key: { required },
      frontend_url: { required, url },
    },
  },
  data() {
    return {
      isLoading: false,
      app: {
        name: '',
        base_url: '',
        api_key: '',
        frontend_url: '',
      },
    };
  },
  computed: {
    header() {
      return this.$t(`INTEGRATION_SETTINGS.CUSTOM_API.${this.mode}.HEADER`);
    },
    submitButtonLabel() {
      return this.$t(
        `INTEGRATION_SETTINGS.CUSTOM_API.${this.mode}.FORM_SUBMIT`
      );
    },
  },
  mounted() {
    if (this.mode === 'UPDATE' && this.selectedAppData) {
      this.app.name = this.selectedAppData.name;
      this.app.base_url = this.selectedAppData.base_url;
      this.app.api_key = this.selectedAppData.api_key;
      this.app.frontend_url = this.selectedAppData.frontend_url;
    }
  },
  methods: {
    closeModal() {
      this.app = {
        name: '',
        api_key: '',
        base_url: '',
        frontend_url: '',
      };
      this.$emit('close');
    },
    async submit() {
      try {
        this.$v.$touch();
        if (this.$v.$invalid) {
          return;
        }

        const action = this.mode.toLowerCase();
        const payload = {
          name: this.app.name,
          base_url: this.app.base_url,
          api_key: this.app.api_key,
          frontend_url: this.app.frontend_url,
        };

        if (action === 'update') {
          payload.id = this.selectedAppData.id;
        }

        this.isLoading = true;
        await this.$store.dispatch(`customApi/${action}`, payload);
        useAlert(
          this.$t(`INTEGRATION_SETTINGS.CUSTOM_API.${this.mode}.API_SUCCESS`)
        );
        this.closeModal();
      } catch (err) {
        useAlert(
          this.$t(`INTEGRATION_SETTINGS.CUSTOM_API.${this.mode}.API_ERROR`)
        );
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>
