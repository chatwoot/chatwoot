<script setup>
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  option: {
    type: Object,
    default: () => {},
  },
  variant: {
    type: String,
    default: 'default',
  },
});
</script>

<template>
  <div class="menu text-n-slate-12 min-h-7 min-w-0" role="button">
    <fluent-icon
      v-if="variant === 'icon' && option.icon"
      :icon="option.icon"
      size="14"
      class="flex-shrink-0"
    />
    <span
      v-if="
        (variant === 'label' || variant === 'label-assigned') && option.color
      "
      class="label-pill flex-shrink-0"
      :style="{ backgroundColor: option.color }"
    />
    <Avatar
      v-if="variant === 'agent'"
      :name="option.label"
      :src="option.thumbnail"
      :icon-name="option.iconName"
      :status="option.status === 'online' ? option.status : null"
      :size="20"
      class="flex-shrink-0"
    >
      <template v-if="option.iconName && option.thumbnail" #badge>
        <div
          class="absolute z-20 flex items-center justify-center rounded-full outline outline-1 outline-n-weak bg-n-solid-1 -bottom-0.5 ltr:-right-0.5 rtl:-left-0.5 size-3"
        >
          <Icon icon="i-lucide-bot" class="text-n-slate-11 size-2" />
        </div>
      </template>
    </Avatar>
    <p class="menu-label truncate min-w-0 flex-1">
      {{ option.label }}
    </p>
    <Icon
      v-if="variant === 'label-assigned'"
      icon="i-lucide-check"
      class="flex-shrink-0 size-3.5 mr-1"
    />
  </div>
</template>

<style scoped lang="scss">
.menu {
  width: calc(6.25rem * 2);
  @apply flex items-center flex-nowrap p-1 rounded-md overflow-hidden cursor-pointer;

  .menu-label {
    @apply my-0 mx-2 text-xs flex-shrink-0;
  }

  &:hover {
    @apply bg-n-brand text-white;
  }
}

.agent-thumbnail {
  margin-top: 0 !important;
}

.label-pill {
  @apply w-4 h-4 rounded-full border border-n-strong border-solid flex-shrink-0;
}
</style>
