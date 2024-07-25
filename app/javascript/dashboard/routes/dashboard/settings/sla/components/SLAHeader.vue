<script setup>
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';

defineProps({
  showActions: {
    type: Boolean,
    default: true,
  },
});

defineEmits(['click']);
</script>
<template>
  <BaseSettingsHeader
    :title="$t('SLA.HEADER')"
    :description="$t('SLA.DESCRIPTION')"
    :link-text="$t('SLA.LEARN_MORE')"
    feature-name="sla"
  >
    <template v-if="showActions" #actions>
      <woot-button
        color-scheme="primary"
        icon="plus-sign"
        class="rounded-xl"
        @click="$emit('click')"
      >
        {{ $t('SLA.ADD_ACTION') }}
      </woot-button>
    </template>
  </BaseSettingsHeader>
</template>
