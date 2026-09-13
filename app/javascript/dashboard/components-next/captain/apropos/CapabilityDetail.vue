<script setup>
import { useI18n } from 'vue-i18n';
import SchemeCode from './SchemeCode.vue';
import ActivityValue from './ActivityValue.vue';
import { formatBinding } from './formatBinding';

defineProps({
  name: { type: String, required: true },
  contract: { type: Object, required: true },
});
const { t } = useI18n();
</script>

<template>
  <div class="min-w-0 space-y-3">
    <div class="space-y-1">
      <p class="m-0 font-mono text-sm font-medium text-n-slate-12 break-words">
        {{ name }}
      </p>
      <p
        v-if="contract.description"
        class="m-0 text-sm text-n-slate-11 leading-relaxed"
      >
        {{ contract.description }}
      </p>
    </div>
    <SchemeCode
      v-if="contract.signature?.startsWith('(')"
      :source="contract.signature"
    />
    <p
      v-else-if="contract.signature"
      class="m-0 text-xs font-mono text-n-slate-11 break-words"
    >
      {{ contract.signature }}
    </p>
    <div v-if="contract.fields?.length" class="space-y-2">
      <p class="m-0 text-xs font-medium text-n-slate-10">
        {{ t('CAPTAIN_ASK.TRACE.FIELDS') }}
      </p>
      <div class="flex flex-wrap gap-1">
        <span
          v-for="field in contract.fields"
          :key="field"
          class="rounded px-1.5 py-0.5 text-xs font-mono bg-n-alpha-2 text-n-slate-11"
        >
          {{ field }}
        </span>
      </div>
    </div>
    <div v-if="contract.query?.length" class="space-y-1">
      <p class="m-0 text-xs font-medium text-n-slate-10">
        {{ t('CAPTAIN_ASK.TRACE.SEARCHABLE') }}
      </p>
      <p class="m-0 text-xs font-mono text-n-slate-11">
        {{ contract.query.join(', ') }}
      </p>
    </div>
    <div
      v-if="contract.relations && Object.keys(contract.relations).length"
      class="space-y-2"
    >
      <p class="m-0 text-xs font-medium text-n-slate-10">
        {{ t('CAPTAIN_ASK.TRACE.RELATIONSHIPS') }}
      </p>
      <div
        v-for="(relation, key) in contract.relations"
        :key="key"
        class="flex items-center gap-2 text-xs text-n-slate-11"
      >
        <span class="font-mono">{{ key }}</span>
        <span class="i-lucide-arrow-right size-3 shrink-0" aria-hidden="true" />
        <span>{{ relation[0] }}</span>
        <span class="ms-auto text-n-slate-9">{{
          relation[2] === 'many'
            ? t('CAPTAIN_ASK.TRACE.MANY')
            : t('CAPTAIN_ASK.TRACE.ONE')
        }}</span>
      </div>
    </div>
    <ActivityValue v-if="contract.arguments" :value="contract.arguments" />
    <p v-if="contract.target" class="m-0 text-xs text-n-slate-11">
      {{ t('CAPTAIN_ASK.TRACE.TARGET', { target: contract.target }) }}
    </p>
    <p v-if="contract.effect" class="m-0 text-xs text-n-slate-11">
      {{ contract.effect.replaceAll('_', ' ') }}
    </p>
    <SchemeCode
      v-if="'binding' in contract"
      :source="formatBinding(contract.binding)"
    />
    <ActivityValue
      v-if="contract.stored_value"
      :value="contract.stored_value"
    />
    <div v-if="contract.connections?.length" class="space-y-1">
      <p class="m-0 text-xs font-medium text-n-slate-10">
        {{ t('CAPTAIN_ASK.TRACE.RELATIONSHIPS') }}
      </p>
      <p class="m-0 text-xs font-mono text-n-slate-11">
        {{ contract.connections.join(', ') }}
      </p>
    </div>
    <div v-if="contract.members" class="space-y-4 border-s border-n-weak ps-3">
      <CapabilityDetail
        v-for="(member, key) in contract.members"
        :key="key"
        :name="key"
        :contract="member"
      />
    </div>
  </div>
</template>
