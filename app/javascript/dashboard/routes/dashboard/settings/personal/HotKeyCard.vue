<template>
  <div
    class="flex flex-col min-w-[15rem] max-h-[21.25rem] sm:w-[23rem] rounded-md border border-solid border-ash-200"
    :class="{
      'border border-solid border-primary-300 ': active,
    }"
  >
    <div
      class="flex justify-between items-center px-2 w-full h-10 rounded-t-[5px]"
    >
      <div class="flex items-center p-1 text-base font-medium text-ash-900">
        {{ heading }}
      </div>
      <div>
        <!-- Show radio button, if the card is active, set radio button checked -->
        <input
          :checked="active"
          type="radio"
          name="hotkey"
          @change="$emit('update', 'enter')"
        />
      </div>
    </div>
    <div
      class="text-slate-700 dark:text-slate-200 text-sm leading-[1.4] px-3 pb-0 text-start"
    >
      {{ content }}
    </div>
    <div v-if="src" class="p-3">
      <img :src="src" class="object-cover w-full" />
    </div>
    <slot v-else />
  </div>
</template>

<script>
export default {
  props: {
    active: {
      type: Boolean,
      default: false,
    },
    heading: {
      type: String,
      default: '',
    },
    content: {
      type: String,
      default: '',
    },
    src: {
      type: String,
      default: '',
    },
  },
};
</script>
