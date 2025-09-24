<script setup>
import { ref } from 'vue';

const paused = ref(false);

const toggle = () => {
  paused.value = !paused.value;
};
</script>

<template>
  <div
    class="svg-wrapper relative"
    :class="{ paused }"
    role="button"
    :aria-pressed="paused"
    tabindex="0"
    @click="toggle"
  >
    <div class="absolute z-0 flex-shrink-0">
      <svg
        width="auto"
        height="auto"
        viewBox="0 0 200 156"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <g opacity="0.5">
          <g clip-path="url(#clip0_773_34322)">
            <circle cx="8" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="3" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="9" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="15" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="21" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="27" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="33" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="39" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="45" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="51" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="57" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="63" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="69" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="75" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="81" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="87" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="93" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="99" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="105" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="111" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="117" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="123" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="129" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="135" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="141" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="147" r="1" class="fill-n-blue-9" />
            <circle cx="8" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="16" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="24" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="32" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="40" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="48" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="56" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="64" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="72" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="80" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="88" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="96" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="104" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="112" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="120" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="128" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="136" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="144" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="152" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="160" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="168" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="176" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="184" cy="153" r="1" class="fill-n-blue-9" />
            <circle cx="192" cy="153" r="1" class="fill-n-blue-9" />
            <rect
              width="200"
              height="156"
              fill="url(#paint0_linear_773_34322)"
            />
            <rect
              width="200"
              height="156"
              fill="url(#paint1_linear_773_34322)"
            />
          </g>
        </g>
        <defs>
          <linearGradient
            id="paint0_linear_773_34322"
            x1="100"
            y1="0"
            x2="100"
            y2="156"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="var(--gradient-start)" />
            <stop
              offset="0.480769"
              stop-color="var(--gradient-start)"
              stop-opacity="0"
            />
            <stop offset="1" stop-color="var(--gradient-start)" />
          </linearGradient>
          <linearGradient
            id="paint1_linear_773_34322"
            x1="0"
            y1="78"
            x2="200"
            y2="78"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="var(--gradient-start)" />
            <stop
              offset="0.480769"
              stop-color="var(--gradient-start)"
              stop-opacity="0"
            />
            <stop offset="1" stop-color="var(--gradient-start)" />
          </linearGradient>
          <clipPath id="clip0_773_34322">
            <rect width="200" height="156" rx="16" fill="white" />
          </clipPath>
        </defs>
      </svg>
    </div>
    <svg
      viewBox="0 0 136 108"
      aria-hidden="false"
      focusable="false"
      class="z-10 relative flex-shrink-0"
    >
      <rect width="136" height="108" fill="url(#paint0_radial_720_25701)" />
      <path
        d="M49 35.039C49 33.9129 49.9129 33 51.039 33C52.1651 33 53.0779 33.9129 53.0779 35.039V39.7513C53.0779 40.8774 52.1651 41.7902 51.039 41.7902C49.9129 41.7902 49 40.8774 49 39.7513V35.039Z"
        class="fill-n-slate-10"
      />
      <path
        d="M55.5244 35.039C55.5244 33.9129 56.4373 33 57.5634 33C58.6895 33 59.6024 33.9129 59.6024 35.039V39.7513C59.6024 40.8774 58.6895 41.7902 57.5634 41.7902C56.4373 41.7902 55.5244 40.8774 55.5244 39.7513V35.039Z"
        class="fill-n-slate-10"
      />
      <path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M58.1862 24.173C50.5933 23.1017 44.4039 23.0594 36.6405 24.1683C34.678 24.4485 33.3796 24.638 32.3896 24.9273C31.4716 25.1956 30.9496 25.5155 30.5177 25.9981C29.6236 26.9974 29.5057 28.1276 29.3838 32.0695C29.264 35.9436 29.5013 39.4156 29.9507 43.3222C30.1901 45.4039 30.3549 46.8088 30.618 47.8769C30.8676 48.89 31.1694 49.4347 31.5889 49.8518C32.0117 50.2721 32.5536 50.5686 33.5482 50.8091C34.6002 51.0636 35.9806 51.2175 38.032 51.4413C44.6668 52.1652 49.6333 52.1615 56.2927 51.4451C58.369 51.2218 59.7719 51.0678 60.8396 50.815C61.8541 50.5749 62.3995 50.2805 62.8165 49.8722C63.2247 49.4724 63.5366 48.921 63.8071 47.8574C64.0894 46.7477 64.2815 45.2793 64.5594 43.1222C65.0553 39.2735 65.4123 35.8935 65.4262 32.1908C65.4411 28.232 65.3601 27.1056 64.4558 26.0608C64.019 25.5562 63.488 25.2244 62.5491 24.9481C61.5352 24.6497 60.2017 24.4573 58.1862 24.173ZM36.1664 20.849C44.2537 19.6939 50.7606 19.7391 58.6546 20.8529L58.7701 20.8692C60.6392 21.1328 62.2183 21.3555 63.4958 21.7315C64.8745 22.1372 66.0274 22.7532 66.991 23.8665C68.8087 25.9666 68.7969 28.4583 68.7811 31.7688C68.7804 31.9121 68.7797 32.057 68.7792 32.2034C68.7645 36.1184 68.3857 39.6634 67.8849 43.5506L67.8717 43.6535C67.6103 45.682 67.395 47.3537 67.0566 48.6839C66.7008 50.0827 66.169 51.282 65.1624 52.2678C64.1645 53.245 62.9854 53.7528 61.6119 54.0778C60.3149 54.3848 58.7011 54.5584 56.7558 54.7676L56.6513 54.7789C49.7551 55.5207 44.5465 55.5249 37.6684 54.7745L37.5622 54.7629C35.6442 54.5537 34.0471 54.3795 32.7599 54.0681C31.3915 53.7371 30.2202 53.219 29.2249 52.2296C28.2263 51.2369 27.7018 50.0571 27.3623 48.6788C27.0421 47.3788 26.856 45.7601 26.6318 43.8109L26.6197 43.7053C26.1588 39.6989 25.906 36.0546 26.0325 31.9659C26.037 31.8176 26.0414 31.6709 26.0458 31.5257C26.144 28.24 26.2178 25.7754 28.019 23.7623C28.9747 22.6942 30.1043 22.102 31.449 21.7089C32.6962 21.3444 34.2339 21.1249 36.0541 20.865C36.0914 20.8597 36.1288 20.8543 36.1664 20.849Z"
        class="fill-n-slate-10"
      />
      <path
        d="M103.999 77.4062H108.999C110.104 77.4062 110.999 78.3017 110.999 79.4062C110.999 80.5108 110.104 81.4062 108.999 81.4062H103.999V77.4062Z"
        class="fill-n-slate-9"
      />
      <path
        d="M63 77.4062H58C56.8954 77.4062 56 78.3017 56 79.4062C56 80.5108 56.8954 81.4062 58 81.4062H63V77.4062Z"
        class="fill-n-slate-9"
      />
      <path
        d="M83.999 64.4063C85.4527 63.7978 86.4227 63.4566 87.9986 63.4508C89.5744 63.445 91.136 63.7496 92.5941 64.3472C94.0523 64.9449 95.3784 65.8239 96.4968 66.9341C97.6153 68.0442 98.5041 69.3638 99.1125 70.8175C99.721 72.2711 100.037 73.8304 100.043 75.4062"
        class="stroke-n-blue-11 fill-n-slate-2"
        stroke-width="1.6"
      />
      <path
        d="M67.049 75.0889C67.0432 73.5131 67.3478 71.9515 67.9454 70.4934C68.5431 69.0352 69.4221 67.7091 70.5322 66.5907C71.6424 65.4723 72.962 64.5834 74.4157 63.975C75.8693 63.3666 77.4286 63.0504 79.0044 63.0445C80.5803 63.0387 82.1419 63.3433 83.6 63.941C85.0581 64.5386 86.3843 65.4176 87.5027 66.5278C88.6211 67.638 89.5099 68.9576 90.1184 70.4112C90.7268 71.8649 91.043 73.4241 91.0488 75"
        class="stroke-n-blue-11 fill-n-slate-2"
        stroke-width="1.6"
      />
      <path
        d="M71.4659 74.9421C71.462 73.8915 71.6651 72.8505 72.0635 71.8784C72.462 70.9063 73.048 70.0222 73.7881 69.2766C74.5282 68.531 75.4079 67.9384 76.377 67.5328C77.3462 67.1272 78.3857 66.9164 79.4362 66.9125C80.4868 66.9086 81.5278 67.1117 82.4999 67.5101C83.472 67.9086 84.3561 68.4946 85.1017 69.2347C85.8473 69.9748 86.4399 70.8545 86.8455 71.8236C87.2511 72.7927 87.4619 73.8322 87.4658 74.8828"
        class="stroke-n-blue-11 fill-n-slate-2"
        stroke-width="1.6"
      />
      <path
        d="M88.4304 67.3188C89.4809 67.3149 90.522 67.5179 91.4941 67.9164C92.4662 68.3148 93.3503 68.9008 94.0959 69.6409C94.8415 70.381 95.434 71.2608 95.8397 72.2299C96.2453 73.199 96.4561 74.2385 96.46 75.2891"
        class="stroke-n-blue-11 fill-n-slate-2"
        stroke-width="1.6"
      />
      <path
        d="M75.9473 74.9203C75.9454 74.395 76.0469 73.8745 76.2461 73.3884C76.4453 72.9024 76.7383 72.4603 77.1084 72.0875C77.4785 71.7147 77.9183 71.4184 78.4029 71.2156C78.8874 71.0128 79.4072 70.9074 79.9325 70.9055C80.4578 70.9035 80.9783 71.0051 81.4643 71.2043C81.9504 71.4035 82.3924 71.6965 82.7652 72.0666C83.138 72.4366 83.4343 72.8765 83.6371 73.361C83.8399 73.8456 83.9453 74.3653 83.9473 74.8906"
        class="stroke-n-blue-11 fill-n-slate-2"
        stroke-width="1.6"
      />
      <path
        d="M90.4585 71.6066C90.9445 71.8058 91.3866 72.0988 91.7594 72.4689C92.1322 72.839 92.4284 73.2788 92.6313 73.7634C92.8341 74.2479 92.9395 74.7677 92.9414 75.293"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M102 74.9062C103.09 74.9062 104.032 75.7999 103.973 76.957C103.853 79.29 103.335 81.588 102.439 83.751C101.939 84.9592 101.499 85.8713 100.931 86.7236C100.363 87.5763 99.6906 88.3338 98.7646 89.2598C96.6889 91.3355 93.3531 92.0527 91.0576 92.0527H76.5576C73.9588 92.0527 70.4405 91.3497 68.3506 89.2598C67.4349 88.3441 66.737 87.5905 66.1416 86.7441C65.5415 85.8911 65.0682 84.9765 64.5605 83.751C63.6646 81.588 63.1471 79.29 63.0273 76.957C62.968 75.7999 63.9098 74.9062 65 74.9062H102Z"
        class="fill-n-slate-2 stroke-n-slate-9"
        stroke-width="2"
      />

      <g class="default-group">
        <path
          d="M103.85 21.1431C104.824 20.8821 105.847 21.3479 106.291 22.2542L112.209 34.3514C112.793 35.544 112.143 36.9734 110.861 37.3171L100.014 40.2235C98.7313 40.5669 97.4538 39.654 97.3628 38.3295L96.4399 24.8937C96.3708 23.8871 97.0247 22.9718 97.9993 22.7107L103.85 21.1431Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <path
          d="M104.528 18.8482C104.84 18.7645 105.124 18.5966 105.347 18.363C106.576 17.0748 105.336 14.9834 103.616 15.4439L95.3492 17.659C93.6293 18.1203 93.6011 20.5515 95.3101 21.0523C95.6201 21.1431 95.9494 21.1468 96.2614 21.0633L104.528 18.8482Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <rect
          x="95.3496"
          y="21.2852"
          width="10.4348"
          height="2.08696"
          rx="0.695652"
          transform="rotate(-15 95.3496 21.2852)"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <path
          d="M103.249 14.4618C103.363 14.5616 103.464 14.6686 103.55 14.7819C103.782 15.0879 103.556 15.4819 103.185 15.5813L99.4893 16.5716L95.7936 17.5618C95.4224 17.6613 95.0296 17.4332 95.0777 17.052C95.0955 16.9109 95.1292 16.7679 95.1785 16.6242C95.3106 16.2393 95.5529 15.8568 95.8916 15.4986C96.2303 15.1403 96.6587 14.8133 97.1525 14.5362C97.6462 14.2592 98.1955 14.0375 98.7691 13.8838C99.3426 13.7301 99.9292 13.6474 100.495 13.6405C101.061 13.6336 101.596 13.7026 102.068 13.8435C102.541 13.9844 102.942 14.1945 103.249 14.4618Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
      </g>

      <g class="frame frame-1">
        <path
          d="M97.8899 24.7525C97.1819 24.0337 97.0822 22.9139 97.6517 22.0811L105.253 10.9636C106.002 9.8676 107.566 9.72734 108.498 10.6731L116.378 18.6731C117.31 19.619 117.146 21.1806 116.039 21.9133L104.809 29.3463C103.967 29.9032 102.848 29.7861 102.14 29.0673L97.8899 24.7525Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <path
          d="M95.5608 25.2908C95.3341 25.0607 95.0482 24.8971 94.735 24.8184C93.0078 24.3847 91.8006 26.4952 93.05 27.7641L99.0562 33.8613C100.306 35.1296 102.435 33.9543 102.027 32.2207C101.953 31.9063 101.794 31.6181 101.567 31.3879L95.5608 25.2908Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <rect
          x="102.207"
          y="32.0742"
          width="10.4348"
          height="2.08696"
          rx="0.695652"
          transform="rotate(-134.569 102.207 32.0742)"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <path
          d="M92.3768 28.5691C92.4071 28.4202 92.4505 28.2799 92.5066 28.1492C92.6581 27.7962 93.1124 27.7985 93.3821 28.0722L96.0671 30.7979L98.7521 33.5236C99.0218 33.7973 99.0172 34.2515 98.6619 34.3978C98.5304 34.4519 98.3895 34.4932 98.2402 34.5212C97.8402 34.5963 97.3879 34.5743 96.9092 34.4565C96.4304 34.3387 95.9346 34.1274 95.45 33.8347C94.9654 33.542 94.5015 33.1737 94.0848 32.7506C93.668 32.3276 93.3067 31.8582 93.0213 31.3692C92.7359 30.8803 92.5321 30.3813 92.4216 29.9009C92.311 29.4204 92.2958 28.9679 92.3768 28.5691Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <circle cx="85" cy="40" r="1" class="fill-n-slate-11" />
        <circle cx="91" cy="38" r="1" class="fill-n-slate-11" />
        <circle cx="91" cy="44" r="1" class="fill-n-slate-11" />
        <circle cx="85" cy="46" r="1" class="fill-n-slate-11" />
        <circle cx="79" cy="46" r="1" class="fill-n-slate-11" />
        <circle cx="88" cy="51" r="1" class="fill-n-slate-11" />
      </g>

      <g class="frame frame-2">
        <path
          d="M97.8879 24.7721C97.1799 24.0532 97.0803 22.9335 97.6497 22.1006L105.251 10.9832C106 9.88713 107.564 9.74688 108.496 10.6927L116.376 18.6926C117.308 19.6385 117.144 21.2001 116.037 21.9329L104.807 29.3658C103.965 29.9227 102.846 29.8056 102.138 29.0868L97.8879 24.7721Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <path
          d="M95.5579 25.3103C95.3311 25.0803 95.0453 24.9167 94.7321 24.838C93.0048 24.4042 91.7977 26.5148 93.0471 27.7836L99.0532 33.8808C100.303 35.1491 102.432 33.9738 102.024 32.2403C101.95 31.9259 101.791 31.6376 101.564 31.4075L95.5579 25.3103Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <rect
          x="102.205"
          y="32.0938"
          width="10.4348"
          height="2.08696"
          rx="0.695652"
          transform="rotate(-134.569 102.205 32.0938)"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <path
          d="M92.3758 28.5886C92.4061 28.4397 92.4495 28.2994 92.5056 28.1687C92.6572 27.8157 93.1115 27.818 93.3811 28.0917L96.0661 30.8174L98.7512 33.5431C99.0208 33.8168 99.0162 34.2711 98.661 34.4173C98.5294 34.4714 98.3885 34.5128 98.2392 34.5408C97.8392 34.6158 97.3869 34.5938 96.9082 34.476C96.4295 34.3582 95.9336 34.1469 95.449 33.8542C94.9644 33.5616 94.5005 33.1932 94.0838 32.7702C93.6671 32.3471 93.3057 31.8777 93.0203 31.3888C92.735 30.8998 92.5312 30.4009 92.4206 29.9204C92.31 29.44 92.2948 28.9874 92.3758 28.5886Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <circle cx="84" cy="42" r="1" class="fill-n-slate-11" />
        <circle cx="90" cy="40" r="1" class="fill-n-slate-11" />
        <circle cx="90" cy="46" r="1" class="fill-n-slate-11" />
        <circle cx="84" cy="48" r="1" class="fill-n-slate-11" />
        <circle cx="78" cy="48" r="1" class="fill-n-slate-11" />
        <circle cx="87" cy="53" r="1" class="fill-n-slate-11" />
      </g>

      <g class="frame frame-3">
        <path
          d="M97.8879 24.7486C97.1799 24.0298 97.0803 22.91 97.6497 22.0771L105.251 10.9597C106 9.86369 107.564 9.72344 108.496 10.6692L116.376 18.6692C117.308 19.6151 117.144 21.1767 116.037 21.9094L104.807 29.3424C103.965 29.8993 102.846 29.7822 102.138 29.0634L97.8879 24.7486Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <path
          d="M95.5579 25.2908C95.3311 25.0607 95.0453 24.8971 94.7321 24.8184C93.0048 24.3847 91.7977 26.4952 93.0471 27.7641L99.0532 33.8613C100.303 35.1296 102.432 33.9543 102.024 32.2207C101.95 31.9063 101.791 31.6181 101.564 31.3879L95.5579 25.2908Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <rect
          x="102.205"
          y="32.0703"
          width="10.4348"
          height="2.08696"
          rx="0.695652"
          transform="rotate(-134.569 102.205 32.0703)"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <path
          d="M92.3758 28.5691C92.4061 28.4202 92.4495 28.2799 92.5056 28.1492C92.6572 27.7962 93.1115 27.7985 93.3811 28.0722L96.0661 30.7979L98.7512 33.5236C99.0208 33.7973 99.0162 34.2515 98.661 34.3978C98.5294 34.4519 98.3885 34.4932 98.2392 34.5212C97.8392 34.5963 97.3869 34.5743 96.9082 34.4565C96.4295 34.3387 95.9336 34.1274 95.449 33.8347C94.9644 33.542 94.5005 33.1737 94.0838 32.7506C93.6671 32.3276 93.3057 31.8582 93.0203 31.3692C92.735 30.8803 92.5312 30.3813 92.4206 29.9009C92.31 29.4204 92.2948 28.9679 92.3758 28.5691Z"
          class="stroke-n-slate-11 fill-n-slate-2"
          stroke-width="1.43699"
        />
        <circle cx="82" cy="44" r="1" class="fill-n-slate-11" />
        <circle cx="88" cy="42" r="1" class="fill-n-slate-11" />
        <circle cx="88" cy="48" r="1" class="fill-n-slate-11" />
        <circle cx="82" cy="50" r="1" class="fill-n-slate-11" />
        <circle cx="76" cy="50" r="1" class="fill-n-slate-11" />
        <circle cx="85" cy="55" r="1" class="fill-n-slate-11" />
      </g>

      <defs>
        <radialGradient
          id="paint0_radial_720_25701"
          cx="0"
          cy="0"
          r="1"
          gradientUnits="userSpaceOnUse"
          gradientTransform="translate(68 54) rotate(90) scale(54 68)"
        >
          <stop
            offset="0.527769"
            stop-color="var(--gradient-end)"
            stop-opacity="0.9"
          />
          <stop offset="1" stop-color="var(--gradient-end)" stop-opacity="0" />
        </radialGradient>
      </defs>
    </svg>
  </div>
