<template>
  <modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('HELP_CENTER.PORTAL.ADD_LOCALE.TITLE')"
      :header-content="$t('HELP_CENTER.PORTAL.ADD_LOCALE.SUB_TITLE')"
    />
    <form class="row" @submit.prevent="onCreate">
      <div class="medium-12 columns">
        <label :class="{ error: $v.selectedLocale.$error }">
          {{ $t('HELP_CENTER.PORTAL.ADD_LOCALE.LOCALE.LABEL') }}
          <select v-model="selectedLocale">
            <option
              v-for="locale in locales"
              :key="locale.name"
              :value="locale.id"
            >
              {{ locale.name }}-{{ locale.code }}
            </option>
          </select>
          <span v-if="$v.selectedLocale.$error" class="message">
            {{ $t('HELP_CENTER.PORTAL.ADD_LOCALE.LOCALE.ERROR') }}
          </span>
        </label>

        <div class="medium-12 columns">
          <div class="modal-footer justify-content-end w-full">
            <woot-button class="button clear" @click.prevent="onClose">
              {{ $t('HELP_CENTER.PORTAL.ADD_LOCALE.BUTTONS.CANCEL') }}
            </woot-button>
            <woot-button>
              {{ $t('HELP_CENTER.PORTAL.ADD_LOCALE.BUTTONS.CREATE') }}
            </woot-button>
          </div>
        </div>
      </div>
    </form>
  </modal>
</template>

<script>
import Modal from 'dashboard/components/Modal';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import allLocales from 'shared/constants/locales.js';
import { PORTALS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
export default {
  components: {
    Modal,
  },
  mixins: [alertMixin],
  props: {
    show: {
      type: Boolean,
      default: true,
    },
    portal: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      selectedLocale: '',
      isUpdating: false,
    };
  },
  computed: {
    addedLocales() {
      const { allowed_locales: allowedLocales } = this.portal.config;
      return allowedLocales.map(locale => locale.code);
    },
    locales() {
      const addedLocales = this.portal.config.allowed_locales.map(
        locale => locale.code
      );
      return Object.keys(allLocales)
        .map(key => {
          return {
            id: key,
            name: allLocales[key],
            code: key,
          };
        })
        .filter(locale => {
          return !addedLocales.includes(locale.code);
        });
    },
  },
  validations: {
    selectedLocale: {
      required,
    },
  },
  methods: {
    async onCreate() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      const updatedLocales = this.addedLocales;
      updatedLocales.push(this.selectedLocale);
      this.isUpdating = true;
      try {
        await this.$store.dispatch('portals/update', {
          portalSlug: this.portal.slug,
          config: { allowed_locales: updatedLocales },
        });
        this.alertMessage = this.$t(
          'HELP_CENTER.PORTAL.ADD_LOCALE.API.SUCCESS_MESSAGE'
        );
        this.onClose();
        this.$track(PORTALS_EVENTS.CREATE_LOCALE, {
          localeAdded: this.selectedLocale,
          totalLocales: updatedLocales.length,
          from: this.$route.name,
        });
      } catch (error) {
        this.alertMessage =
          error?.message ||
          this.$t('HELP_CENTER.PORTAL.ADD_LOCALE.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
        this.isUpdating = false;
      }
    },
    onClose() {
      this.$emit('cancel');
    },
  },
};
</script>
<style scoped lang="scss">
.input-container::v-deep {
  margin: 0 0 var(--space-normal);

  input {
    margin-bottom: 0;
  }
  .message {
    margin-top: 0;
  }
}
</style>
