<template>
  <div>
    <form
      v-if="!hasSubmitted"
      class="email-input-group"
      @submit.prevent="onSubmit()"
    >
      <input
        v-model.trim="email"
        class="form-input small"
        placeholder="Please enter your email"
        :class="{ error: $v.email.$error }"
        @input="$v.email.$touch"
      />
      <button
        class="button"
        :disabled="$v.email.$invalid"
        :style="{ background: widgetColor, borderColor: widgetColor }"
      >
        <i v-if="!uiFlags.isUpdating" class="ion-ios-arrow-forward" />
        <spinner v-else />
      </button>
    </form>
    <span v-else>
      <i>{{ messageContentAttributes.submitted_email }}</i>
    </span>
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
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contact/getUIFlags',
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
    onSubmit() {
      this.$store.dispatch('contact/updateContactAttributes', {
        email: this.email,
        messageId: this.messageId,
      });
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
    border-top-right-radius: 0;
    border-bottom-right-radius: 0;

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