</template>

<style scoped>
svg {
  --gradient-start: #fcfcfd;
  --gradient-end: #fcfcfd;
}

body.dark svg,
.htw-dark svg {
  --gradient-start: #121213;
  --gradient-end: #121213;
}

.svg-wrapper {
  display: flex;
  align-items: center;
  cursor: pointer;
  user-select: none;
  -webkit-tap-highlight-color: transparent;
  outline: none;
}

.default-group {
  opacity: 0;
  transition: opacity 120ms linear;
  pointer-events: none;
}

.frame {
  opacity: 0;
  animation-name: frameVisible;
  animation-duration: 600ms;
  animation-iteration-count: infinite;
  animation-timing-function: steps(1, end);
  transform-origin: center;
}

.frame-1 {
  animation-delay: 0ms;
}
.frame-2 {
  animation-delay: 200ms;
}
.frame-3 {
  animation-delay: 400ms;
}

@keyframes frameVisible {
  0% {
    opacity: 1;
  }
  33.333% {
    opacity: 0;
  }
  100% {
    opacity: 0;
  }
}

.svg-wrapper.paused .frame {
  animation-play-state: paused;
  opacity: 0 !important;
}

.svg-wrapper.paused .default-group {
  opacity: 1;
}
.svg-wrapper:not(.paused) .default-group {
  opacity: 0;
}
</style>
