<script>
import Policy from 'dashboard/components/policy.vue';

export default {
  name: 'WootTabsItem',
  components: {
    Policy,
  },
  props: {
    index: {
      type: Number,
      default: 0,
    },
    name: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    count: {
      type: Number,
      default: 0,
    },
    showBadge: {
      type: Boolean,
      default: true,
    },
    permissions: {
      type: Array,
      default: () => [],
    },
  },

  computed: {
    active() {
      return this.index === this.$parent.index;
    },

    getItemCount() {
      return this.count;
    },
  },

  methods: {
    onTabClick(event) {
      event.preventDefault();
      if (!this.disabled) {
        this.$parent.$emit('change', this.index);
      }
    },
  },
};
</script>

<template>
  <Policy :permissions="permissions">
  <li
    class="tabs-title"
    :class="{
      'is-active': active,
    }"
  >
    <a @click="onTabClick">
      {{ name }}
      <div v-if="showBadge" class="badge min-w-[20px]">
        <span>
          {{ getItemCount }}
        </span>
      </div>
    </a>
  </li>
  </Policy>
</template>
