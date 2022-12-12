# Vue.js hCaptcha Component Library

hCaptcha Component Library for Vue.js. Compatible with Vue 2 and 3.

## Installation
You can install this library via npm with:
* vue2: `npm install @hcaptcha/vue-hcaptcha --save`
* vue3: `npm install @hcaptcha/vue3-hcaptcha --save`

or via yarn:
* vue2: `yarn add @hcaptcha/vue-hcaptcha`
* vue3: `yarn add @hcaptcha/vue3-hcaptcha`

or via script tag (`Vue` must be globally available)
* vue2
   ```
   <script src="https://unpkg.com/vue"></script>
   <script src="https://unpkg.com/@hcaptcha/vue-hcaptcha"></script>
   ```
* vue3
   ```
   <script src="https://unpkg.com/vue@next"></script>
   <script src="https://unpkg.com/@hcaptcha/vue3-hcaptcha"></script>
   ```
  
#### Basic Usage
* vue2:
   ```
   <template>
       <vue-hcaptcha sitekey="**Your sitekey here**"></vue-hcaptcha>
   </template>
   
   <script>
     import VueHcaptcha from '@hcaptcha/vue-hcaptcha';
     export default {
       ...
       components: { VueHcaptcha }
     };
   </script>
   ```
  
* vue3:
   ```
   <template>
       <vue-hcaptcha sitekey="**Your sitekey here**"></vue-hcaptcha>
   </template>
   
   <script setup>
     import VueHcaptcha from '@hcaptcha/vue-hcaptcha';
   </script>
   ```

The component will automatically load the hCaptcha API library and append it to the root component.


### JS API

#### Props

|Name|Values/Type|Required|Default|Description|
|---|---|---|---|---|
|`sitekey`|String|**Yes**|`-`|Your sitekey. Please visit [hCaptcha](https://www.hcaptcha.com) and sign up to get a sitekey.|
|`size`|String (normal, compact, invisible)|No|`normal`|This specifies the "size" of the checkbox. hCaptcha allows you to decide how big the component will appear on render. Defaults to normal.|
|`theme`|String (light, dark)|No|`light`|hCaptcha supports both a light and dark theme. If no theme is set, the API will default to light.|
|`tabindex`|Integer|No|`0`|Set the tabindex of the widget and popup. When appropriate, this can make navigation of your site more intuitive.|
|`language`|String (ISO 639-2 code)|No|`auto`|hCaptcha auto-detects language via the user's browser. This overrides that to set a default UI language.|
|`reCaptchaCompat`|Boolean|No|`true`|Disable drop-in replacement for reCAPTCHA with `false` to prevent hCaptcha from injecting into window.grecaptcha.|
|`challengeContainer`|String|No|`-`|A custom element ID to render the hCaptcha challenge.|
|`rqdata`|String|No|-|See Enterprise docs.|
|`sentry`|Boolean|No|-|See Enterprise docs.|
|`apiEndpoint`|String|No|-|See Enterprise docs.|
|`endpoint`|String|No|-|See Enterprise docs.|
|`reportapi`|String|No|-|See Enterprise docs.|
|`assethost`|String|No|-|See Enterprise docs.|
|`imghost`|String|No|-|See Enterprise docs.|


#### Callback Events

|Event|Params|Description|
|---|---|---|
|`error`|`err`|When an error occurs. Component will reset immediately after an error.|
|`verify`|`token, eKey`|When challenge is completed. The `token` and an `eKey` are passed along.|
|`expired`|-|When the current token expires.|
|`challengeExpired`|-|When the unfinished challenge expires.|
|`opened`|-|When the challenge is opened.|
|`closed`|-|When the challenge is closed.|
|`reset`|-|When the challenge is reset.|
|`rendered`|-|When the challenge is rendered.|
|`executed`|-|When the challenge is executed.|

### Methods

|Method|Description|
|---|---|
|`execute()`|Programmatically trigger a challenge request|
|`reset()`|Reset the current challenge|

### FAQ

#### How can I get a sitekey?

Sign up at [hCaptcha](https://www.hcaptcha.com) to get your sitekey. Check [documentation](https://docs.hcaptcha.com/api#getapikey) for more information.

#### What is hCaptcha?

[hCaptcha](https://www.hcaptcha.com) is a drop-in replacement for reCAPTCHA that earns websites money and helps companies get their data labeled.

#### Are features like bot scores and No-CAPTCHA/passive mode also available?

Yes, in the enterprise version: see [hCaptcha Enterprise (BotStop)](https://www.botstop.com) for details.

### Demo

![Demo](https://raw.githubusercontent.com/hCaptcha/vue-hcaptcha/master/screenshots/demo.gif)

To run the demo:
1. clone this repo `git clone https://github.com/hCaptcha/vue-hcaptcha.git`
2. ```cd examples/traditional-vue2``` 
3. ```yarn && yarn serve``` 
   * it will start the demo app on localhost:8080
   * open your console to see the demo app emitting events

### TypeScript

TypeScript is supported (`types/index.d.ts`), and you can see an example by running `npm run serve:ts`.


### Notes for developers

#### Scripts

* `yarn lint` - will check for lint issues
* `yarn test` - will test both vue2 and vue3 packages
* `yarn build` - will build the production vue2,3 versions

### Notes for maintainers

#### Publishing

To publish a new version, follow the next steps:
1. Bump the version of the updated package: `vue2/package.json` or `vue3/package.json`
2. Push changes to master.
   * CI/CD pipeline will publish the new version(s) to: [@hcaptcha/vue-hcaptcha](https://www.npmjs.com/package/@hcaptcha/vue-hcaptcha) or [@hcaptcha/vue3-hcaptcha](https://www.npmjs.com/package/@hcaptcha/vue3-hcaptcha).

### Contributing + Notable Contributors

`vue-hcaptcha` is developed and maintained through the collective efforts of the hCaptcha community.

This includes developers like you! We welcome your issues, suggestions, and PRs.

Notable contributors for larger changes:

- Vue2 support: hCaptcha team
- Vue3 support: JDinABox and DSergiu
