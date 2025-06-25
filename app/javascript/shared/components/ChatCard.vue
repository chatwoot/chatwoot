<script>
import CardButton from 'shared/components/CardButton.vue';

export default {
  components: {
    CardButton,
  },
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
    :class="$dm('bg-white', 'dark:bg-slate-700')"
  >
    <img v-if="mediaUrl" class="media" :src="mediaUrl" />
    <div class="card-body">
      <h4
        v-if="title"
        class="title"
        :class="$dm('text-black-900', 'dark:text-slate-50')"
      >
        {{ title }}
      </h4>
      <p class="body" :class="$dm('text-black-900', 'dark:text-slate-100')">
        {{ description }}
      </p>
      <CardButton v-for="action in actions" :key="action.id" :action="action" />
    </div>
  </div>
</template>

<style scoped lang="scss">
@import 'widget/assets/scss/_variables.scss';
@import 'dashboard/assets/scss/_mixins.scss';

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
    border: 1px solid #e0e0e0;
    width: 100%;
    object-fit: contain;
    max-height: 150px;
    border-radius: 5px;
  }

  .action-button + .action-button {
    background: $color-white;
    border: 1px solid $color-woot;
    color: $color-woot;
  }
}
</style>
