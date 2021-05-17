<template>
  <div class="row--user-block">
    <Thumbnail
      :src="sender.thumbnail"
      size="20px"
      :username="sender.name"
      :status="sender.availability_status"
    />
    <div>
      <h6 class="text-block-title text-truncate">
        {{ sender.name }}
      </h6>
    </div>
  </div>
</template>
<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
export default {
  components: {
    Thumbnail,
  },
  props: {
    sender: {
      type: Object,
      default: () => {},
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/mixins';

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
