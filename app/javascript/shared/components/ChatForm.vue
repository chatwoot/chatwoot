<template>
  <div class="form chat-bubble agent">
    <form @submit.prevent="onSubmit">
      <div v-for="item in items" :key="item.key" class="form-block">
        <label>{{ item.label }}</label>
        <input
          v-if="item.type === 'email' || item.type === 'text'"
          v-model="formValues[item.name]"
          :type="item.type"
          :name="item.name"
          :placeholder="item.placeholder"
          :disabled="!!submittedValues.length"
        />
        <textarea
          v-else-if="item.type === 'text_area'"
          v-model="formValues[item.name]"
          :name="item.name"
          :placeholder="item.placeholder"
          :disabled="!!submittedValues.length"
        />
      </div>
      <button
        v-if="!submittedValues.length"
        class="button small block"
        type="submit"
        :disabled="!isFormValid"
      >
        {{ $t('COMPONENTS.FORM_BUBBLE.SUBMIT') }}
      </button>
    </form>
  </div>
</template>

<script>
export default {
  props: {
    items: {
      type: Array,
      default: () => [],
    },
    submittedValues: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      formValues: {},
    };
  },
  computed: {
    isFormValid() {
      return this.items.reduce((acc, { name }) => {
        return !!this.formValues[name] && acc;
      }, true);
    },
  },
  mounted() {
    this.updateFormValues();
  },
  methods: {
    onSubmit() {
      if (!this.isFormValid) {
        return;
      }
      this.$emit('submit', this.formValues);
    },
    updateFormValues() {
      this.formValues = this.submittedValues.reduce((acc, obj) => {
        return {
          ...acc,
          [obj.name]: obj.value,
        };
      }, {});
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.form {
  padding: $space-normal;
  width: 100%;

  .form-block {
    max-width: 100%;
    padding-bottom: $space-small;
  }

  label {
    display: block;
    font-weight: $font-weight-bold;
    padding: $space-smaller 0;
    text-transform: capitalize;
  }

  input,
  textarea {
    border-radius: $space-smaller;
    border: 1px solid $color-border;
    display: block;
    font-size: $font-size-default;
    line-height: 1.5;
    padding: $space-smaller $space-small;
    width: 90%;

    &:disabled {
      background: $color-background-light;
    }
  }
}
</style>
