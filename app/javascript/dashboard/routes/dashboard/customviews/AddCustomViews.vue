<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <woot-modal-header :header-title="$t('FILTER.CUSTOM_VIEWS.ADD.TITLE')" />
    <form class="row" @submit.prevent="saveCustomViews">
      <div class="medium-12 columns">
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

        <div class="modal-footer">
          <woot-submit-button
            :disabled="isButtonDisabled"
            :button-text="$t('FILTER.CUSTOM_VIEWS.ADD.SAVE')"
          />
          <button class="button clear" @click.prevent="onClose">
            {{ $t('FILTER.CUSTOM_VIEWS.ADD.CANCEL') }}
          </button>
        </div>
      </div>
    </form>
  </woot-modal>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator.js';

export default {
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
    resetData: {
      type: Function,
      default: () => {},
    },
  },

  data() {
    return {
      name: '',
      filterType: 0,
      show: true,
    };
  },

  computed: {
    ...mapGetters({
      uiFlags: 'getUIFlags',
      appliedFilters: 'getAppliedConversationFilters',
    }),
    customViewsQuery() {
      return filterQueryGenerator(this.appliedFilters);
    },
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
    async saveCustomViews() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('customViews/create', {
          name: this.name,
          filter_type: this.filterType,
          query: this.customViewsQuery,
        });
        this.alertMessage = this.$t(
          'FILTER.CUSTOM_VIEWS.ADD.API.SUCCESS_MESSAGE'
        );
        this.onClose();
        this.resetData();
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage || this.$t('FILTER.CUSTOM_VIEWS.ADD.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
  },
};
</script>
