<template>
  <div class="flex items-center w-full overflow-y-auto">
    <div
      class="flex flex-col h-full p-5 pt-16 mx-auto my-0 bg-white dark:bg-slate-900 font-inter"
    >
      <div class="flex flex-col gap-3">
        <h2 class="mt-4 text-2xl font-medium text-ash-900">Button</h2>

        <h2 class="mt-4 text-lg font-medium text-ash-900">Color</h2>
        <div
          class="flex justify-start gap-6 p-4 border border-dashed border-ash-500 rounded-xl"
        >
          <div class="flex flex-col gap-3">
            <form-button type="submit" variant="solid" icon="text-copy">
              Copy
            </form-button>
            <label class="text-center uppercase text-ash-900">Primary</label>
          </div>
          <div class="flex flex-col gap-3">
            <form-button
              type="submit"
              color-scheme="secondary"
              variant="solid"
              icon="text-copy"
            >
              Copy
            </form-button>
            <label class="text-center uppercase text-ash-900">Secondary</label>
          </div>

          <div class="flex flex-col gap-3">
            <form-button
              type="submit"
              color-scheme="danger"
              variant="solid"
              size="large"
              icon="text-copy"
            >
              Copy
            </form-button>
            <label class="text-center uppercase text-ash-900">Alert</label>
          </div>
        </div>

        <h2 class="mt-4 text-lg font-medium text-ash-900">Style</h2>
        <div
          class="flex flex-col justify-start gap-6 p-4 border border-dashed border-ash-500 rounded-xl"
        >
          <div class="flex gap-6">
            <div class="flex flex-col gap-3">
              <form-button
                type="submit"
                color-scheme="primary"
                variant="solid"
                size="large"
                icon="text-copy"
              >
                Copy
              </form-button>
              <label class="text-center uppercase text-ash-900">Solid</label>
            </div>
            <div class="flex flex-col gap-3">
              <form-button
                type="submit"
                color-scheme="primary"
                variant="outline"
                size="large"
                icon="text-copy"
              >
                Copy
              </form-button>
              <label class="text-center uppercase text-ash-900">Outlined</label>
            </div>
            <div class="flex flex-col gap-3">
              <form-button
                type="submit"
                color-scheme="primary"
                variant="ghost"
                size="large"
                icon="text-copy"
              >
                Copy
              </form-button>
              <label class="text-center uppercase text-ash-900">Ghost</label>
            </div>
          </div>
          <div class="flex gap-6">
            <div class="flex flex-col gap-3">
              <form-button
                type="submit"
                color-scheme="secondary"
                variant="solid"
                size="large"
                icon="text-copy"
              >
                Copy
              </form-button>
              <label class="text-center uppercase text-ash-900">Solid</label>
            </div>
            <div class="flex flex-col gap-3">
              <form-button
                type="submit"
                color-scheme="secondary"
                variant="outline"
                size="large"
                icon="text-copy"
              >
                Copy
              </form-button>
              <label class="text-center uppercase text-ash-900">Outlined</label>
            </div>
            <div class="flex flex-col gap-3">
              <form-button
                type="submit"
                color-scheme="secondary"
                variant="ghost"
                size="large"
                icon="text-copy"
              >
                Copy
              </form-button>
              <label class="text-center uppercase text-ash-900">Ghost</label>
            </div>
          </div>
          <div class="flex gap-6">
            <div class="flex flex-col gap-3">
              <form-button
                type="submit"
                color-scheme="danger"
                variant="solid"
                size="large"
                icon="text-copy"
              >
                Copy
              </form-button>
              <label class="text-center uppercase text-ash-900">Solid</label>
            </div>
            <div class="flex flex-col gap-3">
              <form-button
                type="submit"
                color-scheme="danger"
                variant="outline"
                size="large"
                icon="text-copy"
              >
                Copy
              </form-button>
              <label class="text-center uppercase text-ash-900">Outlined</label>
            </div>
            <div class="flex flex-col gap-3">
              <form-button
                type="submit"
                color-scheme="danger"
                variant="ghost"
                size="large"
                icon="text-copy"
              >
                Copy
              </form-button>
              <label class="text-center uppercase text-ash-900">Ghost</label>
            </div>
          </div>
        </div>

        <h2 class="mt-4 text-lg font-medium text-ash-900">Icon only</h2>
        <div
          class="flex justify-start gap-6 p-4 border border-dashed border-ash-500 rounded-xl"
        >
          <div class="flex flex-col gap-3">
            <form-button
              type="submit"
              color-scheme="primary"
              variant="solid"
              size="large"
              icon="text-copy"
            >
              Copy
            </form-button>
            <label class="text-center uppercase text-ash-900">Default</label>
          </div>
          <div class="flex flex-col gap-3">
            <form-button
              type="submit"
              color-scheme="primary"
              variant="solid"
              size="large"
              icon="text-copy"
              icon-only
            >
              Copy
            </form-button>

            <label class="text-center uppercase text-ash-900">
              Icon only
            </label>
          </div>
        </div>

        <h2 class="mt-4 text-lg font-medium text-ash-900">Size</h2>
        <div
          class="flex justify-start gap-6 p-4 border border-dashed border-ash-500 rounded-xl"
        >
          <div class="flex flex-col gap-3">
            <form-button
              type="submit"
              color-scheme="primary"
              variant="solid"
              icon="text-copy"
              size="medium"
            >
              Copy
            </form-button>
            <label class="text-center uppercase text-ash-900">Medium</label>
          </div>

          <div class="flex flex-col gap-3">
            <form-button
              type="submit"
              color-scheme="primary"
              variant="solid"
              size="large"
              icon="text-copy"
            >
              Copy
            </form-button>
            <label class="text-center uppercase text-ash-900">Large</label>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import FormButton from 'v3/components/Form/Button.vue';

export default {
  components: {
    FormButton,
  },
};
</script>
