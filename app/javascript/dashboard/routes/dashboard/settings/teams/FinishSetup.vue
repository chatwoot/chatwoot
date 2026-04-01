<script>
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

export default {
  components: {
    NextButton,
    Icon,
  },
};
</script>

<template>
  <div
    class="flex h-full min-h-[20rem] w-full flex-col items-center justify-center p-6 lg:p-8"
  >
    <div
      class="w-full max-w-md rounded-2xl border border-outline-variant/10 bg-surface-container-low px-8 py-10 text-center shadow-xl"
    >
      <div
        class="mx-auto mb-5 flex size-14 items-center justify-center rounded-2xl bg-secondary/15 text-secondary"
      >
        <Icon icon="i-lucide-circle-check" class="size-8" />
      </div>
      <h2 class="mb-3 text-2xl font-bold tracking-tight text-on-surface">
        {{ $t('TEAMS_SETTINGS.FINISH.TITLE') }}
      </h2>
      <p class="mb-8 text-base leading-relaxed text-on-primary-container">
        {{ $t('TEAMS_SETTINGS.FINISH.MESSAGE') }}
      </p>
      <router-link
        :to="{ name: 'settings_teams_list' }"
        class="inline-flex w-full sm:w-auto"
      >
        <NextButton
          solid
          teal
          lg
          class="w-full rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.35)] sm:w-auto sm:min-w-[12rem]"
          :label="$t('TEAMS_SETTINGS.FINISH.BUTTON_TEXT')"
        />
      </router-link>
    </div>
  </div>
</template>
