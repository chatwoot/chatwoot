<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { required, email } from '@vuelidate/validators';
import { getContrastingTextColor } from '@chatwoot/utils';

import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import Spinner from 'shared/components/Spinner.vue';
import { useDarkMode } from 'widget/composables/useDarkMode';

export default {
  components: {
    FluentIcon,
    Spinner,
  },
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
  setup() {
    const { getThemeClass } = useDarkMode();
    return { v$: useVuelidate(), getThemeClass };
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
      return `${this.getThemeClass('bg-white', 'dark:bg-slate-600')}
        ${this.getThemeClass('text-black-900', 'dark:text-slate-50')}
        ${this.getThemeClass('border-black-200', 'dark:border-black-500')}`;
    },
    inputHasError() {
      return this.v$.email.$error
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
      if (this.v$.$invalid) {
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

<template>
  <div>
    <form
      v-if="!hasSubmitted"
      class="email-input-group h-10 flex my-2 mx-0 min-w-[200px]"
      @submit.prevent="onSubmit"
    >
      <input
        v-model="email"
        :placeholder="$t('EMAIL_PLACEHOLDER')"
        :class="inputHasError"
        @input="v$.email.$touch"
        @keydown.enter="onSubmit"
      />
      <button
        class="button small"
        :disabled="v$.email.$invalid"
        :style="{
          background: widgetColor,
          borderColor: widgetColor,
          color: textColor,
        }"
      >
        <FluentIcon v-if="!isUpdating" icon="chevron-right" />
        <Spinner v-else class="mx-2" />
      </button>
    </form>
  </div>
</template>

<style lang="scss" scoped>
@import 'widget/assets/scss/variables.scss';

.email-input-group {
  input {
    @apply border border-n-weak rtl:rounded-tl-[0] ltr:rounded-tr-[0] rtl:rounded-bl-[0] ltr:rounded-br-[0] p-2.5 w-full focus:ring-0 focus:border-n-brand;

    &::placeholder {
      @apply text-n-slate-10;
    }

    &.error {
      @apply border border-n-ruby-8 dark:border-n-ruby-8 hover:border-n-ruby-9 dark:hover:border-n-ruby-9;
    }
  }

  .button {
    @apply rtl:rounded-tr-[0] ltr:rounded-tl-[0] rtl:rounded-br-[0] ltr:rounded-bl-[0] rounded-lg h-auto ltr:-ml-px rtl:-mr-px text-xl;

    .spinner {
      display: block;
      padding: 0;
      height: auto;
      width: auto;
    }
  }
}
</style>
