<template>
  <div>
    <p class="text-woot-600 dark:text-woot-600 mb-1">
      <span :class="{ 'font-bold': selectedContactId == cardData.id }">
        {{ cardData.title }}
      </span>
    </p>
    <p
      v-if="
        displayOptions.lastStageChangedAt && cardData.formattedStageChangedAt
      "
      class="mb-1"
    >
      <span>
        <strong>
          {{ $t(`CARD_DISPLAY.lastStageChangedAt.CARD_LABEL`) }}
        </strong>
      </span>
      <span> {{ cardData.formattedStageChangedAt }} </span>
    </p>
    <p v-if="displayOptions.assignee && cardData.assignee" class="mb-1">
      <span>
        <strong> {{ $t(`CARD_DISPLAY.assignee.CARD_LABEL`) }} </strong>
      </span>
      <span>{{ cardData.assignee }}</span>
    </p>
    <p
      v-if="displayOptions.productShortName && cardData.productShortName"
      class="mb-1"
    >
      <span>
        <strong> {{ $t(`CARD_DISPLAY.productShortName.CARD_LABEL`) }} </strong>
      </span>
      <span>{{ cardData.productShortName }}</span>
    </p>
    <p v-if="displayOptions.product && cardData.product" class="mb-1">
      <span>
        <strong> {{ $t(`CARD_DISPLAY.product.CARD_LABEL`) }} </strong>
      </span>
      <span>{{ cardData.product }}</span>
    </p>
    <p
      v-if="displayOptions.lastActivityAt && cardData.formattedLastActivityAt"
      class="mb-1"
    >
      <span>
        <strong>
          {{ $t(`CARD_DISPLAY.lastActivityAt.CARD_LABEL`) }}
        </strong>
      </span>
      <span>{{ cardData.formattedLastActivityAt }}</span>
    </p>
    <p v-if="displayOptions.lastNote && cardData.lastNote" class="mb-1">
      <em> {{ cardData.lastNote }} </em>
    </p>
    <p
      v-if="displayOptions.currentAction && cardData.currentActionText"
      class="mb-1"
    >
      {{ cardData.currentActionText }}
    </p>
  </div>
</template>

<script>
export default {
  props: {
    cardData: {
      type: Object,
      default: null,
    },
    displayOptions: {
      type: Object,
      default: null,
    },
    selectedContactId: {
      type: [String, Number],
      default: '',
    },
  },
};
</script>
