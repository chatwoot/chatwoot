<template>
  <woot-modal :show="show" :on-close="closeModal">
    <div class="column content-box">
      <woot-modal-header :header-title="header" />

      <form class="row" @submit.prevent="submit">
        <woot-input
          v-model.trim="app.title"
          :class="{ error: $v.app.title.$error }"
          class="medium-12 columns"
          :label="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.TITLE_LABEL')"
          :placeholder="
            $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.TITLE_PLACEHOLDER')
          "
          :error="
            $v.app.title.$error
              ? $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.TITLE_ERROR')
              : null
          "
          data-testid="app-title"
          @input="$v.app.title.$touch"
        />
        <div
          v-for="(item, i) in app.content"
          :key="i"
          class="content-row"
          :set="(v = $v.app.content.$each[i])"
        >
          <woot-input
            v-model.trim="item.url"
            :class="{ error: v.url.$error }"
            class="medium-12 columns app--url_input"
            :label="$t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.URL_LABEL')"
            :placeholder="
              $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.URL_PLACEHOLDER')
            "
            :error="
              v.url.$error
                ? $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.FORM.URL_ERROR')
                : null
            "
            data-testid="app-url"
            @input="v.url.$touch"
          />
          <woot-button
            v-if="app.content.length > 1"
            variant="smooth"
            color-scheme="alert"
            icon="delete"
            class="app--url_add_btn"
            type="button"
            @click="removeFrame(i)"
          />
          <woot-button
            variant="smooth"
            color-scheme="secondary"
            icon="add"
            class="app--url_add_btn"
            type="button"
            @click="addNewFrame"
          />
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-button :is-disabled="$v.$invalid" data-testid="label-submit">
              {{ submitButtonLabel }}
            </woot-button>
            <woot-button class="button clear" @click.prevent="closeModal">
              {{ $t('INTEGRATION_SETTINGS.DASHBOARD_APPS.CREATE.FORM_CANCEL') }}
            </woot-button>
          </div>
        </div>
      </form>
    </div>
  </woot-modal>
</template>

<script>
import { required, url } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
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
      title: {
        required,
      },
      content: {
        $each: {
          type: { required },
          url: { required, url },
        },
      },
    },
  },
  data() {
    return {
      app: {
        title: '',
        content: [
          {
            type: 'frame',
            url: '',
          },
        ],
      },
    };
  },
  computed: {
    header() {
      return this.$t(`INTEGRATION_SETTINGS.DASHBOARD_APPS.${this.mode}.HEADER`);
    },
    submitButtonLabel() {
      return this.$t(
        `INTEGRATION_SETTINGS.DASHBOARD_APPS.${this.mode}.FORM_SUBMIT`
      );
    },
  },
  mounted() {
    if (this.mode === 'UPDATE' && this.selectedAppData) {
      this.app = this.selectedAppData;
    }
  },
  methods: {
    getUrlErrorMessage() {},
    addNewFrame() {
      this.app.content.push({
        type: 'frame',
        url: '',
      });
    },
    removeFrame(i) {
      this.app.content.splice(i, 1);
    },
    closeModal() {
      this.$emit('close');
    },
    async submit() {
      try {
        this.$v.$touch();
        if (this.$v.$invalid) return;
        const action = this.mode === 'UPDATE' ? 'update' : 'create';
        await this.$store.dispatch(`dashboardApps/${action}`, this.app);
        this.showAlert(
          this.$t(
            `INTEGRATION_SETTINGS.DASHBOARD_APPS.${this.mode}.API_SUCCESS`
          )
        );
        this.closeModal();
      } catch (err) {
        this.showAlert(
          this.$t(`INTEGRATION_SETTINGS.DASHBOARD_APPS.${this.mode}.API_ERROR`)
        );
      }
    },
  },
};
</script>

<style scoped lang="scss">
.content-row {
  display: flex;
  align-items: center;
  width: 100%;
  .app--url_input {
    flex: 1;
  }
  .app--url_add_btn {
    margin-left: var(--space-one);
    margin-top: var(--space-one);
  }
}
</style>
