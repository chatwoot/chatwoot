<template>
  <div
    class="flex-grow-0 flex-shrink-0 w-full h-full max-w-full px-6 pt-3 pb-6 bg-white border border-transparent border-solid dark:bg-slate-900 dark:border-transparent"
  >
    <empty-state
      :title="$t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.FINISH_PAGE.TITLE')"
      :message="
        $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.FINISH_PAGE.MESSAGE')
      "
    >
      <div class="w-full text-center">
        <router-link
          class="rounded button success nice"
          :to="{
            name: 'list_all_portals',
          }"
        >
          {{ $t('HELP_CENTER.PORTAL.ADD.CREATE_FLOW_PAGE.FINISH_PAGE.FINISH') }}
        </router-link>
      </div>
    </empty-state>
  </div>
</template>

<script setup>
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import { defineComponent } from 'vue';
defineComponent({
  name: 'PortalSettingsFinish',
});
</script>
