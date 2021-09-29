<template>
  <li class="py-4">
    <div class="flex items-center space-x-4">
      <div class="flex-shrink-0">
        <div class="h-8 w-8 rounded-full">
          <thumbnail
            src="https://images.unsplash.com/photo-1519345182560-3f2917c472ef?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
            size="24px"
            username="Erin Lindford"
          />
        </div>
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-gray-900 truncate">
          Leonard Krasner
        </p>
        <p class="text-sm text-gray-500 truncate">
          @leonardkrasner
        </p>
      </div>
      <div>
        <a
          href="#"
          class="inline-flex items-center shadow-sm px-2.5 py-0.5 border border-gray-300 text-sm leading-5 font-medium rounded-full text-gray-700 bg-white hover:bg-gray-50"
        >
          View
        </a>
      </div>
    </div>
  </li>
</template>
<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail';

export default {
  components: { Thumbnail },
  props: {
    conversation: {
      type: Object,
      default: () => ({}),
    },
  },
  setup(props) {
    console.log(props);
  },
};
</script>
