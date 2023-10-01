<template>
  <div class="flex">
    <span
      v-for="(user, index) in users"
      :key="user.id"
      :class="`${
        index ? '-ml-4' : ''
      } inline-block rounded-full text-white shadow-solid`"
    >
      <thumbnail
        size="36px"
        :username="user.name"
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
