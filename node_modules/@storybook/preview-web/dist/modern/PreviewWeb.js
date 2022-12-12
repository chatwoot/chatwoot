import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import global from 'global';
import { CURRENT_STORY_WAS_SET, IGNORED_EXCEPTION, PRELOAD_STORIES, PREVIEW_KEYDOWN, SET_CURRENT_STORY, SET_STORIES, STORY_ARGS_UPDATED, STORY_CHANGED, STORY_ERRORED, STORY_MISSING, STORY_PREPARED, STORY_RENDER_PHASE_CHANGED, STORY_SPECIFIED, STORY_THREW_EXCEPTION, STORY_UNCHANGED, UPDATE_QUERY_PARAMS } from '@storybook/core-events';
import { logger } from '@storybook/client-logger';
import { Preview } from './Preview';
import { UrlStore } from './UrlStore';
import { WebView } from './WebView';
import { PREPARE_ABORTED, StoryRender } from './StoryRender';
import { DocsRender } from './DocsRender';
const {
  window: globalWindow
} = global;

function focusInInput(event) {
  const target = event.target;
  return /input|textarea/i.test(target.tagName) || target.getAttribute('contenteditable') !== null;
}

export class PreviewWeb extends Preview {
  constructor() {
    super();
    this.urlStore = void 0;
    this.view = void 0;
    this.previewEntryError = void 0;
    this.currentSelection = void 0;
    this.currentRender = void 0;
    this.view = new WebView();
    this.urlStore = new UrlStore(); // Add deprecated APIs for back-compat
    // @ts-ignore

    this.storyStore.getSelection = deprecate(() => this.urlStore.selection, dedent`
        \`__STORYBOOK_STORY_STORE__.getSelection()\` is deprecated and will be removed in 7.0.
  
        To get the current selection, use the \`useStoryContext()\` hook from \`@storybook/addons\`.
      `);
  }

  setupListeners() {
    super.setupListeners();
    globalWindow.onkeydown = this.onKeydown.bind(this);
    this.channel.on(SET_CURRENT_STORY, this.onSetCurrentStory.bind(this));
    this.channel.on(UPDATE_QUERY_PARAMS, this.onUpdateQueryParams.bind(this));
    this.channel.on(PRELOAD_STORIES, this.onPreloadStories.bind(this));
  }

  initializeWithProjectAnnotations(projectAnnotations) {
    return super.initializeWithProjectAnnotations(projectAnnotations).then(() => this.setInitialGlobals());
  }

  async setInitialGlobals() {
    const {
      globals
    } = this.urlStore.selectionSpecifier || {};

    if (globals) {
      this.storyStore.globals.updateFromPersisted(globals);
    }

    this.emitGlobals();
  } // If initialization gets as far as the story index, this function runs.


