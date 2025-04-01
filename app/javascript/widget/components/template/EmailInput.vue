<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { required, email } from '@vuelidate/validators';
import { getContrastingTextColor } from '@chatwoot/utils';

import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import Spinner from 'shared/components/Spinner.vue';

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
    return { v$: useVuelidate() };
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
        type="email"
        :placeholder="$t('EMAIL_PLACEHOLDER')"
        :class="{ error: v$.email.$error }"
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
.email-input-group {
  input {
    @apply dark:bg-n-alpha-black1 rtl:rounded-tl-[0] ltr:rounded-tr-[0] rtl:rounded-bl-[0] ltr:rounded-br-[0] p-2.5 w-full focus:ring-0 focus:outline-n-brand;

    &::placeholder {
      @apply text-n-slate-10;
    }

    &.error {
      @apply outline-n-ruby-8 dark:outline-n-ruby-8 hover:outline-n-ruby-9 dark:hover:outline-n-ruby-9;
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
