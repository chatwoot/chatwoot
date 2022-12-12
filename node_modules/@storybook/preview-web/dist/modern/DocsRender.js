import global from 'global';
import { DOCS_RENDERED } from '@storybook/core-events';
export class DocsRender {
  static fromStoryRender(storyRender) {
    const {
      channel,
      store,
      id,
      story
    } = storyRender;
    return new DocsRender(channel, store, id, story);
  } // eslint-disable-next-line no-useless-constructor


  constructor(channel, store, id, story) {
    this.channel = channel;
    this.store = store;
    this.id = id;
    this.story = story;
    this.canvasElement = void 0;
    this.context = void 0;
    this.disableKeyListeners = false;
  } // DocsRender doesn't prepare, it is created *from* a prepared StoryRender


  isPreparing() {
    return false;
  }

  async renderToElement(canvasElement, renderStoryToElement) {
    var _global$FEATURES;

    this.canvasElement = canvasElement;
    const {
      id,
      title,
      name
    } = this.story;
    const csfFile = await this.store.loadCSFFileByStoryId(this.id);
    this.context = Object.assign({
      id,
      title,
      name,
      // NOTE: these two functions are *sync* so cannot access stories from other CSF files
      storyById: storyId => this.store.storyFromCSFFile({
        storyId,
        csfFile
      }),
      componentStories: () => this.store.componentStoriesFromCSFFile({
        csfFile
      }),
      loadStory: storyId => this.store.loadStory({
        storyId
      }),
      renderStoryToElement,
      getStoryContext: renderedStory => Object.assign({}, this.store.getStoryContext(renderedStory), {
        viewMode: 'docs'
      })
    }, !((_global$FEATURES = global.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.breakingChangesV7) && this.store.getStoryContext(this.story));
    return this.render();
  }

  async render() {
    if (!this.story || !this.context || !this.canvasElement) throw new Error('DocsRender not ready to render');
    const renderer = await import('./renderDocs');
    renderer.renderDocs(this.story, this.context, this.canvasElement, () => this.channel.emit(DOCS_RENDERED, this.id));
  }

  async rerender() {
    var _global$FEATURES2;

    // NOTE: in modern inline render mode, each story is rendered via
    // `preview.renderStoryToElement` which means the story will track
    // its own re-renders. Thus there will be no need to re-render the whole
    // docs page when a single story changes.
    if (!((_global$FEATURES2 = global.FEATURES) !== null && _global$FEATURES2 !== void 0 && _global$FEATURES2.modernInlineRender)) await this.render();
  }

  async teardown({
    viewModeChanged
  } = {}) {
    if (!viewModeChanged || !this.canvasElement) return;
    const renderer = await import('./renderDocs');
    renderer.unmountDocs(this.canvasElement);
  }

}
DocsRender.displayName = "DocsRender";