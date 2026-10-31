<script setup>
import { computed } from 'vue';
import { I18nT } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  approval: { type: Object, required: true },
  // The waiting card leads with this sentence, so it shows in full contrast there.
  emphasis: { type: Boolean, default: false },
});

const accountLabels = useMapGetter('labels/getLabels');

// Each action names its card string and the values that fill it. A time is shown in the agent's own time zone.
const values = computed(() => {
  const { values: cardValues = {}, count } = props.approval;
  const params = { ...cardValues, count };
  if (cardValues.time) {
    params.time = messageTimestamp(cardValues.time, 'LLL d, h:mm a');
  }
  return params;
});

// Labels show as the chips agents know from conversations, in the label's own color. Their text is smaller than the
// sentence, so the template lifts them 1px to center them on the line.
const labels = computed(() =>
  (values.value.labels || []).map(
    title => accountLabels.value.find(label => label.title === title) || title
  )
);
</script>

<template>
  <I18nT
    :keypath="`CAPTAIN.COPILOT.APPROVAL.ACTIONS.${approval.summary}`"
    :plural="approval.count"
    scope="global"
    tag="p"
    class="m-0 leading-6 break-words"
    :class="emphasis ? 'text-n-slate-12' : 'text-n-slate-11'"
  >
    <template v-for="(value, name) in values" #[name]>
      <span
        v-if="name === 'labels'"
        :key="name"
        class="inline-flex flex-wrap gap-1 align-middle -translate-y-px"
      >
        <Label
          v-for="label in labels"
          :key="label.title || label"
          :label="label"
          compact
        />
      </span>
      <span v-else :key="`${name}-value`" class="font-medium text-n-slate-12">
        {{ value }}
      </span>
    </template>
  </I18nT>
</template>
