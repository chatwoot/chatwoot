<template>
  <resizable-textarea>
    <textarea
      class="form-input user-message-input"
      :placeholder="placeholder"
      :value="value"
      @input="$emit('input', $event.target.value)"
    />
  </resizable-textarea>
</template>

<script>
import ResizableTextarea from 'widget/components/ResizableTextarea.vue';

export default {
  components: {
    ResizableTextarea,
  },
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
  border: 0;
  height: $space-large;
  resize: none;
  padding-top: $space-small;
}
</style>
