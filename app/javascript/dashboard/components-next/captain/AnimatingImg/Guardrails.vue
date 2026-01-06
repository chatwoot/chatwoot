<script setup>
import { ref } from 'vue';

const hidden = ref(false);

const toggle = () => {
  hidden.value = !hidden.value;
};
</script>

<template>
  <div
    class="svg-wrapper relative"
    role="button"
    :aria-pressed="!hidden"
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
      <rect width="136" height="108" fill="url(#paint0_radial_720_25689)" />
      <path
        d="M47 36.039C47 34.9129 47.9129 34 49.039 34C50.1651 34 51.0779 34.9129 51.0779 36.039V40.7513C51.0779 41.8774 50.1651 42.7902 49.039 42.7902C47.9129 42.7902 47 41.8774 47 40.7513V36.039Z"
        class="fill-n-slate-10"
      />
      <path
        d="M53.5244 36.039C53.5244 34.9129 54.4373 34 55.5634 34C56.6895 34 57.6024 34.9129 57.6024 36.039V40.7513C57.6024 41.8774 56.6895 42.7902 55.5634 42.7902C54.4373 42.7902 53.5244 41.8774 53.5244 40.7513V36.039Z"
        class="fill-n-slate-10"
      />
      <path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M58.1862 24.173C50.5933 23.1017 44.4039 23.0594 36.6405 24.1683C34.678 24.4485 33.3796 24.638 32.3896 24.9273C31.4716 25.1956 30.9496 25.5155 30.5177 25.9981C29.6236 26.9974 29.5057 28.1276 29.3838 32.0695C29.264 35.9436 29.5013 39.4156 29.9507 43.3222C30.1901 45.4039 30.3549 46.8088 30.618 47.8769C30.8676 48.89 31.1694 49.4347 31.5889 49.8518C32.0117 50.2721 32.5536 50.5686 33.5482 50.8091C34.6002 51.0636 35.9806 51.2175 38.032 51.4413C44.6668 52.1652 49.6333 52.1615 56.2927 51.4451C58.369 51.2218 59.7719 51.0678 60.8396 50.815C61.8541 50.5749 62.3995 50.2805 62.8165 49.8722C63.2247 49.4724 63.5366 48.921 63.8071 47.8574C64.0894 46.7477 64.2815 45.2793 64.5594 43.1222C65.0553 39.2735 65.4123 35.8935 65.4262 32.1908C65.4411 28.232 65.3601 27.1056 64.4558 26.0608C64.019 25.5562 63.488 25.2244 62.5491 24.9481C61.5352 24.6497 60.2017 24.4573 58.1862 24.173ZM36.1664 20.849C44.2537 19.6939 50.7606 19.7391 58.6546 20.8529L58.7701 20.8692C60.6392 21.1328 62.2183 21.3555 63.4958 21.7315C64.8745 22.1372 66.0274 22.7532 66.991 23.8665C68.8087 25.9666 68.7969 28.4583 68.7811 31.7688C68.7804 31.9121 68.7797 32.057 68.7792 32.2034C68.7645 36.1184 68.3857 39.6634 67.8849 43.5506L67.8717 43.6535C67.6103 45.682 67.395 47.3537 67.0566 48.6839C66.7008 50.0827 66.169 51.282 65.1624 52.2678C64.1645 53.245 62.9854 53.7528 61.6119 54.0778C60.3149 54.3848 58.7011 54.5584 56.7558 54.7676L56.6513 54.7789C49.7551 55.5207 44.5465 55.5249 37.6684 54.7745L37.5622 54.7629C35.6442 54.5537 34.0471 54.3795 32.7599 54.0681C31.3915 53.7371 30.2202 53.219 29.2249 52.2296C28.2263 51.2369 27.7018 50.0571 27.3623 48.6788C27.0421 47.3788 26.856 45.7601 26.6318 43.8109L26.6197 43.7053C26.1588 39.6989 25.906 36.0546 26.0325 31.9659C26.037 31.8176 26.0414 31.6709 26.0458 31.5257C26.144 28.24 26.2178 25.7754 28.019 23.7623C28.9747 22.6942 30.1043 22.102 31.449 21.7089C32.6962 21.3444 34.2339 21.1249 36.0541 20.865C36.0914 20.8597 36.1288 20.8543 36.1664 20.849Z"
        class="fill-n-slate-10"
      />
      <path
        d="M110.008 68.5613C110.835 68.5197 111.54 69.1568 111.581 69.9842C111.623 70.8116 110.986 71.516 110.158 71.5575L105.664 71.783L105.514 68.7868L110.008 68.5613Z"
        class="fill-n-slate-2 stroke-n-slate-9"
      />
      <path
        d="M59.0714 71.1172C58.244 71.1587 57.6069 71.8631 57.6484 72.6905C57.69 73.5178 58.3944 74.1549 59.2217 74.1134L63.7161 73.8878L63.5657 70.8916L59.0714 71.1172Z"
        class="fill-n-slate-2 stroke-n-slate-9"
      />
      <path
        d="M67.9694 67.8503C67.8845 66.2767 68.1105 64.7018 68.6343 63.2156C69.1581 61.7293 69.9696 60.3608 71.0223 59.1881C72.075 58.0155 73.3484 57.0617 74.7697 56.3811C76.1911 55.7006 77.7325 55.3067 79.3061 55.2218C80.8797 55.137 82.4546 55.363 83.9408 55.8868C85.4271 56.4106 86.7956 57.2221 87.9683 58.2748C89.1409 59.3275 90.0948 60.6009 90.7753 62.0222C91.4558 63.4436 91.8498 64.985 91.9346 66.5586"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M84.3624 56.3297C85.7837 55.6491 86.7355 55.2598 88.309 55.175C89.8826 55.0901 91.4575 55.3161 92.9438 55.8399C94.43 56.3638 95.7985 57.1752 96.9712 58.2279C98.1439 59.2806 99.0977 60.554 99.7782 61.9753C100.459 63.3967 100.853 64.9381 100.937 66.5117"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M72.3738 67.4861C72.3172 66.4371 72.4679 65.3872 72.8171 64.3963C73.1663 63.4055 73.7073 62.4931 74.4091 61.7114C75.1109 60.9296 75.9598 60.2937 76.9074 59.84C77.8549 59.3863 78.8826 59.1237 79.9316 59.0672C80.9807 59.0106 82.0306 59.1613 83.0214 59.5105C84.0123 59.8597 84.9246 60.4006 85.7064 61.1025C86.4882 61.8043 87.124 62.6532 87.5777 63.6007C88.0314 64.5483 88.294 65.5759 88.3506 66.625"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M88.9345 59.0203C89.9836 58.9637 91.0335 59.1144 92.0244 59.4636C93.0152 59.8128 93.9275 60.3538 94.7093 61.0556C95.4911 61.7574 96.127 62.6063 96.5807 63.5539C97.0344 64.5014 97.297 65.5291 97.3535 66.5781"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M76.8475 67.2353C76.8193 66.7107 76.8946 66.1858 77.0692 65.6904C77.2438 65.1949 77.5143 64.7388 77.8652 64.3479C78.2161 63.957 78.6405 63.639 79.1143 63.4122C79.5881 63.1853 80.1019 63.054 80.6265 63.0258C81.151 62.9975 81.6759 63.0728 82.1714 63.2474C82.6668 63.422 83.1229 63.6925 83.5138 64.0434C83.9047 64.3943 84.2227 64.8188 84.4495 65.2926C84.6764 65.7663 84.8077 66.2802 84.8359 66.8047"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <path
        d="M91.1753 63.2005C91.6707 63.3752 92.1269 63.6456 92.5177 63.9965C92.9086 64.3474 93.2266 64.7719 93.4534 65.2457C93.6803 65.7195 93.8116 66.2333 93.8398 66.7578"
        class="stroke-n-blue-11"
        stroke-width="1.6"
      />
      <mask
        id="path-12-outside-1_720_25689"
        maskUnits="userSpaceOnUse"
        x="62.8409"
        y="64.2675"
        width="44.1488"
        height="26.125"
        fill="black"
      >
        <rect
          fill="white"
          x="62.8409"
          y="64.2675"
          width="44.1488"
          height="26.125"
        />
        <path
          d="M102.916 66.9147C103.468 66.887 103.94 67.3119 103.939 67.8642C103.937 70.0863 103.554 72.2942 102.806 74.3919C101.946 76.8039 100.619 79.0228 98.9015 80.9221C97.1838 82.8213 95.1088 84.3636 92.7951 85.4609C90.4813 86.5582 87.9741 87.189 85.4165 87.3174C82.859 87.4457 80.3012 87.0691 77.8892 86.2089C75.4772 85.3488 73.2582 84.0219 71.359 82.3042C69.4598 80.5865 67.9175 78.5116 66.8202 76.1978C65.8659 74.1856 65.2644 72.027 65.0394 69.8163C64.9835 69.2668 65.4108 68.7968 65.9624 68.7691L84.4392 67.8419L102.916 66.9147Z"
        />
      </mask>
      <path
        d="M102.916 66.9147C103.468 66.887 103.94 67.3119 103.939 67.8642C103.937 70.0863 103.554 72.2942 102.806 74.3919C101.946 76.8039 100.619 79.0228 98.9015 80.9221C97.1838 82.8213 95.1088 84.3636 92.7951 85.4609C90.4813 86.5582 87.9741 87.189 85.4165 87.3174C82.859 87.4457 80.3012 87.0691 77.8892 86.2089C75.4772 85.3488 73.2582 84.0219 71.359 82.3042C69.4598 80.5865 67.9175 78.5116 66.8202 76.1978C65.8659 74.1856 65.2644 72.027 65.0394 69.8163C64.9835 69.2668 65.4108 68.7968 65.9624 68.7691L84.4392 67.8419L102.916 66.9147Z"
        class="fill-n-slate-2"
      />
      <path
        d="M102.916 66.9147C103.468 66.887 103.94 67.3119 103.939 67.8642C103.937 70.0863 103.554 72.2942 102.806 74.3919C101.946 76.8039 100.619 79.0228 98.9015 80.9221C97.1838 82.8213 95.1088 84.3636 92.7951 85.4609C90.4813 86.5582 87.9741 87.189 85.4165 87.3174C82.859 87.4457 80.3012 87.0691 77.8892 86.2089C75.4772 85.3488 73.2582 84.0219 71.359 82.3042C69.4598 80.5865 67.9175 78.5116 66.8202 76.1978C65.8659 74.1856 65.2644 72.027 65.0394 69.8163C64.9835 69.2668 65.4108 68.7968 65.9624 68.7691L84.4392 67.8419L102.916 66.9147Z"
        class="stroke-n-slate-9"
        stroke-width="4"
        mask="url(#path-12-outside-1_720_25689)"
      />
      <circle
        cx="71.2325"
        cy="74.0111"
        r="0.5"
        transform="rotate(-2.87289 71.2325 74.0111)"
        class="fill-n-slate-2 stroke-n-slate-9"
      />
      <circle
        cx="78.6241"
        cy="81.6517"
        r="0.5"
        transform="rotate(-2.87289 78.6241 81.6517)"
        class="fill-n-slate-2 stroke-n-slate-9"
      />
      <circle
        cx="80.2207"
        cy="73.5619"
        r="0.5"
        transform="rotate(-2.87289 80.2207 73.5619)"
        class="fill-n-slate-2 stroke-n-slate-9"
      />
      <circle
        cx="85.6153"
        cy="81.3002"
        r="0.5"
        transform="rotate(-2.87289 85.6153 81.3002)"
        class="fill-n-slate-2 stroke-n-slate-9"
      />
      <circle
        cx="88.211"
        cy="73.1596"
        r="0.5"
        transform="rotate(-2.87289 88.211 73.1596)"
        class="fill-n-slate-2 stroke-n-slate-9"
      />
      <circle
        cx="92.6065"
        cy="80.9486"
        r="0.5"
        transform="rotate(-2.87289 92.6065 80.9486)"
        class="fill-n-slate-2 stroke-n-slate-9"
      />
      <circle
        cx="97.1993"
        cy="72.7103"
        r="0.5"
        transform="rotate(-2.87289 97.1993 72.7103)"
        class="fill-n-slate-2 stroke-n-slate-9"
      />
      <!-- Frame 1 -->
      <g
        class="frame frame-1"
        :class="{ 'paused-or-hidden': hidden }"
        aria-hidden="false"
      >
        <path
          d="M76.6923 91.9366C76.973 92.348 77.3111 92.714 77.6883 93.0053C78.2732 93.457 78.5492 93.9827 78.5894 94.5226C78.6298 95.0667 78.4743 95.5914 78.1748 95.9816C77.8773 96.3692 77.4664 96.5897 77.0404 96.6209C76.6144 96.6521 76.1754 96.494 75.8237 96.1539C75.4699 95.8116 75.2385 95.3153 75.1981 94.7712C75.158 94.2312 75.3541 93.6711 75.8661 93.1389C76.1961 92.7958 76.4755 92.3844 76.6923 91.9366Z"
          class="stroke-n-blue-11"
          stroke-width="1.2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M87.2968 94.1553C87.5775 94.5668 87.9156 94.9327 88.2928 95.224C88.8777 95.6758 89.1537 96.2014 89.1938 96.7413C89.2343 97.2854 89.0788 97.8101 88.7793 98.2003C88.4818 98.5879 88.0709 98.8084 87.6449 98.8397C87.2189 98.8708 86.7799 98.7128 86.4282 98.3727C86.0744 98.0304 85.843 97.534 85.8026 96.9899C85.7625 96.4499 85.9586 95.8898 86.4705 95.3576C86.8006 95.0145 87.08 94.6032 87.2968 94.1553Z"
          class="stroke-n-blue-11"
          stroke-width="1.2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M95.9784 89.4991C96.2592 89.9105 96.5972 90.2765 96.9744 90.5678C97.5593 91.0195 97.8353 91.5452 97.8755 92.0851C97.9159 92.6292 97.7604 93.1539 97.461 93.5441C97.1634 93.9317 96.7525 94.1522 96.3265 94.1834C95.9005 94.2146 95.4615 94.0565 95.1099 93.7164C94.756 93.3741 94.5246 92.8778 94.4842 92.3337C94.4441 91.7937 94.6402 91.2336 95.1522 90.7014C95.4822 90.3583 95.7616 89.9469 95.9784 89.4991Z"
          class="stroke-n-blue-11"
          stroke-width="1.2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </g>

      <!-- Frame 2 -->
      <g class="frame frame-2" :class="{ 'paused-or-hidden': hidden }">
        <path
          d="M76.6923 93.9366C76.973 94.348 77.3111 94.714 77.6883 95.0053C78.2732 95.457 78.5492 95.9827 78.5894 96.5226C78.6298 97.0667 78.4743 97.5914 78.1748 97.9816C77.8773 98.3692 77.4664 98.5897 77.0404 98.6209C76.6144 98.6521 76.1754 98.494 75.8237 98.1539C75.4699 97.8116 75.2385 97.3153 75.1981 96.7712C75.158 96.2312 75.3541 95.6711 75.8661 95.1389C76.1961 94.7958 76.4755 94.3844 76.6923 93.9366Z"
          class="stroke-n-blue-11"
          stroke-width="1.2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M87.2968 96.1553C87.5775 96.5668 87.9156 96.9327 88.2928 97.224C88.8777 97.6758 89.1537 98.2014 89.1938 98.7413C89.2343 99.2854 89.0788 99.8101 88.7793 100.2C88.4818 100.588 88.0709 100.808 87.6449 100.84C87.2189 100.871 86.7799 100.713 86.4282 100.373C86.0744 100.03 85.843 99.534 85.8026 98.9899C85.7625 98.4499 85.9586 97.8898 86.4705 97.3576C86.8006 97.0145 87.08 96.6032 87.2968 96.1553Z"
          class="stroke-n-blue-11"
          stroke-width="1.2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M95.9784 91.4991C96.2592 91.9105 96.5972 92.2765 96.9744 92.5678C97.5593 93.0195 97.8353 93.5452 97.8755 94.0851C97.9159 94.6292 97.7604 95.1539 97.461 95.5441C97.1634 95.9317 96.7525 96.1522 96.3265 96.1834C95.9005 96.2146 95.4615 96.0565 95.1099 95.7164C94.756 95.3741 94.5246 94.8778 94.4842 94.3337C94.4441 93.7937 94.6402 93.2336 95.1522 92.7014C95.4822 92.3583 95.7616 91.9469 95.9784 91.4991Z"
          class="stroke-n-blue-11"
          stroke-width="1.2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </g>

      <!-- Frame 3 -->
      <g class="frame frame-3" :class="{ 'paused-or-hidden': hidden }">
        <path
          d="M76.6923 94.9366C76.973 95.348 77.3111 95.714 77.6883 96.0053C78.2732 96.457 78.5492 96.9827 78.5894 97.5226C78.6298 98.0667 78.4743 98.5914 78.1748 98.9816C77.8773 99.3692 77.4664 99.5897 77.0404 99.6209C76.6144 99.6521 76.1754 99.494 75.8237 99.1539C75.4699 98.8116 75.2385 98.3153 75.1981 97.7712C75.158 97.2312 75.3541 96.6711 75.8661 96.1389C76.1961 95.7958 76.4755 95.3844 76.6923 94.9366Z"
          class="stroke-n-blue-11"
          stroke-width="1.2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M87.2968 97.1553C87.5775 97.5668 87.9156 97.9327 88.2928 98.224C88.8777 98.6758 89.1537 99.2014 89.1938 99.7413C89.2343 100.285 89.0788 100.81 88.7793 101.2C88.4818 101.588 88.0709 101.808 87.6449 101.84C87.2189 101.871 86.7799 101.713 86.4282 101.373C86.0744 101.03 85.843 100.534 85.8026 99.9899C85.7625 99.4499 85.9586 98.8898 86.4705 98.3576C86.8006 98.0145 87.08 97.6032 87.2968 97.1553Z"
          class="stroke-n-blue-11"
          stroke-width="1.2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M95.9784 92.4991C96.2592 92.9105 96.5972 93.2765 96.9744 93.5678C97.5593 94.0195 97.8353 94.5452 97.8755 95.0851C97.9159 95.6292 97.7604 96.1539 97.461 96.5441C97.1634 96.9317 96.7525 97.1522 96.3265 97.1834C95.9005 97.2146 95.4615 97.0565 95.1099 96.7164C94.756 96.3741 94.5246 95.8778 94.4842 95.3337C94.4441 94.7937 94.6402 94.2336 95.1522 93.7014C95.4822 93.3583 95.7616 92.9469 95.9784 92.4991Z"
          class="stroke-n-blue-11"
          stroke-width="1.2"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </g>
      <defs>
        <radialGradient
          id="paint0_radial_720_25689"
          cx="0"
          cy="0"
          r="1"
          gradientUnits="userSpaceOnUse"
          gradientTransform="translate(68 54) rotate(90) scale(54 68)"
        >
          <stop
            offset="0.527769"
            stop-color="var(--gradient-start)"
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

.paused-or-hidden {
  animation-play-state: paused !important;
  opacity: 0 !important;
  pointer-events: none;
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
</style>
