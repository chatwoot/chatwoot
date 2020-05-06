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
        class="button block"
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
    if (this.submittedValues.length) {
      this.updateFormValues();
    } else {
      this.setFormDefaults();
    }
  },
  methods: {
    onSubmit() {
      if (!this.isFormValid) {
        return;
      }
      this.$emit('submit', this.formValues);
    },
    buildFormObject(formObjectArray) {
      return formObjectArray.reduce((acc, obj) => {
        return {
          ...acc,
          [obj.name]: obj.value || obj.default,
        };
      }, {});
    },
    updateFormValues() {
      this.formValues = this.buildFormObject(this.submittedValues);
    },
    setFormDefaults() {
      this.formValues = this.buildFormObject(this.items);
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.form {
  padding: $space-normal;
  width: 80%;

  .form-block {
    width: 90%;
    padding-bottom: $space-small;
  }

  label {
    display: block;
    font-weight: $font-weight-medium;
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
    padding: $space-one;
    width: 100%;

    &:disabled {
      background: $color-background-light;
    }
  }

  .button {
    font-size: $font-size-default;
  }
}
</style>
