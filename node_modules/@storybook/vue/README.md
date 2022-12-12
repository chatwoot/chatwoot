# Storybook for Vue

Storybook for Vue is a UI development environment for your Vue components.
With it, you can visualize different states of your UI components and develop them interactively.

![Storybook Screenshot](https://github.com/storybookjs/storybook/blob/main/media/storybook-intro.gif)

Storybook runs outside of your app.
So you can develop UI components in isolation without worrying about app specific dependencies and requirements.

## Getting Started

```sh
cd my-vue-app
npx sb init
```

For more information visit: [storybook.js.org](https://storybook.js.org)

## Starter Storybook-for-Vue Boilerplate project with [Vuetify](https://github.com/vuetifyjs/vuetify) Material Component Framework

<https://github.com/white-rabbit-japan/vue-vuetify-storybook>

---

Storybook also comes with a lot of [addons](https://storybook.js.org/addons) and a great API to customize as you wish.
You can also build a [static version](https://storybook.js.org/docs/vue/sharing/publish-storybook) of your Storybook and deploy it anywhere you want.

## Vue Notes

- When using global custom components or extensions (e.g., `Vue.use`). You will need to declare those in the `./storybook/preview.js`.

## Known Limitations

In Storybook story and decorator components, you can not access the Vue instance
in factory functions for default prop values:

```js
{
  props: {
    foo: {
      default() {
        return this.bar; // does not work!
      }
    }
  }
}
```
