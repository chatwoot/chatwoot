<template>
  <div class="option-item--user">
    <thumbnail :src="thumbnail" size="24px" :username="name" />
    <span class="option__title">
      {{ name }}
    </span>
  </div>
</template>

<script>
export default {
  props: {
    name: {
      type: String,
      default: '',
    },
    thumbnail: {
      type: String,
      default: '',
    },
  },
};
</script>

<style lang="scss" scoped>
.option-item--user {
  display: flex;
}
</style>
