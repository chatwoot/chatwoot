<template>
  <div class="gift-icon">
    <woot-button
      class-names="gift-icon--button"
      variant="clear"
      color-scheme="secondary"
      @click="$emit('open-promo-popup')"
    >
      <div class="sparkles">
        <svg
          width="12"
          height="12"
          viewBox="0 0 12 12"
          class="sparkle sparkle-1"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <g clip-path="url(#clip0_424_2)">
            <path
              d="M5.999 0L3.95734 3.872L0 5.936L3.95734 8.128L5.999 12L8.16864 8.128L12 5.936L8.16864 3.872L5.999 0Z"
              fill="#6AC6E2"
            />
          </g>
          <defs>
            <clipPath id="clip0_424_2">
              <rect width="12" height="12" fill="white" />
            </clipPath>
          </defs>
        </svg>
        <svg
          width="10"
          height="10"
          class="sparkle sparkle-2"
          viewBox="0 0 10 10"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <g clip-path="url(#clip0_424_4)">
            <path
              d="M4.99917 0L3.29778 3.22667L0 4.94667L3.29778 6.77333L4.99917 10L6.8072 6.77333L10 4.94667L6.8072 3.22667L4.99917 0Z"
              fill="#00437F"
            />
          </g>
          <defs>
            <clipPath id="clip0_424_4">
              <rect width="10" height="10" fill="white" />
            </clipPath>
          </defs>
        </svg>

        <svg
          class="sparkle sparkle-3"
          width="4"
          height="4"
          viewBox="0 0 4 4"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <g clip-path="url(#clip0_424_6)">
            <path
              d="M2 4C3.10457 4 4 3.10457 4 2C4 0.895431 3.10457 0 2 0C0.895431 0 0 0.895431 0 2C0 3.10457 0.895431 4 2 4Z"
              fill="#0086FF"
            />
          </g>
          <defs>
            <clipPath id="clip0_424_6">
              <rect width="4" height="4" fill="white" />
            </clipPath>
          </defs>
        </svg>
      </div>
      <svg
        width="512"
        height="512"
        class="gift-icon--svg"
        viewBox="0 0 512 512"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M415.534 259.599L366.934 241.898C365.434 241.299 363.634 240.999 361.835 240.999H50.4349C42.0339 240.999 35.4349 247.598 35.4349 255.999V466.999C35.4349 491.898 55.5339 511.999 80.4349 511.999H380.435C405.336 511.999 425.435 491.898 425.435 466.999V273.698C425.435 267.399 421.534 261.699 415.534 259.599Z"
          fill="#FC1A40"
        />
        <path
          d="M425.435 273.698V466.999C425.435 491.898 405.336 511.999 380.435 511.999H230.435V240.999H361.835C363.635 240.999 365.435 241.299 366.934 241.898L415.534 259.599C421.534 261.699 425.435 267.399 425.435 273.698Z"
          fill="#C60034"
        />
        <path
          d="M420.035 97.7878C414.936 77.0878 399.635 60.8888 378.935 54.2878C358.535 47.9868 336.634 52.4878 320.735 66.8868L285.934 97.4878L279.035 51.5888C275.735 30.5888 262.235 12.8878 242.136 4.48882C238.236 2.98782 234.336 1.78782 230.436 1.18782C213.936 -2.11218 196.836 1.48782 183.035 11.6888C164.735 24.8888 155.436 47.0888 158.435 69.2878C161.736 91.4878 176.736 110.388 198.035 117.888L230.436 129.588L270.336 144.288C270.636 144.288 270.636 144.288 270.636 144.288L339.936 169.787C346.835 172.188 354.035 173.389 360.935 173.389C375.637 173.389 390.036 167.987 401.436 157.788C418.235 142.788 425.435 119.687 420.035 97.7878Z"
          fill="#FE9923"
        />
        <path
          d="M401.435 157.788C390.035 167.987 375.635 173.389 360.934 173.389C354.035 173.389 346.835 172.188 339.935 169.787L270.635 144.288C270.635 144.288 270.635 144.288 270.335 144.288L230.435 129.588V1.18701C234.335 1.78801 238.235 2.98701 242.135 4.48801C262.234 12.887 275.735 30.588 279.034 51.588L285.933 97.487L320.734 66.886C336.633 52.487 358.534 47.986 378.934 54.287C399.634 60.888 414.934 77.087 420.034 97.787C425.435 119.687 418.235 142.788 401.435 157.788Z"
          fill="#FE8821"
        />
        <path
          d="M476.735 234.098L456.335 290.498C453.934 296.498 448.234 300.098 442.234 300.098C440.434 300.098 438.634 299.798 437.135 299.199L282.034 242.799L267.935 196.299L230.435 204.698L197.436 212.198L42.3349 155.798C34.5349 152.799 30.6359 144.098 33.3349 136.598L54.0349 80.1996C57.9349 68.7996 66.3359 59.7976 77.1359 54.6986C87.9359 49.5996 100.235 48.9986 111.635 53.1986L230.436 96.3986L238.537 99.3976C238.537 99.3976 270.936 158.199 271.837 158.199C272.438 158.199 285.337 150.999 297.937 144.098C310.534 137.198 323.135 129.999 323.135 129.999L449.734 176.198C461.134 180.398 470.134 188.799 475.233 199.599C480.335 210.398 480.934 222.699 476.735 234.098Z"
          fill="#FF3E75"
        />
        <path
          d="M476.735 234.098L456.335 290.498C453.934 296.498 448.234 300.098 442.234 300.098C440.434 300.098 438.634 299.798 437.135 299.199L282.034 242.799L267.935 196.299L230.435 204.698V96.3989L238.536 99.3979C238.536 99.3979 270.935 158.199 271.836 158.199C272.437 158.199 285.336 150.999 297.936 144.098C310.534 137.198 323.135 129.999 323.135 129.999L449.734 176.198C461.134 180.398 470.134 188.799 475.233 199.599C480.335 210.398 480.934 222.699 476.735 234.098Z"
          fill="#FC1A40"
        />
        <path
          d="M185.435 240.999V511.999H275.435V240.999H185.435Z"
          fill="#FCBF29"
        />
        <path
          d="M238.535 99.3979L230.434 121.598L197.435 212.199L230.434 224.2L267.934 237.7L282.033 242.799L323.135 129.999L238.535 99.3979Z"
          fill="#FCBF29"
        />
        <path
          d="M275.439 240.999H230.439V511.999H275.439V240.999Z"
          fill="#FE9923"
        />
        <path
          d="M323.135 129.999L282.034 242.799L267.935 237.699L230.435 224.199V121.598L238.535 99.3979L323.135 129.999Z"
          fill="#FE9923"
        />
      </svg>
    </woot-button>
  </div>