  initializeWithStoryIndex(storyIndex) {
    return super.initializeWithStoryIndex(storyIndex).then(() => {
      var _global$FEATURES;

      if (!((_global$FEATURES = global.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.storyStoreV7)) {
        this.channel.emit(SET_STORIES, this.storyStore.getSetStoriesPayload());
      }

      return this.selectSpecifiedStory();
    });
  } // Use the selection specifier to choose a story, then render it


  async selectSpecifiedStory() {
    if (!this.urlStore.selectionSpecifier) {
      this.renderMissingStory();
      return;
    }

    const {
      storySpecifier,
      viewMode,
      args
    } = this.urlStore.selectionSpecifier;
    const storyId = this.storyStore.storyIndex.storyIdFromSpecifier(storySpecifier);

    if (!storyId) {
      if (storySpecifier === '*') {
        this.renderStoryLoadingException(storySpecifier, new Error(dedent`
            Couldn't find any stories in your Storybook.
            - Please check your stories field of your main.js config.
            - Also check the browser console and terminal for error messages.
          `));
      } else {
        this.renderStoryLoadingException(storySpecifier, new Error(dedent`
            Couldn't find story matching '${storySpecifier}'.
            - Are you sure a story with that id exists?
            - Please check your stories field of your main.js config.
            - Also check the browser console and terminal for error messages.
          `));
      }

      return;
    }

    this.urlStore.setSelection({
      storyId,
      viewMode
    });
    this.channel.emit(STORY_SPECIFIED, this.urlStore.selection);
    this.channel.emit(CURRENT_STORY_WAS_SET, this.urlStore.selection);
    await this.renderSelection({
      persistedArgs: args
    });
  } // EVENT HANDLERS
  // This happens when a config file gets reloaded


  async onGetProjectAnnotationsChanged({
    getProjectAnnotations
  }) {
    await super.onGetProjectAnnotationsChanged({
      getProjectAnnotations
    });
    this.renderSelection();
  } // This happens when a glob gets HMR-ed


  async onStoriesChanged({
    importFn,
    storyIndex
  }) {
    var _global$FEATURES2;

    super.onStoriesChanged({
      importFn,
      storyIndex
    });

    if (!((_global$FEATURES2 = global.FEATURES) !== null && _global$FEATURES2 !== void 0 && _global$FEATURES2.storyStoreV7)) {
      this.channel.emit(SET_STORIES, await this.storyStore.getSetStoriesPayload());
    }

    if (this.urlStore.selection) {
      await this.renderSelection();
    } else {
      // Our selection has never applied before, but maybe it does now, let's try!
      await this.selectSpecifiedStory();
    }
  }

  onKeydown(event) {
    var _this$currentRender;

    if (!((_this$currentRender = this.currentRender) !== null && _this$currentRender !== void 0 && _this$currentRender.disableKeyListeners) && !focusInInput(event)) {
      // We have to pick off the keys of the event that we need on the other side
      const {
        altKey,
        ctrlKey,
        metaKey,
        shiftKey,
        key,
        code,
        keyCode
      } = event;
      this.channel.emit(PREVIEW_KEYDOWN, {
        event: {
          altKey,
          ctrlKey,
          metaKey,
          shiftKey,
          key,
          code,
          keyCode
        }
      });
    }
  }

  onSetCurrentStory(selection) {
    this.urlStore.setSelection(Object.assign({
      viewMode: 'story'
    }, selection));
    this.channel.emit(CURRENT_STORY_WAS_SET, this.urlStore.selection);
    this.renderSelection();
  }

  onUpdateQueryParams(queryParams) {
    this.urlStore.setQueryParams(queryParams);
  }

  async onUpdateGlobals({
    globals
  }) {
    super.onUpdateGlobals({
      globals
    });
    if (this.currentRender instanceof DocsRender) await this.currentRender.rerender();
  }

  async onUpdateArgs({
    storyId,
    updatedArgs
  }) {
    super.onUpdateArgs({
      storyId,
      updatedArgs
    }); // NOTE: we aren't checking to see the story args are targetted at the "right" story.
    // This is because we may render >1 story on the page and there is no easy way to keep track
    // of which ones were rendered by the docs page.
    // However, in `modernInlineRender`, the individual stories track their own events as they
    // each call `renderStoryToElement` below.

    if (this.currentRender instanceof DocsRender) await this.currentRender.rerender();
  }

  async onPreloadStories(ids) {
    await Promise.all(ids.map(id => this.storyStore.loadStory({
      storyId: id
    })));
  } // RENDERING
  // We can either have:
  // - a story selected in "story" viewMode,
  //     in which case we render it to the root element, OR
  // - a story selected in "docs" viewMode,
  //     in which case we render the docsPage for that story


  async renderSelection({
    persistedArgs
  } = {}) {
    var _this$currentSelectio, _this$currentSelectio2, _lastRender, _global$FEATURES3;

    const {
      selection
    } = this.urlStore;

    if (!selection) {
      throw new Error('Cannot render story as no selection was made');
    }

    const {
      storyId
    } = selection;
    const storyIdChanged = ((_this$currentSelectio = this.currentSelection) === null || _this$currentSelectio === void 0 ? void 0 : _this$currentSelectio.storyId) !== storyId;
    const viewModeChanged = ((_this$currentSelectio2 = this.currentSelection) === null || _this$currentSelectio2 === void 0 ? void 0 : _this$currentSelectio2.viewMode) !== selection.viewMode; // Show a spinner while we load the next story

    if (selection.viewMode === 'story') {
      this.view.showPreparingStory({
        immediate: viewModeChanged
      });
    } else {
      this.view.showPreparingDocs();
    }

    const lastSelection = this.currentSelection;
    let lastRender = this.currentRender; // If the last render is still preparing, let's drop it right now. Either
    //   (a) it is a different story, which means we would drop it later, OR
    //   (b) it is the *same* story, in which case we will resolve our own .prepare() at the
    //       same moment anyway, and we should just "take over" the rendering.
    // (We can't tell which it is yet, because it is possible that an HMR is going on and
    //  even though the storyId is the same, the story itself is not).

    if ((_lastRender = lastRender) !== null && _lastRender !== void 0 && _lastRender.isPreparing()) {
      await this.teardownRender(lastRender);
      lastRender = null;
    }

    const storyRender = new StoryRender(this.channel, this.storyStore, (...args) => {
      // At the start of renderToDOM we make the story visible (see note in WebView)
      this.view.showStoryDuringRender();
      return this.renderToDOM(...args);
    }, this.mainStoryCallbacks(storyId), storyId, 'story'); // We need to store this right away, so if the story changes during
    // the async `.prepare()` below, we can (potentially) cancel it

    this.currentSelection = selection; // Note this may be replaced by a docsRender after preparing

    this.currentRender = storyRender;

    try {
      await storyRender.prepare();
    } catch (err) {
      if (err !== PREPARE_ABORTED) {
        // We are about to render an error so make sure the previous story is
        // no longer rendered.
        await this.teardownRender(lastRender);
        this.renderStoryLoadingException(storyId, err);
      }

      return;
    }

    const implementationChanged = !storyIdChanged && !storyRender.isEqual(lastRender);
    if (persistedArgs) this.storyStore.args.updateFromPersisted(storyRender.story, persistedArgs);
    const {
      parameters,
      initialArgs,
      argTypes,
      args
    } = storyRender.context(); // Don't re-render the story if nothing has changed to justify it

    if (lastRender && !storyIdChanged && !implementationChanged && !viewModeChanged) {
      this.currentRender = lastRender;
      this.channel.emit(STORY_UNCHANGED, storyId);
      this.view.showMain();
      return;
    } // Wait for the previous render to leave the page. NOTE: this will wait to ensure anything async
    // is properly aborted, which (in some cases) can lead to the whole screen being refreshed.


    await this.teardownRender(lastRender, {
      viewModeChanged
    }); // If we are rendering something new (as opposed to re-rendering the same or first story), emit

    if (lastSelection && (storyIdChanged || viewModeChanged)) {
      this.channel.emit(STORY_CHANGED, storyId);
    }

    if ((_global$FEATURES3 = global.FEATURES) !== null && _global$FEATURES3 !== void 0 && _global$FEATURES3.storyStoreV7) {
      this.channel.emit(STORY_PREPARED, {
        id: storyId,
        parameters,
        initialArgs,
        argTypes,
        args
      });
    } // For v6 mode / compatibility
    // If the implementation changed, or args were persisted, the args may have changed,
    // and the STORY_PREPARED event above may not be respected.


    if (implementationChanged || persistedArgs) {
      this.channel.emit(STORY_ARGS_UPDATED, {
        storyId,
        args
      });
    }

    if (selection.viewMode === 'docs' || parameters.docsOnly) {
      this.currentRender = DocsRender.fromStoryRender(storyRender);
      this.currentRender.renderToElement(this.view.prepareForDocs(), this.renderStoryToElement.bind(this));
    } else {
      this.storyRenders.push(storyRender);
      this.currentRender.renderToElement(this.view.prepareForStory(storyRender.story));
    }
  } // Used by docs' modernInlineRender to render a story to a given element
  // Note this short-circuits the `prepare()` phase of the StoryRender,
  // main to be consistent with the previous behaviour. In the future,
  // we will change it to go ahead and load the story, which will end up being
  // "instant", although async.


  renderStoryToElement(story, element) {
    const render = new StoryRender(this.channel, this.storyStore, this.renderToDOM, this.inlineStoryCallbacks(story.id), story.id, 'docs', story);
    render.renderToElement(element);
    this.storyRenders.push(render);
    return async () => {
      await this.teardownRender(render);
    };
  }

  async teardownRender(render, {
    viewModeChanged
  } = {}) {
    this.storyRenders = this.storyRenders.filter(r => r !== render);
    await (render === null || render === void 0 ? void 0 : render.teardown({
      viewModeChanged
    }));
  } // API


  async extract(options) {
    var _global$FEATURES4;

    if (this.previewEntryError) {
      throw this.previewEntryError;
    }

    if (!this.storyStore.projectAnnotations) {
      // In v6 mode, if your preview.js throws, we never get a chance to initialize the preview
      // or store, and the error is simply logged to the browser console. This is the best we can do
      throw new Error(dedent`Failed to initialize Storybook.
      
      Do you have an error in your \`preview.js\`? Check your Storybook's browser console for errors.`);
    }

    if ((_global$FEATURES4 = global.FEATURES) !== null && _global$FEATURES4 !== void 0 && _global$FEATURES4.storyStoreV7) {
      await this.storyStore.cacheAllCSFFiles();
    }

    return this.storyStore.extract(options);
  } // UTILITIES


  mainStoryCallbacks(storyId) {
    return {
      showMain: () => this.view.showMain(),
      showError: err => this.renderError(storyId, err),
      showException: err => this.renderException(storyId, err)
    };
  }

  inlineStoryCallbacks(storyId) {
    return {
      showMain: () => {},
      showError: err => logger.error(`Error rendering docs story (${storyId})`, err),
      showException: err => logger.error(`Error rendering docs story (${storyId})`, err)
    };
  }

  renderPreviewEntryError(reason, err) {
    super.renderPreviewEntryError(reason, err);
    this.view.showErrorDisplay(err);
  }

  renderMissingStory() {
    this.view.showNoPreview();
    this.channel.emit(STORY_MISSING);
  }

  renderStoryLoadingException(storySpecifier, err) {
    logger.error(`Unable to load story '${storySpecifier}':`);
    logger.error(err);
    this.view.showErrorDisplay(err);
    this.channel.emit(STORY_MISSING, storySpecifier);
  } // renderException is used if we fail to render the story and it is uncaught by the app layer


  renderException(storyId, err) {
    this.channel.emit(STORY_THREW_EXCEPTION, err);
    this.channel.emit(STORY_RENDER_PHASE_CHANGED, {
      newPhase: 'errored',
      storyId
    }); // Ignored exceptions exist for control flow purposes, and are typically handled elsewhere.

    if (err !== IGNORED_EXCEPTION) {
      this.view.showErrorDisplay(err);
      logger.error(`Error rendering story '${storyId}':`);
      logger.error(err);
    }
  } // renderError is used by the various app layers to inform the user they have done something
  // wrong -- for instance returned the wrong thing from a story


  renderError(storyId, {
    title,
    description
  }) {
    logger.error(`Error rendering story ${title}: ${description}`);
    this.channel.emit(STORY_ERRORED, {
      title,
      description
    });
    this.channel.emit(STORY_RENDER_PHASE_CHANGED, {
      newPhase: 'errored',
      storyId
    });
    this.view.showErrorDisplay({
      message: title,
      stack: description
    });
  }

}