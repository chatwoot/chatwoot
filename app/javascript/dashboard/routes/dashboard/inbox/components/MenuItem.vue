<script setup>
defineProps({
  label: {
    type: String,
    default: '',
  },
});

const emits = defineEmits(['click']);

const onMenuItemClick = () => {
  emits('click');
};
</script>
<template>
  <div
    role="button"
    class="py-1 px-2 w-full h-8 font-medium text-xs text-slate-800 dark:text-slate-100 flex items-center whitespace-nowrap text-ellipsis overflow-hidden hover:text-woot-600 dark:hover:text-woot-500 cursor-pointer rounded-md"
    @click.stop="onMenuItemClick"
  >
    {{ label }}
  </div>
</template>
