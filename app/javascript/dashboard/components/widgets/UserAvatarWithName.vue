<template>
  <div class="row--user-block">
    <thumbnail
      :src="user.thumbnail"
      :size="size"
      :username="user.name"
      :status="user.availability_status"
    />
    <h6 class="text-block-title text-truncate text-capitalize">
      {{ user.name }}
    </h6>
  </div>
</template>
<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  components: {
    Thumbnail,
  },
  props: {
    user: {
      type: Object,
      default: () => {},
    },
    size: {
      type: String,
      default: '20px',
    },
  },
};
</script>

<style scoped lang="scss">
.row--user-block {
  align-items: center;
  display: flex;
  text-align: left;

  .user-name {
    margin: 0;
    text-transform: capitalize;
  }
  .user-thumbnail-box {
    margin-right: var(--space-small);
  }
}
</style>
