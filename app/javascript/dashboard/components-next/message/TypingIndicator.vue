<template>
  <svg
    class="w-8 h-4"
    viewBox="0 0 120 30"
    xmlns="http://www.w3.org/2000/svg"
    fill="currentColor"
  >
    <circle cx="15" cy="15" r="12">
      <animate
        attributeName="cy"
        from="15"
        to="5"
        begin="0s"
        dur="0.9s"
        values="15;5;15;15;15;15"
        calcMode="linear"
        repeatCount="indefinite"
      />
    </circle>
    <circle cx="55" cy="15" r="12">
      <animate
        attributeName="cy"
        from="15"
        to="5"
        begin="0.1s"
        dur="0.9s"
        values="15;5;15;15;15;15"
        calcMode="linear"
        repeatCount="indefinite"
      />
    </circle>
    <circle cx="95" cy="15" r="12">
      <animate
        attributeName="cy"
        from="15"
        to="5"
        begin="0.2s"
        dur="0.9s"
        values="15;5;15;15;15;15"
        calcMode="linear"
        repeatCount="indefinite"
      />
    </circle>
  </svg>
</template>
