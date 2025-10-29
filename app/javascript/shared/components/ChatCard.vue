<script>
import CardButton from 'shared/components/CardButton.vue';
import darkModeMixin from '../../widget/mixins/darkModeMixin';

export default {
  components: {
    CardButton,
  },
  mixins: [darkModeMixin],
  props: {
    title: {
      type: String,
      default: '',
    },
    description: {
      type: String,
      default: '',
    },
    mediaUrl: {
      type: String,
      default: '',
    },
    actions: {
      type: Array,
      default: () => [],
    },
  },
};
</script>

<template>
  <div
    class="card-message chat-bubble agent"
    :class="dm('bg-white', 'dark:bg-slate-700')"
  >
    <img v-if="mediaUrl" class="media" :src="mediaUrl" />
    <div class="card-body">
      <h4
        v-if="title"
        class="title"
        :class="dm('text-black-900', 'dark:text-slate-50')"
      >
        {{ title }}
      </h4>
      <p class="body" :class="dm('text-black-900', 'dark:text-slate-100')">
        {{ description }}
      </p>
      <CardButton v-for="action in actions" :key="action.id" :action="action" />
    </div>
  </div>
</template>

<style scoped lang="scss">
@import 'widget/assets/scss/variables';
@import 'dashboard/assets/scss/mixins';

.card-message {
  padding: $space-small;
  border-radius: $space-small;
  overflow: hidden;

  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-medium;
    margin-top: $space-smaller;
    margin-bottom: $space-smaller;
    line-height: 1.5;
  }

  .body {
    margin-bottom: $space-smaller;
  }

  .media {
    @include border-light;
    width: 100%;
    object-fit: contain;
    max-height: 150px;
    border-radius: 5px;
  }

  .action-button + .action-button {
    background: $color-white;
    @include thin-border($color-woot);
    color: $color-woot;
  }
}
</style>
