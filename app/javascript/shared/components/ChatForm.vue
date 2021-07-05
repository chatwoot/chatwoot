<template>
  <div class="form chat-bubble agent">
    <form @submit.prevent="onSubmit">
      <div
        v-for="item in items"
        :key="item.key"
        class="form-block"
        :class="{
          'has-submitted': hasSubmitted,
        }"
      >
        <label>{{ item.label }}</label>
        <input
          v-if="item.type === 'email'"
          v-model="formValues[item.name]"
          :type="item.type"
          :pattern="item.regex"
          :title="item.title"
          :required="item.required && 'required'"
          :name="item.name"
          :placeholder="item.placeholder"
          :disabled="!!submittedValues.length"
        />
        <input
          v-else-if="item.type === 'text'"
          v-model="formValues[item.name]"
          :required="item.required && 'required'"
          :pattern="item.pattern"
          :title="item.title"
          :type="item.type"
          :name="item.name"
          :placeholder="item.placeholder"
          :disabled="!!submittedValues.length"
        />
        <textarea
          v-else-if="item.type === 'text_area'"
          v-model="formValues[item.name]"
          :required="item.required && 'required'"
          :title="item.title"
          :name="item.name"
          :placeholder="item.placeholder"
          :disabled="!!submittedValues.length"
        />
        <select
          v-else-if="item.type === 'select'"
          v-model="formValues[item.name]"
          :required="item.required && 'required'"
        >
          <option
            v-for="option in item.options"
            :key="option.key"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>
        <span class="error-message">
          {{ item.pattern_error || $t('CHAT_FORM.INVALID.FIELD') }}
        </span>
      </div>
      <button
        v-if="!submittedValues.length"
        class="button block"
        type="submit"
        :style="{ background: widgetColor, borderColor: widgetColor }"
        @click="onSubmitClick"
      >
        {{ buttonLabel || $t('COMPONENTS.FORM_BUBBLE.SUBMIT') }}
      </button>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
export default {
  props: {
    buttonLabel: {
      type: String,
      default: '',
    },
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
      hasSubmitted: false,
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
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
    onSubmitClick() {
      this.hasSubmitted = true;
    },
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
    font-family: inherit;
    font-size: $font-size-default;
    line-height: 1.5;
    padding: $space-one;
    width: 100%;

    &:disabled {
      background: $color-background-light;
    }
  }

  textarea {
    resize: none;
  }

  select {
    width: 110%;
    padding: $space-smaller;
    -webkit-appearance: none;
    -moz-appearance: none;
    appearance: none;
    border: 1px solid $color-border;
    border-radius: $space-smaller;
    background-color: $color-white;
    font-family: inherit;
    font-size: $space-normal;
    font-weight: normal;
    line-height: 1.5;
    background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='32' height='24' viewBox='0 0 32 24'><polygon points='0,0 32,0 16,24' style='fill: rgb%28110, 111, 115%29'></polygon></svg>");
    background-origin: content-box;
    background-position: right -1.6rem center;
    background-repeat: no-repeat;
    background-size: 9px 6px;
    padding-right: 2.4rem;
  }

  .button {
    font-size: $font-size-default;
  }

  .error-message {
    display: none;
    margin-top: $space-smaller;
    color: $color-error;
  }

  .has-submitted {
    input:invalid {
      border: 1px solid $color-error;
    }

    input:invalid + .error-message {
      display: block;
    }

    textarea:invalid {
      border: 1px solid $color-error;
    }

    textarea:invalid + .error-message {
      display: block;
    }
  }
}
</style>
