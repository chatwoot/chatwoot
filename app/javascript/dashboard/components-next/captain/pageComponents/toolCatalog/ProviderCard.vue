<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import ProviderIcon from './ProviderIcon.vue';

const props = defineProps({
  provider: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['open']);
const { t } = useI18n();

const isPlanned = computed(() => props.provider.availability === 'planned');
const connectionLabel = computed(() => {
  if (isPlanned.value) return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.PLANNED');
  if (props.provider.connection?.connected) {
    return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CONNECTED');
  }
  return t('CAPTAIN.CUSTOM_TOOLS.CATALOG.NOT_CONNECTED');
});
</script>

<template>
  <article
    class="flex flex-col gap-4 rounded-xl border border-n-weak bg-n-solid-1 p-5"
  >
    <div class="flex items-start gap-3">
      <ProviderIcon
        :provider-key="provider.key"
        :provider-name="provider.name"
      />
      <div class="min-w-0 flex-1">
        <div class="flex flex-wrap items-center gap-2">
          <h3 class="text-base font-medium text-n-slate-12">
            {{ provider.name }}
          </h3>
          <span
            class="rounded-md px-2 py-0.5 text-xs"
            :class="
              provider.connection?.connected
                ? 'bg-n-teal-3 text-n-teal-11'
                : 'bg-n-alpha-2 text-n-slate-11'
            "
          >
            {{ connectionLabel }}
          </span>
        </div>
        <p class="mt-1 text-sm leading-5 text-n-slate-11 line-clamp-2">
          {{ provider.description }}
        </p>
      </div>
    </div>

    <dl class="grid grid-cols-3 gap-3 text-sm">
      <div>
        <dt class="text-n-slate-10">
          {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CATEGORIES') }}
        </dt>
        <dd class="font-medium text-n-slate-12">
          {{ provider.category_count || 0 }}
        </dd>
      </div>
      <div>
        <dt class="text-n-slate-10">
          {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.ACTIONS') }}
        </dt>
        <dd class="font-medium text-n-slate-12">
          {{ provider.available_template_count || 0 }}
        </dd>
      </div>
      <div>
        <dt class="text-n-slate-10">
          {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.INSTALLED') }}
        </dt>
        <dd class="font-medium text-n-slate-12">
          {{ provider.installed_count || 0 }}
        </dd>
      </div>
    </dl>

    <Button
      :label="
        isPlanned
          ? $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.PLANNED')
          : $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.VIEW_INTEGRATION')
      "
      color="slate"
      variant="outline"
      size="sm"
      :disabled="isPlanned"
      class="self-start"
      @click="emit('open', provider.key)"
    />
  </article>
</template>
