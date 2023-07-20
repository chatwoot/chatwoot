<template>
  <div>
    <form
      v-if="!hasSubmitted"
      class="email-input-group"
      @submit.prevent="onSubmit"
    >
      <div class="mt-2 flex rounded-md shadow-sm">
        <div class="relative flex flex-grow items-stretch focus-within:z-10">
          <input
            v-model.trim="email"
            type="email"
            class="block w-full rounded-none rounded-l-md border-0 py-2 px-2 text-slate-900 ring-1 ring-inset ring-slate-300 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600"
            :placeholder="$t('EMAIL_PLACEHOLDER')"
            :class="inputHasError"
            @input="$v.email.$touch"
            @keydown.enter="onSubmit"
          />
        </div>
        <button
          type="button"
          class="relative -ml-px inline-flex items-center gap-x-1.5 rounded-r-md px-3 py-2 text-sm font-semibold text-white hover:bg-slate-50"
          :disabled="$v.email.$invalid"
          :style="{
            background: widgetColor,
            borderColor: widgetColor,
            color: textColor,
          }"
        >
          <fluent-icon v-if="!isUpdating" icon="chevron-right" />
          <spinner v-else class="mx-2" />
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { required, email } from 'vuelidate/lib/validators';
import { getContrastingTextColor } from '@chatwoot/utils';

import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import Spinner from 'shared/components/Spinner';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  components: {
    FluentIcon,
    Spinner,
  },
  mixins: [darkModeMixin],
  props: {
    messageId: {
      type: Number,
      required: true,
    },
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      email: '',
      isUpdating: false,
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    hasSubmitted() {
      return (
        this.messageContentAttributes &&
        this.messageContentAttributes.submitted_email
      );
    },
    inputColor() {
      return `${this.$dm('bg-white', 'dark:bg-slate-600')}
        ${this.$dm('text-black-900', 'dark:text-slate-50')}
        ${this.$dm('border-black-200', 'dark:border-black-500')}`;
    },
    inputHasError() {
      return this.$v.email.$error
        ? `${this.inputColor} error`
        : `${this.inputColor}`;
    },
  },
  validations: {
    email: {
      required,
      email,
    },
  },
  methods: {
    async onSubmit() {
      if (this.$v.$invalid) {
        return;
      }
      this.isUpdating = true;
      try {
        await this.$store.dispatch('message/update', {
          email: this.email,
          messageId: this.messageId,
        });
      } catch (error) {
        // Ignore error
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.email-input-group {
}
</style>
