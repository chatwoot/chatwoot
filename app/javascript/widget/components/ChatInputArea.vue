<template>
  <textarea
    class="form-input user-message-input"
    :placeholder="placeholder"
    :value="value"
    @input="$emit('input', $event.target.value)"
  />
</template>

<script>
export default {
  props: {
    placeholder: String,
    value: String,
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.user-message-input {
  border-color: $color-white;
  border-bottom-color: $color-border-light;
  height: $space-big;
  resize: none;
}
</style>