</template>

<script>
export default {};
</script>

<style scoped lang="scss">
.gift-icon--button {
  display: flex;
  position: relative;
  border-radius: var(--border-radius-large);
  border: 1px solid transparent;
  color: var(--s-600);

  &:hover {
    background: var(--w-50);
    color: var(--s-600);
  }

  &:focus {
    border-color: var(--w-500);
  }

  &.is-active {
    background: var(--w-50);
    color: var(--w-500);
  }
}
.gift-icon--svg {
  height: var(--space-medium);
  width: var(--space-medium);
  animation: float 3s ease-in-out infinite;
  position: relative;
}

@keyframes float {
  0% {
    transform: translatey(0px);
  }
  50% {
    transform: translatey(-5px);
  }
  100% {
    transform: translatey(0px);
  }
}
.sparkle {
  position: absolute;
}
.sparkle-1 {
  top: 0;
  left: 0;
  animation: twinkle 2.4s ease infinite;
  transition-timing-function: cubic-bezier(0.17, 0.67, 0.83, 0.67);
}
.sparkle-2 {
  right: 0;
  bottom: 0;
  animation: twinkle 2.6s ease infinite;
  transition-timing-function: cubic-bezier(0.17, 0.67, 0.83, 0.67);
}
.sparkle-3 {
  right: 0;
  top: 0;
  animation: twinkle2 2.2s ease infinite;
  transition-timing-function: cubic-bezier(0.17, 0.67, 0.83, 0.67);
}

@keyframes twinkle {
  0% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.1;
    transform: scale(0.5);
  }
  100% {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes twinkle2 {
  0% {
    opacity: 1;
  }
  50% {
    opacity: 0.1;
    transform: scale(0.8);
  }
  100% {
    opacity: 1;
  }
}
</style>
