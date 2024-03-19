<script setup>
import BaseHeader from '../../components/BaseHeader.vue';
</script>
<template>
  <base-header
    :title="$t('SLA.HEADER')"
    :description="$t('SLA.DESCRIPTION')"
    :link-text="$t('SLA.LEARN_MORE')"
    href="/"
    icon-name="document-list-clock"
  >
    <template #actions>
      <woot-button
        color-scheme="primary"
        icon="add"
        class="rounded-xl"
        @click="emit('click')"
      >
        {{ $t('SLA.ADD_ACTION') }}
      </woot-button>
    </template>
  </base-header>
</template>
