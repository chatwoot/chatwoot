<template>
  <div class="form chat-bubble agent">
    <form @submit="onSubmit">
      <div v-for="item in items" :key="item.key" class="form-block">
        <label>{{ item.label }}</label>
        <input
          v-if="item.type === 'email' || item.type === 'text'"
          v-model="formValues[item.name]"
          :type="item.type"
          :name="item.name"
          :placeholder="item.placeholder"
        />
        <textarea
          v-if="item.type === 'text_area'"
          v-model="formValues[item.name]"
          :name="item.name"
          :placeholder="item.placeholder"
        />
      </div>
      <button class="button small block" type="submit">
        Submit
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
  },
  data() {
    return {
      formValues: {},
    };
  },
  methods: {
    onSubmit(e) {
      e.preventDefault();
      console.log(this.formValues);
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.form {
  padding: 16px;
  width: 100%;

  .form-block {
    max-width: 100%;
    padding-bottom: 8px;
  }

  label {
    display: block;
    font-weight: 600;
    padding: 4px 0;
    text-transform: capitalize;
  }

  input,
  textarea {
    display: block;

    width: 90%;
    padding: 4px 8px;
    line-height: 1.5;
    border-radius: 4px;
    border: 1px solid $color-border;
    font-size: $font-size-default;
  }
}
</style>
