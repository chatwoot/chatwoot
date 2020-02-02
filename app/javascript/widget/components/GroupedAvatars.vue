<template>
  <div class="avatars">
    <span class="avatar">
      <img src="https://picsum.photos/70" />
    </span>
    <span class="avatar">
      <img src="https://picsum.photos/80" />
    </span>
    <span class="avatar">
      <img src="https://picsum.photos/90" />
    </span>
  </div>
</template>

<script>
export default {
  name: 'GroupedAvatars',
  props: {
    photos: {
      type: Array,
      default: () => [],
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.avatars {
  display: inline-block;
  transform: scale(-1, 1);

  .avatar {
    margin-left: -$space-two;
    position: relative;
    display: inline-block;
    border: 1px solid #fff;
    border-radius: 50%;
    overflow: hidden;
    width: $space-medium;
    height: $space-medium;
  }
  .avatar img {
    width: $space-medium;
    height: $space-medium;
    transform: scale(-1, 1);
  }
}
</style>
