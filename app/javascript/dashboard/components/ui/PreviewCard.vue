<template>
  <div
    class="flex flex-col min-w-[15rem] max-h-[21.25rem] w-[23rem] rounded-md border border-solid border-slate-75 dark:border-slate-600"
    :class="{
      'border border-solid border-woot-300 dark:border-woot-400': active,
    }"
  >
    <div
      class="flex justify-between items-center px-2 w-full h-10 rounded-t-[5px]"
    >
      <div class="flex items-center p-1 text-sm font-medium">{{ heading }}</div>
      <!-- <fluent-icon
        v-if="active"
        icon="checkmark-circle"
        type="solid"
        size="24"
        class="text-woot-500 dark:text-woot-500"
      /> -->
      <div>
        <input type="radio" name="hotkey" value="enter" :checked="active" />
      </div>
    </div>
    <div
      class="text-slate-700 dark:text-slate-200 text-xs leading-[1.4] px-3 pb-0 text-start"
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
    heading: {
      type: String,
      default: '',
    },
    content: {
      type: String,
      default: '',
    },
    active: {
      type: Boolean,
      default: false,
    },
    buttonText: {
      type: String,
      default: 'Active',
    },
    src: {
      type: String,
      default: '',
    },
  },
};
</script>
