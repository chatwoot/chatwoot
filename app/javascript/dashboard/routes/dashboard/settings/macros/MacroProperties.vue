<script>
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

export default {
  components: {
    NextButton,
    Icon,
  },
  inject: ['v$'],
  props: {
    macroName: {
      type: String,
      default: '',
    },
    macroVisibility: {
      type: String,
      default: 'global',
    },
  },
  emits: ['update:name', 'update:visibility', 'submit'],
  methods: {
    isActive(key) {
      return this.macroVisibility === key
        ? 'bg-n-blue-2 dark:bg-n-blue-1 border-n-blue-3 dark:border-n-blue-4'
        : 'bg-white dark:bg-n-solid-2 border-n-weak dark:border-n-strong';
    },
    onUpdateName(value) {
      this.$emit('update:name', value);
    },
    onUpdateVisibility(value) {
      this.$emit('update:visibility', value);
    },
  },
};
</script>

<template>
  <div
    class="p-4 bg-n-solid-2 border border-n-weak rounded-lg shadow-sm h-full flex flex-col"
  >
    <div>
      <woot-input
        :model-value="macroName"
        :label="$t('MACROS.ADD.FORM.NAME.LABEL')"
        :placeholder="$t('MACROS.ADD.FORM.NAME.PLACEHOLDER')"
        :error="v$.macro.name.$error ? $t('MACROS.ADD.FORM.NAME.ERROR') : null"
        :class="{ error: v$.macro.name.$error }"
        @update:model-value="onUpdateName"
      />
    </div>
    <div class="mt-2">
      <p class="block m-0 text-sm font-medium leading-[1.8] text-n-slate-12">
        {{ $t('MACROS.EDITOR.VISIBILITY.LABEL') }}
      </p>
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-3">
        <button
          class="p-2 relative rounded-md border border-solid justify-between items-start gap-2 flex flex-col text-start cursor-default"
          :class="isActive('global')"
          @click="onUpdateVisibility('global')"
        >
          <div class="flex items-center gap-2 min-w-0 justify-between w-full">
            <p class="block m-0 text-heading-3 text-n-slate-12 line-clamp-1">
              {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL') }}
            </p>
            <Icon
              v-if="macroVisibility === 'global'"
              icon="i-lucide-circle-check-big"
              class="text-n-brand size-4"
            />
          </div>
          <p class="text-n-slate-11 text-label-small">
            {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.DESCRIPTION') }}
          </p>
        </button>
        <button
          class="p-2 relative rounded-md border border-solid justify-between items-start gap-2 flex flex-col text-start cursor-default"
          :class="isActive('personal')"
          @click="onUpdateVisibility('personal')"
        >
          <div class="flex items-center gap-2 min-w-0 justify-between w-full">
            <p class="block m-0 text-heading-3 text-n-slate-12 line-clamp-1">
              {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL') }}
            </p>
            <Icon
              v-if="macroVisibility === 'personal'"
              icon="i-lucide-circle-check-big"
              class="text-n-brand size-4"
            />
          </div>
          <p class="text-n-slate-11 text-label-small">
            {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.DESCRIPTION') }}
          </p>
        </button>
      </div>
      <div
        class="mt-2 flex items-start p-2 bg-n-alpha-1 gap-2 dark:bg-n-solid-3 rounded-md"
      >
        <Icon
          icon="i-lucide-info"
          class="flex-shrink-0 mt-0.5 size-4 text-n-slate-11"
        />
        <p class="mb-0 text-n-slate-11 text-body-para">
          {{ $t('MACROS.ORDER_INFO') }}
        </p>
      </div>
    </div>
    <div class="mt-4 w-full">
      <NextButton
        blue
        solid
        :label="$t('MACROS.HEADER_BTN_TXT_SAVE')"
        class="w-full"
        @click="$emit('submit')"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
::v-deep input[type='text'] {
  @apply mb-0;
}

::v-deep .error {
  .message {
    @apply mb-0;
  }
}
</style>
