<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { CONTACTS_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';

export default {
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
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      show: true,
      name: '',
    };
  },

  computed: {
    isButtonDisabled() {
      return this.v$.name.$invalid;
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
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('customViews/create', {
          name: this.name,
          filter_type: this.filterType,
          query: this.customViewsQuery,
        });
        this.alertMessage =
          this.filterType === 0
            ? this.$t('FILTER.CUSTOM_VIEWS.ADD.API_FOLDERS.SUCCESS_MESSAGE')
            : this.$t('FILTER.CUSTOM_VIEWS.ADD.API_SEGMENTS.SUCCESS_MESSAGE');
        this.onClose();

        useTrack(CONTACTS_EVENTS.SAVE_FILTER, {
          type: this.filterType === 0 ? 'folder' : 'segment',
        });
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage || this.filterType === 0
            ? errorMessage
            : this.$t('FILTER.CUSTOM_VIEWS.ADD.API_SEGMENTS.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
      }
      this.openLastSavedItem();
    },
  },
};
</script>

<template>
  <woot-modal v-model:show="show" :on-close="onClose">
    <woot-modal-header :header-title="$t('FILTER.CUSTOM_VIEWS.ADD.TITLE')" />
    <form class="w-full" @submit.prevent="saveCustomViews">
      <div class="w-full">
        <woot-input
          v-model="name"
          :label="$t('FILTER.CUSTOM_VIEWS.ADD.LABEL')"
          type="text"
          :error="
            v$.name.$error ? $t('FILTER.CUSTOM_VIEWS.ADD.ERROR_MESSAGE') : ''
          "
          :class="{ error: v$.name.$error }"
          :placeholder="$t('FILTER.CUSTOM_VIEWS.ADD.PLACEHOLDER')"
          @blur="v$.name.$touch"
        />

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <woot-button :disabled="isButtonDisabled">
            {{ $t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON') }}
          </woot-button>
          <woot-button variant="clear" @click.prevent="onClose">
            {{ $t('FILTER.CUSTOM_VIEWS.ADD.CANCEL_BUTTON') }}
          </woot-button>
        </div>
      </div>
    </form>
  </woot-modal>
</template>
