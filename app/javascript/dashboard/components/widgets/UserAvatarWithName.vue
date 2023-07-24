<template>
  <div class="row--user-block">
    <thumbnail
      :src="user.thumbnail"
      :size="size"
      :username="user.name"
      :status="user.availability_status"
    />
    <h6
      class="text-block-title user-name overflow-hidden whitespace-nowrap text-ellipsis text-capitalize"
    >
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
  @apply items-center flex text-left;

  .user-name {
    @apply my-0 mx-2 text-slate-700 dark:text-slate-100;
  }
}
</style>
