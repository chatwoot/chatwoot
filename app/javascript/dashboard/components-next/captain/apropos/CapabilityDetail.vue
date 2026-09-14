<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import SchemeCode from './SchemeCode.vue';
import ActivityValue from './ActivityValue.vue';
import { formatBinding } from './formatBinding';

const props = defineProps({
  name: { type: String, required: true },
  contract: { type: Object, required: true },
});
const { t } = useI18n();
const { formatMessage } = useMessageFormatter();
const relationshipLabels = computed(() => ({
  one: t('CAPTAIN_ASK.TRACE.ONE'),
  many: t('CAPTAIN_ASK.TRACE.MANY'),
  scoped: t('CAPTAIN_ASK.TRACE.SCOPED_RELATION'),
  association: t('CAPTAIN_ASK.TRACE.SCOPED_RELATION'),
  polymorphic: t('CAPTAIN_ASK.TRACE.POLYMORPHIC_RELATION'),
}));
const formattedKnowledge = computed(() => {
  // Concept links refer to catalog documents, not browser routes. The named
  // relationships below retain their catalog targets without broken navigation.
  const markdown = (props.contract.markdown || '').replace(
    /\[([^\]]+)\]\([\w-]+\.md\)/g,
    '$1'
  );
  return formatMessage(markdown);
});
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
    <div
      v-if="contract.markdown"
      v-dompurify-html="formattedKnowledge"
      class="prose prose-sm prose-slate dark:prose-invert max-w-none break-words text-n-slate-12"
    />
    <section v-if="contract.concept_relations" class="space-y-2">
      <h4 class="m-0 text-xs font-medium text-n-slate-10">
        {{ t('CAPTAIN_ASK.TRACE.CONCEPT_RELATIONSHIPS') }}
      </h4>
      <dl class="m-0 space-y-2">
        <div
          v-for="(targets, relation) in contract.concept_relations"
          :key="relation"
          class="space-y-1"
        >
          <dt class="text-xs text-n-slate-10">
            {{ relation.replaceAll('_', ' ') }}
          </dt>
          <dd class="m-0 flex flex-wrap gap-1">
            <span
              v-for="target in targets"
              :key="target"
              class="rounded bg-n-alpha-2 px-1.5 py-0.5 font-mono text-xs text-n-slate-12 break-all"
            >
              {{ target }}
            </span>
          </dd>
        </div>
      </dl>
    </section>
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
    <section v-if="contract.field_metadata" class="space-y-2">
      <h4 class="m-0 text-xs font-medium text-n-slate-10">
        {{ t('CAPTAIN_ASK.TRACE.FIELDS') }}
      </h4>
      <dl class="m-0 divide-y divide-n-weak">
        <div
          v-for="(field, key) in contract.field_metadata"
          :key="key"
          class="space-y-1 py-2"
        >
          <dt class="flex flex-wrap items-center gap-2 text-xs">
            <span class="font-mono text-n-slate-12 break-all">{{ key }}</span>
            <span class="text-n-slate-10">{{ field.type }}</span>
            <span v-if="field.nullable" class="text-n-slate-10">
              {{ t('CAPTAIN_ASK.TRACE.NULLABLE') }}
            </span>
            <span v-if="field.computed" class="text-n-slate-10">
              {{ t('CAPTAIN_ASK.TRACE.COMPUTED') }}
            </span>
          </dt>
          <dd v-if="field.values" class="m-0 flex flex-wrap gap-1">
            <span
              v-for="value in field.values"
              :key="value"
              class="rounded bg-n-alpha-2 px-1.5 py-0.5 font-mono text-xs text-n-slate-11"
            >
              {{ value }}
            </span>
          </dd>
        </div>
      </dl>
    </section>
    <div v-else-if="contract.fields?.length" class="space-y-2">
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
        class="space-y-1 text-xs text-n-slate-11"
      >
        <div class="flex flex-wrap items-center gap-2">
          <span class="font-mono break-all">{{ key }}</span>
          <span class="ms-auto text-n-slate-9">{{
            relationshipLabels[relation[2]]
          }}</span>
        </div>
        <dl v-if="relation[2] === 'polymorphic'" class="m-0 space-y-1">
          <div
            v-for="(target, senderType) in relation[0]"
            :key="senderType"
            class="flex flex-wrap items-center gap-2"
          >
            <dt class="font-mono break-all">{{ senderType }}</dt>
            <span
              class="i-lucide-arrow-right size-3 shrink-0"
              aria-hidden="true"
            />
            <dd class="m-0">{{ target }}</dd>
          </div>
        </dl>
        <p v-else class="m-0 font-mono">{{ relation[0] }}</p>
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
    <section v-if="contract.see_also" class="space-y-2">
      <h4 class="m-0 text-xs font-medium text-n-slate-10">
        {{ t('CAPTAIN_ASK.TRACE.SEE_ALSO') }}
      </h4>
      <dl class="m-0 space-y-2">
        <div v-for="(reason, entry) in contract.see_also" :key="entry">
          <dt class="font-mono text-xs text-n-slate-12">{{ entry }}</dt>
          <dd class="m-0 mt-1 text-sm text-n-slate-11">{{ reason }}</dd>
        </div>
      </dl>
    </section>
  </div>
</template>
