<template>
  <div
    class="options-message chat-bubble agent"
    :class="$dm('bg-white', 'dark:bg-slate-700')"
  >
    <div class="card-body">
      <h4 class="title" :class="$dm('text-black-900', 'dark:text-slate-50')">
        {{ title }}
      </h4>
    </div>
  </div>
</template>

<script>
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  mixins: [darkModeMixin],
  props: {
    title: {
      type: String,
      default: '',
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.options-message {
  max-width: 17rem;
  padding: $space-small $space-normal;
  border-radius: $space-small;
  overflow: hidden;

  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-normal;
    margin-top: $space-smaller;
    margin-bottom: $space-smaller;
    line-height: 1.5;
  }
}
</style>
