import global from 'global';
import { logger } from '@storybook/client-logger';
import AnsiToHtml from 'ansi-to-html';
import dedent from 'ts-dedent';
import qs from 'qs';
const {
  document
} = global;
const PREPARING_DELAY = 100;
const layoutClassMap = {
  centered: 'sb-main-centered',
  fullscreen: 'sb-main-fullscreen',
  padded: 'sb-main-padded'
};
var Mode;

(function (Mode) {
  Mode["MAIN"] = "MAIN";
  Mode["NOPREVIEW"] = "NOPREVIEW";
  Mode["PREPARING_STORY"] = "PREPARING_STORY";
  Mode["PREPARING_DOCS"] = "PREPARING_DOCS";
  Mode["ERROR"] = "ERROR";
})(Mode || (Mode = {}));

const classes = {
  PREPARING_STORY: 'sb-show-preparing-story',
  PREPARING_DOCS: 'sb-show-preparing-docs',
  MAIN: 'sb-show-main',
  NOPREVIEW: 'sb-show-nopreview',
  ERROR: 'sb-show-errordisplay'
};
const ansiConverter = new AnsiToHtml({
  escapeXML: true
});
export class WebView {
  constructor() {
    this.currentLayoutClass = void 0;
    this.testing = false;
    this.preparingTimeout = null;
    // Special code for testing situations
    const {
      __SPECIAL_TEST_PARAMETER__
    } = qs.parse(document.location.search, {
      ignoreQueryPrefix: true
    });

    switch (__SPECIAL_TEST_PARAMETER__) {
      case 'preparing-story':
        {
          this.showPreparingStory();
          this.testing = true;
          break;
        }

      case 'preparing-docs':
        {
          this.showPreparingDocs();
          this.testing = true;
          break;
        }

      default: // pass;

    }
  } // Get ready to render a story, returning the element to render to


  prepareForStory(story) {
    this.showStory();
    this.applyLayout(story.parameters.layout);
    document.documentElement.scrollTop = 0;
    document.documentElement.scrollLeft = 0;
    return this.storyRoot();
  }

  storyRoot() {
    return document.getElementById('root');
  }

  prepareForDocs() {
    this.showMain();
    this.showDocs();
    this.applyLayout('fullscreen');
    return this.docsRoot();
  }

  docsRoot() {
    return document.getElementById('docs-root');
  }

  applyLayout(layout = 'padded') {
    if (layout === 'none') {
      document.body.classList.remove(this.currentLayoutClass);
      this.currentLayoutClass = null;
      return;
    }

    this.checkIfLayoutExists(layout);
    const layoutClass = layoutClassMap[layout];
    document.body.classList.remove(this.currentLayoutClass);
    document.body.classList.add(layoutClass);
    this.currentLayoutClass = layoutClass;
  }

  checkIfLayoutExists(layout) {
    if (!layoutClassMap[layout]) {
      logger.warn(dedent`The desired layout: ${layout} is not a valid option.
         The possible options are: ${Object.keys(layoutClassMap).join(', ')}, none.`);
    }
  }

  showMode(mode) {
    clearTimeout(this.preparingTimeout);
    Object.keys(Mode).forEach(otherMode => {
      if (otherMode === mode) {
        document.body.classList.add(classes[otherMode]);
      } else {
        document.body.classList.remove(classes[otherMode]);
      }
    });
  }

  showErrorDisplay({
    message = '',
    stack = ''
  }) {
    let header = message;
    let detail = stack;
    const parts = message.split('\n');

    if (parts.length > 1) {
      [header] = parts;
      detail = parts.slice(1).join('\n');
    }

    document.getElementById('error-message').innerHTML = ansiConverter.toHtml(header);
    document.getElementById('error-stack').innerHTML = ansiConverter.toHtml(detail);
    this.showMode(Mode.ERROR);
  }

  showNoPreview() {
    var _this$storyRoot, _this$docsRoot;

    if (this.testing) return;
    this.showMode(Mode.NOPREVIEW); // In storyshots this can get called and these two can be null

    (_this$storyRoot = this.storyRoot()) === null || _this$storyRoot === void 0 ? void 0 : _this$storyRoot.setAttribute('hidden', 'true');
    (_this$docsRoot = this.docsRoot()) === null || _this$docsRoot === void 0 ? void 0 : _this$docsRoot.setAttribute('hidden', 'true');
  }

  showPreparingStory({
    immediate = false
  } = {}) {
    clearTimeout(this.preparingTimeout);

    if (immediate) {
      this.showMode(Mode.PREPARING_STORY);
    } else {
      this.preparingTimeout = setTimeout(() => this.showMode(Mode.PREPARING_STORY), PREPARING_DELAY);
    }
  }

  showPreparingDocs() {
    clearTimeout(this.preparingTimeout);
    this.preparingTimeout = setTimeout(() => this.showMode(Mode.PREPARING_DOCS), PREPARING_DELAY);
  }

  showMain() {
    this.showMode(Mode.MAIN);
  }

  showDocs() {
    this.storyRoot().setAttribute('hidden', 'true');
    this.docsRoot().removeAttribute('hidden');
  }

  showStory() {
    this.docsRoot().setAttribute('hidden', 'true');
    this.storyRoot().removeAttribute('hidden');
  }

  showStoryDuringRender() {
    // When 'showStory' is called (at the start of rendering) we get rid of our display:none
    // from all children of the root (but keep the preparing spinner visible). This may mean
    // that very weird and high z-index stories are briefly visible.
    // See https://github.com/storybookjs/storybook/issues/16847 and
    //   http://localhost:9011/?path=/story/core-rendering--auto-focus (official SB)
    document.body.classList.add(classes.MAIN);
  }

}