<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { CONTACTS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';
import Button from 'next/button/Button.vue';

export default {
  components: {
    Button,
  },
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
      outsideClickHandler: [
        () => this.emit('close'),
        { ignore: ['#saveFilterTeleportTarget'] },
      ],
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
  <div
    v-on-click-outside="outsideClickHandler"
    class="z-40 max-w-3xl lg:w-[500px] overflow-visible w-full border border-n-weak bg-n-alpha-3 backdrop-blur-[100px] shadow-lg rounded-xl p-6 grid gap-6"
  >
    <h3 class="text-base font-medium leading-6 text-n-slate-12">
      {{ $t('FILTER.CUSTOM_VIEWS.ADD.TITLE') }}
    </h3>
    <form class="w-full" @submit.prevent="saveCustomViews">
      <div class="w-full">
        <input
          v-model="name"
          class="py-1.5 px-3 text-n-slate-12 bg-n-alpha-1 text-sm rounded-lg reset-base w-full"
          :placeholder="$t('FILTER.CUSTOM_VIEWS.ADD.PLACEHOLDER')"
          @blur="v$.name.$touch"
        />
        <span
          v-if="v$.name.$error"
          class="text-xs text-n-ruby-11 ml-1 rtl:mr-1"
        >
          {{ $t('FILTER.CUSTOM_VIEWS.ADD.ERROR_MESSAGE') }}
        </span>
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <Button sm solid blue :disabled="isButtonDisabled">
            {{ $t('FILTER.CUSTOM_VIEWS.ADD.SAVE_BUTTON') }}
          </Button>
          <Button faded slate sm @click.prevent="onClose">
            {{ $t('FILTER.CUSTOM_VIEWS.ADD.CANCEL_BUTTON') }}
          </Button>
        </div>
      </div>
    </form>
  </div>
</template>
