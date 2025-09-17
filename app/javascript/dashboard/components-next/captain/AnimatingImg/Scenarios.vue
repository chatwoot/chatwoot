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
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="false"
      focusable="false"
      class="z-10 relative flex-shrink-0"
    >
      <rect width="136" height="108" fill="url(#paint0_radial_720_25695)" />
      <path
        d="M49 30.039C49 28.9129 49.9129 28 51.039 28C52.1651 28 53.0779 28.9129 53.0779 30.039V34.7513C53.0779 35.8774 52.1651 36.7902 51.039 36.7902C49.9129 36.7902 49 35.8774 49 34.7513V30.039Z"
        class="fill-n-slate-10"
      />
      <path
        d="M55.5244 30.039C55.5244 28.9129 56.4373 28 57.5634 28C58.6895 28 59.6024 28.9129 59.6024 30.039V34.7513C59.6024 35.8774 58.6895 36.7902 57.5634 36.7902C56.4373 36.7902 55.5244 35.8774 55.5244 34.7513V30.039Z"
        class="fill-n-slate-10"
      />
      <path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M58.1862 24.173C50.5933 23.1017 44.4039 23.0594 36.6405 24.1683C34.678 24.4485 33.3796 24.638 32.3896 24.9273C31.4716 25.1956 30.9496 25.5155 30.5177 25.9981C29.6236 26.9974 29.5057 28.1276 29.3838 32.0695C29.264 35.9436 29.5013 39.4156 29.9507 43.3222C30.1901 45.4039 30.3549 46.8088 30.618 47.8769C30.8676 48.89 31.1694 49.4347 31.5889 49.8518C32.0117 50.2721 32.5536 50.5686 33.5482 50.8091C34.6002 51.0636 35.9806 51.2175 38.032 51.4413C44.6668 52.1652 49.6333 52.1615 56.2927 51.4451C58.369 51.2218 59.7719 51.0678 60.8396 50.815C61.8541 50.5749 62.3995 50.2805 62.8165 49.8722C63.2247 49.4724 63.5366 48.921 63.8071 47.8574C64.0894 46.7477 64.2815 45.2793 64.5594 43.1222C65.0553 39.2735 65.4123 35.8935 65.4262 32.1908C65.4411 28.232 65.3601 27.1056 64.4558 26.0608C64.019 25.5562 63.488 25.2244 62.5491 24.9481C61.5352 24.6497 60.2017 24.4573 58.1862 24.173ZM36.1664 20.849C44.2537 19.6939 50.7606 19.7391 58.6546 20.8529L58.7701 20.8692C60.6392 21.1328 62.2183 21.3555 63.4958 21.7315C64.8745 22.1372 66.0274 22.7532 66.991 23.8665C68.8087 25.9666 68.7969 28.4583 68.7811 31.7688C68.7804 31.9121 68.7797 32.057 68.7792 32.2034C68.7645 36.1184 68.3857 39.6634 67.8849 43.5506L67.8717 43.6535C67.6103 45.682 67.395 47.3537 67.0566 48.6839C66.7008 50.0827 66.169 51.282 65.1624 52.2678C64.1645 53.245 62.9854 53.7528 61.6119 54.0778C60.3149 54.3848 58.7011 54.5584 56.7558 54.7676L56.6513 54.7789C49.7551 55.5207 44.5465 55.5249 37.6684 54.7745L37.5622 54.7629C35.6442 54.5537 34.0471 54.3795 32.7599 54.0681C31.3915 53.7371 30.2202 53.219 29.2249 52.2296C28.2263 51.2369 27.7018 50.0571 27.3623 48.6788C27.0421 47.3788 26.856 45.7601 26.6318 43.8109L26.6197 43.7053C26.1588 39.6989 25.906 36.0546 26.0325 31.9659C26.037 31.8176 26.0414 31.6709 26.0458 31.5257C26.144 28.24 26.2178 25.7754 28.019 23.7623C28.9747 22.6942 30.1043 22.102 31.449 21.7089C32.6962 21.3444 34.2339 21.1249 36.0541 20.865C36.0914 20.8597 36.1288 20.8543 36.1664 20.849Z"
        class="fill-n-slate-10"
      />
      <path
        d="M103.999 72.4062H108.999C110.104 72.4062 110.999 73.3017 110.999 74.4062C110.999 75.5108 110.104 76.4062 108.999 76.4062H103.999V72.4062Z"
        class="fill-n-slate-9"
      />
      <path
        d="M63 72.4062H58C56.8954 72.4062 56 73.3017 56 74.4062C56 75.5108 56.8954 76.4062 58 76.4062H63V72.4062Z"
        class="fill-n-slate-9"
      />
      <path
        d="M67.049 70.0889C67.0432 68.5131 67.3478 66.9515 67.9454 65.4934C68.5431 64.0352 69.4221 62.7091 70.5322 61.5907C71.6424 60.4723 72.962 59.5834 74.4157 58.975C75.8693 58.3666 77.4286 58.0504 79.0044 58.0445C80.5803 58.0387 82.1419 58.3433 83.6 58.941C85.0581 59.5386 86.3843 60.4176 87.5027 61.5278C88.6211 62.638 89.5099 63.9576 90.1184 65.4112C90.7268 66.8649 91.043 68.4241 91.0488 70"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M83.999 59.4063C85.4527 58.7978 86.4227 58.4566 87.9986 58.4508C89.5744 58.445 91.136 58.7496 92.5941 59.3472C94.0523 59.9449 95.3784 60.8239 96.4968 61.9341C97.6153 63.0442 98.5041 64.3638 99.1125 65.8175C99.721 67.2711 100.037 68.8304 100.043 70.4062"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M71.4659 69.9421C71.462 68.8915 71.6651 67.8505 72.0635 66.8784C72.462 65.9063 73.048 65.0222 73.7881 64.2766C74.5282 63.531 75.4079 62.9384 76.377 62.5328C77.3462 62.1272 78.3857 61.9164 79.4362 61.9125C80.4868 61.9086 81.5278 62.1117 82.4999 62.5101C83.472 62.9086 84.3561 63.4946 85.1017 64.2347C85.8473 64.9748 86.4399 65.8545 86.8455 66.8236C87.2511 67.7927 87.4619 68.8322 87.4658 69.8828"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M88.4304 62.3188C89.4809 62.3149 90.522 62.5179 91.4941 62.9164C92.4662 63.3148 93.3503 63.9008 94.0959 64.6409C94.8415 65.381 95.434 66.2608 95.8397 67.2299C96.2453 68.199 96.4561 69.2385 96.46 70.2891"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M75.9473 69.9203C75.9454 69.395 76.0469 68.8745 76.2461 68.3884C76.4453 67.9024 76.7383 67.4603 77.1084 67.0875C77.4785 66.7147 77.9183 66.4184 78.4029 66.2156C78.8874 66.0128 79.4072 65.9074 79.9325 65.9055C80.4578 65.9035 80.9783 66.0051 81.4643 66.2043C81.9504 66.4035 82.3924 66.6965 82.7652 67.0666C83.138 67.4366 83.4343 67.8765 83.6371 68.361C83.8399 68.8456 83.9453 69.3653 83.9473 69.8906"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M90.4585 66.6066C90.9445 66.8058 91.3866 67.0988 91.7594 67.4689C92.1322 67.839 92.4284 68.2788 92.6313 68.7634C92.8341 69.2479 92.9395 69.7677 92.9414 70.293"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M102 69.9062C103.09 69.9062 104.032 70.7999 103.973 71.957C103.853 74.29 103.335 76.588 102.439 78.751C101.939 79.9592 101.499 80.8713 100.931 81.7236C100.363 82.5763 99.6906 83.3338 98.7646 84.2598C96.6889 86.3355 93.3531 87.0527 91.0576 87.0527H76.5576C73.9588 87.0527 70.4405 86.3497 68.3506 84.2598C67.4349 83.3441 66.737 82.5905 66.1416 81.7441C65.5415 80.8911 65.0682 79.9765 64.5605 78.751C63.6646 76.588 63.1471 74.29 63.0273 71.957C62.968 70.7999 63.9098 69.9062 65 69.9062H102Z"
        class="fill-n-slate-2 stroke-n-slate-9"
        stroke-width="2"
      />
      <g class="default-group">
        <path
          d="M84.37 23.002L82.32 20.962M91.07 24.002L88.61 21.542M78 30.702C78 30.702 87.87 27.202 90.73 24.342C91.1483 23.9244 91.4802 23.4285 91.7068 22.8826C91.9334 22.3367 92.0503 21.7516 92.0507 21.1605C92.0512 20.5695 91.9352 19.9841 91.7095 19.4379C91.4837 18.8917 91.1526 18.3952 90.735 17.977C90.3174 17.5587 89.8215 17.2268 89.2756 17.0002C88.7297 16.7736 88.1446 16.6567 87.5535 16.6563C86.9625 16.6558 86.3771 16.7717 85.8309 16.9975C85.2847 17.2233 84.7883 17.5544 84.37 17.972C81.5 20.842 78 30.702 78 30.702Z"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M97.7305 18C97.7305 18 96.4005 16 94.2305 16C92.5905 16 90.7305 18 90.7305 18C90.7305 18 92.0605 20 94.2305 20C96.4005 20 97.7305 18 97.7305 18Z"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M90.7305 11C90.7305 11 88.7305 12.33 88.7305 14.5C88.7305 16.67 90.7305 18 90.7305 18C90.7305 18 92.7305 16.16 92.7305 14.5C92.7305 12.33 90.7305 11 90.7305 11Z"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M103.013 39H103.023"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <animate
            attributeName="stroke-opacity"
            values="1;0;1"
            dur="1s"
            repeatCount="indefinite"
          />
        </path>
        <path
          d="M105.013 49C105.513 48.5 106.133 48 107.513 48C106.133 48 105.513 47.5 105.013 47"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M106.013 29C105.717 29.5892 105.252 30.0758 104.676 30.3965C104.101 30.7172 103.442 30.8571 102.786 30.798L96.6156 30.237C96.2934 30.206 95.9683 30.2409 95.6601 30.3394C95.3518 30.438 95.0668 30.5982 94.8224 30.8103C94.578 31.0224 94.3793 31.282 94.2383 31.5733C94.0974 31.8647 94.0171 32.1816 94.0025 32.5049C93.9878 32.8282 94.039 33.1511 94.153 33.454C94.267 33.7568 94.4415 34.0334 94.6657 34.2668C94.8899 34.5001 95.1592 34.6855 95.4573 34.8115C95.7553 34.9376 96.0759 35.0017 96.3996 35H107.513C109.236 35 110.89 35.6848 112.109 36.9038C113.328 38.1228 114.013 39.7761 114.013 41.5C114.013 43.2239 113.328 44.8772 112.109 46.0962C110.89 47.3152 109.236 48 107.513 48C108.176 48 108.811 47.7366 109.28 47.2678C109.749 46.7989 110.013 46.163 110.013 45.5C110.013 44.837 109.749 44.2011 109.28 43.7322C108.811 43.2634 108.176 43 107.513 43H104.013C102.156 43 100.376 42.2625 99.0628 40.9497C97.7501 39.637 97.0126 37.8565 97.0126 36V35"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M106.013 35C106.669 36.2311 107.013 37.6048 107.013 39C107.013 40.3952 106.669 41.7689 106.013 43"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M108.013 43C110.013 43 112.513 39 112.013 37"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </g>

      <!-- First -1 -->
      <g class="frame frame-1">
        <g filter="url(#filter0_d_720_25693)">
          <path
            d="M84.37 23.002L82.32 20.962M91.07 24.002L88.61 21.542M78 30.702C78 30.702 87.87 27.202 90.73 24.342C91.1483 23.9244 91.4802 23.4285 91.7068 22.8826C91.9334 22.3367 92.0503 21.7516 92.0507 21.1605C92.0512 20.5695 91.9352 19.9841 91.7095 19.4379C91.4837 18.8917 91.1526 18.3952 90.735 17.977C90.3174 17.5587 89.8215 17.2268 89.2756 17.0002C88.7297 16.7736 88.1446 16.6567 87.5535 16.6563C86.9625 16.6558 86.3771 16.7717 85.8309 16.9975C85.2847 17.2233 84.7883 17.5544 84.37 17.972C81.5 20.842 78 30.702 78 30.702Z"
            class="stroke-n-blue-11"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M97.7305 18C97.7305 18 96.4005 16 94.2305 16C92.5905 16 90.7305 18 90.7305 18C90.7305 18 92.0605 20 94.2305 20C96.4005 20 97.7305 18 97.7305 18Z"
            class="stroke-n-blue-11"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M90.7305 11C90.7305 11 88.7305 12.33 88.7305 14.5C88.7305 16.67 90.7305 18 90.7305 18C90.7305 18 92.7305 16.16 92.7305 14.5C92.7305 12.33 90.7305 11 90.7305 11Z"
            class="stroke-n-blue-11"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </g>
        <path
          d="M103.013 39H103.023"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <animate
            attributeName="stroke-opacity"
            values="1;0;1"
            dur="1s"
            repeatCount="indefinite"
          />
        </path>
        <path
          d="M105.013 49C105.513 48.5 106.133 48 107.513 48C106.133 48 105.513 47.5 105.013 47"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M106.013 29C105.717 29.5892 105.252 30.0758 104.676 30.3965C104.101 30.7172 103.442 30.8571 102.786 30.798L96.6156 30.237C96.2934 30.206 95.9683 30.2409 95.6601 30.3394C95.3518 30.438 95.0668 30.5982 94.8224 30.8103C94.578 31.0224 94.3793 31.282 94.2383 31.5733C94.0974 31.8647 94.0171 32.1816 94.0025 32.5049C93.9878 32.8282 94.039 33.1511 94.153 33.454C94.267 33.7568 94.4415 34.0334 94.6657 34.2668C94.8899 34.5001 95.1592 34.6855 95.4573 34.8115C95.7553 34.9376 96.0759 35.0017 96.3996 35H107.513C109.236 35 110.89 35.6848 112.109 36.9038C113.328 38.1228 114.013 39.7761 114.013 41.5C114.013 43.2239 113.328 44.8772 112.109 46.0962C110.89 47.3152 109.236 48 107.513 48C108.176 48 108.811 47.7366 109.28 47.2678C109.749 46.7989 110.013 46.163 110.013 45.5C110.013 44.837 109.749 44.2011 109.28 43.7322C108.811 43.2634 108.176 43 107.513 43H104.013C102.156 43 100.376 42.2625 99.0628 40.9497C97.7501 39.637 97.0126 37.8565 97.0126 36V35"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M106.013 35C106.669 36.2311 107.013 37.6048 107.013 39C107.013 40.3952 106.669 41.7689 106.013 43"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M108.013 43C110.013 43 112.513 39 112.013 37"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </g>

      <!-- Second -2 -->
      <g class="frame frame-2">
        <path
          d="M84.37 23.002L82.32 20.962M91.07 24.002L88.61 21.542M78 30.702C78 30.702 87.87 27.202 90.73 24.342C91.1483 23.9244 91.4802 23.4285 91.7068 22.8826C91.9334 22.3367 92.0503 21.7516 92.0507 21.1605C92.0512 20.5695 91.9352 19.9841 91.7095 19.4379C91.4837 18.8917 91.1526 18.3952 90.735 17.977C90.3174 17.5587 89.8215 17.2268 89.2756 17.0002C88.7297 16.7736 88.1446 16.6567 87.5535 16.6563C86.9625 16.6558 86.3771 16.7717 85.8309 16.9975C85.2847 17.2233 84.7883 17.5544 84.37 17.972C81.5 20.842 78 30.702 78 30.702Z"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M97.7305 18C97.7305 18 96.4005 16 94.2305 16C92.5905 16 90.7305 18 90.7305 18C90.7305 18 92.0605 20 94.2305 20C96.4005 20 97.7305 18 97.7305 18Z"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M90.7305 11C90.7305 11 88.7305 12.33 88.7305 14.5C88.7305 16.67 90.7305 18 90.7305 18C90.7305 18 92.7305 16.16 92.7305 14.5C92.7305 12.33 90.7305 11 90.7305 11Z"
          class="stroke-n-slate-10"
          stroke-width="1.6"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <g filter="url(#filter0_d_720_25692)">
          <path
            d="M103.013 39H103.023"
            class="stroke-n-blue-11"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <animate
              attributeName="stroke-opacity"
              values="1;0;1"
              dur="1s"
              repeatCount="indefinite"
            />
          </path>
          <path
            d="M105.013 49C105.513 48.5 106.133 48 107.513 48C106.133 48 105.513 47.5 105.013 47"
            class="stroke-n-blue-11"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M106.013 29C105.717 29.5892 105.252 30.0758 104.676 30.3965C104.101 30.7172 103.442 30.8571 102.786 30.798L96.6156 30.237C96.2934 30.206 95.9683 30.2409 95.6601 30.3394C95.3518 30.438 95.0668 30.5982 94.8224 30.8103C94.578 31.0224 94.3793 31.282 94.2383 31.5733C94.0974 31.8647 94.0171 32.1816 94.0025 32.5049C93.9878 32.8282 94.039 33.1511 94.153 33.454C94.267 33.7568 94.4415 34.0334 94.6657 34.2668C94.8899 34.5001 95.1592 34.6855 95.4573 34.8115C95.7553 34.9376 96.0759 35.0017 96.3996 35H107.513C109.236 35 110.89 35.6848 112.109 36.9038C113.328 38.1228 114.013 39.7761 114.013 41.5C114.013 43.2239 113.328 44.8772 112.109 46.0962C110.89 47.3152 109.236 48 107.513 48C108.176 48 108.811 47.7366 109.28 47.2678C109.749 46.7989 110.013 46.163 110.013 45.5C110.013 44.837 109.749 44.2011 109.28 43.7322C108.811 43.2634 108.176 43 107.513 43H104.013C102.156 43 100.376 42.2625 99.0628 40.9497C97.7501 39.637 97.0126 37.8565 97.0126 36V35"
            class="stroke-n-blue-11"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M106.013 35C106.669 36.2311 107.013 37.6048 107.013 39C107.013 40.3952 106.669 41.7689 106.013 43"
            class="stroke-n-blue-11"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M108.013 43C110.013 43 112.513 39 112.013 37"
            class="stroke-n-blue-11"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </g>
      </g>

      <defs>
        <radialGradient
          id="paint0_radial_720_25695"
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
  pointer-events: none;
}

.frame {
  opacity: 0;
  animation-name: frameVisible;
  animation-duration: 800ms;
  animation-iteration-count: infinite;
  animation-timing-function: steps(1, end);
  transform-origin: center;
}

.frame-1 {
  animation-delay: 0ms;
}
.frame-2 {
  animation-delay: 400ms;
}

@keyframes frameVisible {
  0% {
    opacity: 1;
  }
  50% {
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
