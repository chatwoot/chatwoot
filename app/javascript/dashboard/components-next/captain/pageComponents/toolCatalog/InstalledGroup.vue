<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import ProviderIcon from './ProviderIcon.vue';

const props = defineProps({
  group: {
    type: Object,
    required: true,
  },
  canManage: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['open']);
const { t } = useI18n();

const needsReconnect = computed(
  () =>
    props.group.connectionRequired ||
    props.group.connection?.connected === false
);

const connectionLabel = computed(() => {
  if (needsReconnect.value) {
    return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.RECONNECT_REQUIRED');
  }
  if (props.group.connection?.connected) {
    return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CONNECTED');
  }
  return '';
});
</script>

<template>
  <section class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1">
    <header
      class="flex flex-wrap items-center gap-3 border-b border-n-weak p-5"
    >
      <ProviderIcon :provider-key="group.key" :provider-name="group.name" />
      <div class="min-w-0 flex-1">
        <div class="flex flex-wrap items-center gap-2">
          <h2 class="font-medium text-n-slate-12">{{ group.name }}</h2>
          <span
            v-if="connectionLabel"
            class="rounded-md px-2 py-0.5 text-xs"
            :class="
              needsReconnect
                ? 'bg-n-amber-3 text-n-amber-11'
                : 'bg-n-teal-3 text-n-teal-11'
            "
          >
            {{ connectionLabel }}
          </span>
        </div>
        <p
          v-if="group.connection?.display_name"
          class="text-sm text-n-slate-10"
        >
          {{ group.connection.display_name }}
        </p>
      </div>
      <span class="text-sm text-n-slate-10">
        {{
          $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.TOOL_COUNT', {
            count: group.toolCount,
          })
        }}
      </span>
      <Button
        v-if="canManage"
        :label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.MANAGE')"
        color="slate"
        variant="ghost"
        size="sm"
        @click="emit('open', group.key)"
      />
    </header>

    <div
      v-if="needsReconnect || group.updateCount"
      class="flex flex-col gap-2 border-b border-n-weak bg-n-amber-2 px-5 py-3 text-sm text-n-amber-11 sm:flex-row sm:items-center sm:justify-between"
    >
      <span v-if="needsReconnect">
        {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.RECONNECT_NOTICE') }}
      </span>
      <span v-else>
        {{
          $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.UPDATE_NOTICE', {
            count: group.updateCount,
          })
        }}
      </span>
    </div>

    <div class="divide-y divide-n-weak">
      <section
        v-for="category in group.categories"
        :key="category.key"
        class="p-5"
      >
        <h3 class="mb-3 text-sm font-medium text-n-slate-11">
          {{ category.name }}
        </h3>
        <ul class="flex flex-col gap-3">
          <li
            v-for="tool in category.tools"
            :key="tool.id"
            class="flex items-start justify-between gap-4"
          >
            <div class="min-w-0">
              <p class="text-sm font-medium text-n-slate-12">
                {{ tool.title }}
              </p>
              <p class="mt-0.5 text-sm text-n-slate-10 line-clamp-2">
                {{ tool.description }}
              </p>
            </div>
            <span
              class="shrink-0 rounded-md bg-n-alpha-2 px-2 py-0.5 text-xs text-n-slate-11"
            >
              {{
                tool.risk_class === 'read'
                  ? $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.READ')
                  : $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.WRITE')
              }}
            </span>
          </li>
        </ul>
      </section>
    </div>
  </section>
</template>
