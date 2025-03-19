<template>
  <div>
    <form
      v-if="!hasSubmitted"
      class="phone-input-group"
      @submit.prevent="onSubmit"
    >
      <input
        v-model.trim="phone"
        class="form-input"
        :placeholder="'Please enter your phone'"
        :class="inputHasError"
        @input="$v.phone.$touch"
        @keydown.enter="onSubmit"
      />
      <button
        class="button small"
        :disabled="$v.phone.$invalid"
        :style="{
          background: widgetColor,
          borderColor: widgetColor,
          color: textColor,
        }"
      >
        <fluent-icon v-if="!isUpdating" icon="chevron-right" />
        <spinner v-else class="mx-2" />
      </button>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { required } from 'vuelidate/lib/validators';
import { getContrastingTextColor } from '@chatwoot/utils';

import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import Spinner from 'shared/components/Spinner.vue';
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
      phone: '',
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
        this.messageContentAttributes.submitted_phone
      );
    },
    inputColor() {
      return `${this.$dm('bg-white', 'dark:bg-slate-600')}
        ${this.$dm('text-black-900', 'dark:text-slate-50')}
        ${this.$dm('border-black-200', 'dark:border-black-500')}`;
    },
    inputHasError() {
      return this.$v.phone.$error
        ? `${this.inputColor} error`
        : `${this.inputColor}`;
    },
  },
  validations: {
    phone: {
      required,
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
          phone: this.phone,
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
@import '~widget/assets/scss/variables.scss';

.phone-input-group {
  display: flex;
  margin: $space-small 0;
  min-width: 200px;

  input {
    border-bottom-right-radius: 0;
    border-top-right-radius: 0;
    padding: $space-one;
    width: 100%;

    &::placeholder {
      color: $color-light-gray;
    }

    &.error {
      border-color: $color-error;
    }
  }

  .button {
    border-bottom-left-radius: 0;
    border-top-left-radius: 0;
    font-size: $font-size-large;
    height: auto;
    margin-left: -1px;

    .spinner {
      display: block;
      padding: 0;
      height: auto;
      width: auto;
    }
  }
}
</style>
