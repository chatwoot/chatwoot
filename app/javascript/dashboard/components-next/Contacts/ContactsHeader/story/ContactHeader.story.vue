<script setup>
import { ref } from 'vue';
import ContactHeader from '../ContactHeader.vue';

// Base state controls
const searchValue = ref('');
const activeSort = ref('last_activity_at');
const activeOrdering = ref('');

// Event handlers
const onSearch = value => {
  searchValue.value = value;
};

const onSort = ({ sort, order }) => {
  activeSort.value = sort;
  activeOrdering.value = order;
};
</script>

<template>
  <Story
    title="Components/Contacts/ContactHeader"
    :layout="{ type: 'grid', width: '900px' }"
  >
    <Variant title="Default">
      <div class="w-full h-[400px]">
        <ContactHeader
          header-title="Contacts"
          button-label="Message"
          :search-value="searchValue"
          :active-sort="activeSort"
          :active-ordering="activeOrdering"
          @search="onSearch"
          @filter="() => {}"
          @update:sort="onSort"
          @message="() => {}"
          @add="() => {}"
          @import="() => {}"
          @export="() => {}"
        />
      </div>
    </Variant>

    <Variant title="Empty State">
      <div class="w-full">
        <ContactHeader
          is-empty-state
          header-title="Contacts"
          button-label="Message"
          :search-value="searchValue"
          :active-sort="activeSort"
          :active-ordering="activeOrdering"
          @search="onSearch"
          @filter="() => {}"
          @update:sort="onSort"
          @message="() => {}"
          @add="() => {}"
          @import="() => {}"
          @export="() => {}"
        />
      </div>
    </Variant>

    <Variant title="Segment View">
      <div class="w-full">
        <ContactHeader
          :is-not-segment-view="false"
          header-title="Segment: VIP Customers"
          button-label="Message"
          :search-value="searchValue"
          :active-sort="activeSort"
          :active-ordering="activeOrdering"
          @search="onSearch"
          @filter="() => {}"
          @update:sort="onSort"
          @message="() => {}"
          @add="() => {}"
          @import="() => {}"
          @export="() => {}"
        />
      </div>
    </Variant>
  </Story>
</template>
