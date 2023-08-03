<template>
  <div class="flex items-center text-left">
    <thumbnail
      :src="user.thumbnail"
      :size="size"
      :username="user.name"
      :status="user.availability_status"
    />
    <h6
      class="text-xs my-0 mx-2 text-slate-600 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis text-capitalize"
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
