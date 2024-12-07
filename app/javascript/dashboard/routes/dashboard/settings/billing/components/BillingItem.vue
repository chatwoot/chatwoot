<script>
export default {
  props: {
    title: {
      type: String,
      default: '',
    },
    description: {
      type: String,
      default: '',
    },
    buttonLabel: {
      type: String,
      default: '',
    },

    buttonIcon: {
      type: String,
      default: 'edit',
    },
  },
  emits: ['open'],
};
</script>

<template>
  <div class="manage-subscription">
    <div>
      <h6>{{ title }}</h6>
      <p class="manage-subscription--description">
        {{ description }}
      </p>
    </div>
    <div>
      <woot-button variant="smooth" :icon="buttonIcon" @click="$emit('open')">
        {{ buttonLabel }}
      </woot-button>
    </div>
  </div>
</template>
