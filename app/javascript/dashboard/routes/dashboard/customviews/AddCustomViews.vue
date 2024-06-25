<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <woot-modal-header :header-title="$t('FILTER.CUSTOM_VIEWS.ADD.TITLE')" />
    <form class="w-full" @submit.prevent="saveCustomViews">
      <div class="gap-2 flex flex-row">
        <div class="w-[70%]">
          <woot-input
            v-model="name"
            :label="$t('FILTER.CUSTOM_VIEWS.ADD.LABEL')"
            type="text"
            :error="
              $v.name.$error ? $t('FILTER.CUSTOM_VIEWS.ADD.ERROR_MESSAGE') : ''
            "
            :class="{ error: $v.name.$error }"
            :placeholder="$t('FILTER.CUSTOM_VIEWS.ADD.PLACEHOLDER')"
            @blur="$v.name.$touch"
          />
        </div>
        <div v-if="isAdmin" class="w-[30%] text-right">
          <label class="input-label">
            {{ $t('CONTACTS_FILTER.ACCOUNT_SCOPED_LABEL') }}
          </label>
          <input v-model="accountScoped" type="checkbox" class="text-right" />
        </div>
      </div>
      <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
        <woot-button :disabled="isButtonDisabled">
          {{ $t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON') }}
        </woot-button>
        <woot-button variant="clear" @click.prevent="onClose">
          {{ $t('FILTER.CUSTOM_VIEWS.ADD.CANCEL_BUTTON') }}
        </woot-button>
      </div>
    </form>
  </woot-modal>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import adminMixin from 'dashboard/mixins/isAdmin';
import { CONTACTS_EVENTS } from '../../../helper/AnalyticsHelper/events';

export default {
  mixins: [alertMixin, adminMixin],
  props: {
    filterType: {
      type: Number,
      default: 0,
    },
    customViewsQuery: {
      type: Object,
      default: () => {},
    },
    openLastSavedItem: {
      type: Function,
      default: () => {},
    },
  },

  data() {
    return {
      show: true,
      name: '',
      accountScoped: false,
    };
  },

  computed: {
    isButtonDisabled() {
      return this.$v.name.$invalid;
    },
  },

  validations: {
    name: {
      required,
      minLength: minLength(1),
    },
  },

  methods: {
    onClose() {
      this.$emit('close');
    },
    async saveCustomViews() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('customViews/create', {
          name: this.name,
          account_scoped: this.accountScoped,
          filter_type: this.filterType,
          query: this.customViewsQuery,
        });
        this.alertMessage =
          this.filterType === 0
            ? this.$t('FILTER.CUSTOM_VIEWS.ADD.API_FOLDERS.SUCCESS_MESSAGE')
            : this.$t('FILTER.CUSTOM_VIEWS.ADD.API_SEGMENTS.SUCCESS_MESSAGE');
        this.onClose();

        this.$track(CONTACTS_EVENTS.SAVE_FILTER, {
          type: this.filterType === 0 ? 'folder' : 'segment',
        });
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage || this.filterType === 0
            ? errorMessage
            : this.$t('FILTER.CUSTOM_VIEWS.ADD.API_SEGMENTS.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
      this.openLastSavedItem();
    },
  },
};
</script>
