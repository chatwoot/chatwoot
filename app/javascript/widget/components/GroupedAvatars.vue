<template>
  <div class="avatars">
    <span v-for="user in users" :key="user.id" class="avatar">
      <Thumbnail
        size="24px"
        :username="user.name"
        status="online"
        :src="user.avatar"
        has-border
      />
    </span>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  name: 'GroupedAvatars',
  components: { Thumbnail },
  props: {
    users: {
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
  padding-left: $space-one;

  .avatar {
    margin-left: -$space-slab;
    position: relative;
    display: inline-block;
    overflow: hidden;
    width: $space-medium;
    height: $space-medium;
  }
}
</style>
