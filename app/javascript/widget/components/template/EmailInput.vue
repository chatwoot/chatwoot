<template>
  <div>
    <form
      v-if="!hasSubmitted"
      class="email-input-group"
      @submit.prevent="onSubmit()"
    >
      <input
        v-model.trim="email"
        class="form-input"
        :placeholder="$t('EMAIL_PLACEHOLDER')"
        :class="{ error: $v.email.$error }"
        @input="$v.email.$touch"
        @keyup.enter="onSubmit"
      />
      <button
        class="button"
        :disabled="$v.email.$invalid"
        :style="{ background: widgetColor, borderColor: widgetColor }"
      >
        <i v-if="!isUpdating" class="ion-ios-arrow-forward" />
        <spinner v-else />
      </button>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner';
import { required, email } from 'vuelidate/lib/validators';

export default {
  components: {
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
@import '~widget/assets/scss/variables.scss';

.email-input-group {
  display: flex;
  margin: $space-small 0;
  min-width: 200px;

  input {
    border-bottom-right-radius: 0;
    border-top-right-radius: 0;
    padding: $space-one;
    width: auto;

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
