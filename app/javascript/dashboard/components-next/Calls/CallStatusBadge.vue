<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { CALL_KIND } from './constants';

const props = defineProps({
  kind: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();

const KIND_CONFIG = {
  [CALL_KIND.ONGOING]: {
    icon: 'i-lucide-phone-call',
    class: 'bg-n-teal-3 text-n-teal-11',
  },
  [CALL_KIND.INCOMING]: {
    icon: 'i-lucide-phone-incoming',
    class: 'bg-n-slate-3 text-n-slate-11',
  },
  [CALL_KIND.OUTGOING]: {
    icon: 'i-lucide-phone-outgoing',
    class: 'bg-n-slate-3 text-n-slate-11',
  },
  [CALL_KIND.MISSED]: {
    icon: 'i-lucide-phone-missed',
    class: 'bg-n-ruby-3 text-n-ruby-11',
  },
  [CALL_KIND.NO_REPLY]: {
    icon: 'i-lucide-phone-outgoing',
    class: 'bg-n-amber-3 text-n-amber-11',
  },
  [CALL_KIND.FAILED]: {
    icon: 'i-lucide-phone-off',
    class: 'bg-n-ruby-3 text-n-ruby-11',
  },
};

const config = computed(() => KIND_CONFIG[props.kind]);
</script>

<template>
  <span
    class="inline-flex items-center justify-center w-20 gap-1.5 h-6 px-1 rounded-md text-label-small shrink-0"
    :class="config.class"
  >
    <Icon :icon="config.icon" class="size-3 flex-shrink-0" />
    <span class="truncate">{{
      t(`CALLS_PAGE.STATUS.${kind.toUpperCase()}`)
    }}</span>
  </span>
</template>
