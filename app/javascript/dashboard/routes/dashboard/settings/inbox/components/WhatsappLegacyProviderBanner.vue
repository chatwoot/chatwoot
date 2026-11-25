<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Banner from 'dashboard/components-next/banner/Banner.vue';

// Said on a legacy WhatsApp provider (the catalog's `legacy`), when it is being set up and
// on an inbox that already runs on it. The native provider is recommended only where this
// account can actually pick it: pointing at a channel the picker does not show is a dead end.
const props = defineProps({
  nativeAvailable: {
    type: Boolean,
    default: false,
  },
  // The inbox settings offer to convert the inbox; the setup screen, with nothing to
  // convert yet, offers to set up the native provider instead.
  canConvert: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['convert', 'useNative']);

const { t } = useI18n();

const message = computed(() =>
  props.nativeAvailable
    ? t('INBOX_MGMT.ADD.WHATSAPP.LEGACY_PROVIDER.NOTICE_WITH_NATIVE')
    : t('INBOX_MGMT.ADD.WHATSAPP.LEGACY_PROVIDER.NOTICE')
);

const actionLabel = computed(() => {
  if (!props.nativeAvailable) return null;
  return props.canConvert
    ? t('INBOX_MGMT.ADD.WHATSAPP.LEGACY_PROVIDER.CONVERT_TO_NATIVE')
    : t('INBOX_MGMT.ADD.WHATSAPP.LEGACY_PROVIDER.USE_NATIVE');
});

// Each event named where it is emitted: vue/no-unused-emit-declarations cannot follow a
// name picked at runtime.
const onAction = () => {
  if (props.canConvert) emit('convert');
  else emit('useNative');
};
</script>

<template>
  <Banner
    color="amber"
    :action-label="actionLabel"
    data-testid="whatsapp-legacy-provider-banner"
    @action="onAction"
  >
    {{ message }}
  </Banner>
</template>
