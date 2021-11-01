<template>
  <modal :show.sync="show" :on-close="onClose" :close-on-backdrop-click="false">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('INTEGRATION_SETTINGS.WEBHOOK.ADD.TITLE')"
        :header-content="
          useInstallationName(
            $t('INTEGRATION_SETTINGS.WEBHOOK.ADD.DESC'),
            globalConfig.installationName
          )
        "
      />
      <form class="row" @submit.prevent="addWebhook">
        <div class="medium-12 columns">
          <label :class="{ error: $v.endPoint.$error }">
            {{ $t('INTEGRATION_SETTINGS.WEBHOOK.ADD.FORM.END_POINT.LABEL') }}
            <input
              v-model.trim="endPoint"
              type="text"
              name="endPoint"
              :placeholder="
                $t(
                  'INTEGRATION_SETTINGS.WEBHOOK.ADD.FORM.END_POINT.PLACEHOLDER'
                )
              "
              @input="$v.endPoint.$touch"
            />
            <span v-if="$v.endPoint.$error" class="message">
              {{ $t('INTEGRATION_SETTINGS.WEBHOOK.ADD.FORM.END_POINT.ERROR') }}
            </span>
          </label>
        </div>

        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-button
              :disabled="$v.endPoint.$invalid || addWebHook.showLoading"
              :is-loading="addWebHook.showLoading"
            >
              {{ $t('INTEGRATION_SETTINGS.WEBHOOK.ADD.FORM.SUBMIT') }}
            </woot-button>
            <woot-button class="button clear" @click.prevent="onClose">
              {{ $t('INTEGRATION_SETTINGS.WEBHOOK.ADD.CANCEL') }}
            </woot-button>
          </div>
        </div>
      </form>
    </div>
  </modal>
</template>

<script>
import { required, url, minLength } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import Modal from '../../../../components/Modal';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import { mapGetters } from 'vuex';

export default {
  components: {
    Modal,
  },
  mixins: [alertMixin, globalConfigMixin],
  props: {
    onClose: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      endPoint: '',
      addWebHook: {
        showAlert: false,
        showLoading: false,
      },
      show: true,
    };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },
  validations: {
    endPoint: {
      required,
      minLength: minLength(7),
      url,
    },
  },
  methods: {
    resetForm() {
      this.endPoint = '';
      this.$v.endPoint.$reset();
    },
    async addWebhook() {
      this.addWebHook.showLoading = true;

      try {
        await this.$store.dispatch('webhooks/create', {
          webhook: { url: this.endPoint },
        });
        this.addWebHook.showLoading = false;

        this.addWebHook.message = this.$t(
          'INTEGRATION_SETTINGS.WEBHOOK.ADD.API.SUCCESS_MESSAGE'
        );
        this.resetForm();
        this.onClose();
      } catch (error) {
        this.addWebHook.showLoading = false;
        this.addWebHook.message =
          error.response.data.message ||
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.ERROR_MESSAGE');
      } finally {
        this.addWebHook.showLoading = false;
        this.showAlert(this.addWebHook.message);
      }
    },
  },
};
</script>
