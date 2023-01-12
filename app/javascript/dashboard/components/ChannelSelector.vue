<template>
  <button class="small-6 medium-4 large-3 channel" @click="$emit('click')">
    <img :src="src" :alt="title" />
    <h3 class="channel__title">
      {{ title }}
    </h3>
  </button>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    src: {
      type: String,
      required: true,
    },
  },
};
</script>

<style scoped lang="scss">
.inactive {
  filter: grayscale(100%);
}

.channel {
  background: var(--white);
  border: 1px solid var(--color-border-light);
  cursor: pointer;
  display: flex;
  flex-direction: column;
  margin: -1px;
  padding: var(--space-normal) 0;
  transition: all 0.2s ease-in;

  &:hover {
    border: 1px solid var(--w-500);
    box-shadow: var(--shadow-medium);
    z-index: var(--z-index-high);
  }

  &.disabled {
    opacity: 0.6;
  }

  img {
    margin: var(--space-normal) auto;
    width: 50%;
  }

  .channel__title {
    color: var(--color-body);
    font-size: var(--font-size-default);
    text-align: center;
    text-transform: capitalize;
  }

  p {
    color: var(--b-500);
    width: 100%;
  }
}
</style>
