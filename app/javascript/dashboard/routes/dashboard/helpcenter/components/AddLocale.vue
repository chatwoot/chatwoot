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
              v-for="item in allLocales"
              :key="item.name"
              :value="item.id"
            >
              {{ item.name }}
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
import { convertToPortalSlug } from 'dashboard/helper/commons.js';
import allLocales from 'shared/constants/locales.js';
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
    portalId: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      selectedLocale: '',
    };
  },
  computed: {
    allLocales() {
      return Object.keys(allLocales).map(key => {
        return {
          id: key,
          name: allLocales[key],
        };
      });
    },
  },
  validations: {
    selectedLocale: {
      required,
    },
  },
  methods: {
    onNameChange() {
      this.slug = convertToPortalSlug(this.name);
    },
    async onCreate() {
      this.$v.$touch();
      // if (this.$v.$invalid) {
      //   return;
      // }
      // console.log('onCreate', this.selectedLocale);

      // try {
      //   await this.$store.dispatch('portals/create', {
      //     portal: {
      //       name: this.name,
      //       slug: this.slug,
      //       custom_domain: this.domain,
      //       // TODO: add support for choosing color
      //       color: '#1f93ff',
      //       homepage_link: this.homePageLink,
      //       page_title: this.pageTitle,
      //       header_text: this.headerText,
      //       config: {
      //         // TODO: add support for choosing locale
      //         allowed_locales: ['en'],
      //       },
      //     },
      //   });
      //   this.alertMessage = this.$t(
      //     'HELP_CENTER.PORTAL.ADD.API.SUCCESS_MESSAGE'
      //   );
      //   this.$emit('cancel');
      // } catch (error) {
      //   this.alertMessage =
      //     error?.message || this.$t('HELP_CENTER.PORTAL.ADD.API.ERROR_MESSAGE');
      // } finally {
      //   this.showAlert(this.alertMessage);
      // }
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
