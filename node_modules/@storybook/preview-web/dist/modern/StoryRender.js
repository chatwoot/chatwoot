import global from 'global';
import { STORY_RENDER_PHASE_CHANGED, STORY_RENDERED } from '@storybook/core-events';
const {
  AbortController
} = global;

function createController() {
  if (AbortController) return new AbortController(); // Polyfill for IE11

  return {
    signal: {
      aborted: false
    },

    abort() {
      this.signal.aborted = true;
    }

  };
}

export const PREPARE_ABORTED = new Error('prepareAborted');
export class StoryRender {
  constructor(channel, store, renderToScreen, callbacks, id, viewMode, story) {
    this.channel = channel;
    this.store = store;
    this.renderToScreen = renderToScreen;
    this.callbacks = callbacks;
    this.id = id;
    this.viewMode = viewMode;
    this.story = void 0;
    this.phase = void 0;
    this.abortController = void 0;
    this.canvasElement = void 0;
    this.notYetRendered = true;
    this.disableKeyListeners = false;
    this.abortController = createController(); // Allow short-circuiting preparing if we happen to already
    // have the story (this is used by docs mode)

    if (story) {
      this.story = story; // TODO -- what should the phase be now?
      // TODO -- should we emit the render phase changed event?

      this.phase = 'preparing';
    }
  }

  async runPhase(signal, phase, phaseFn) {
    this.phase = phase;
    this.channel.emit(STORY_RENDER_PHASE_CHANGED, {
      newPhase: this.phase,
      storyId: this.id
    });
    if (phaseFn) await phaseFn();

    if (signal.aborted) {
      this.phase = 'aborted';
      this.channel.emit(STORY_RENDER_PHASE_CHANGED, {
        newPhase: this.phase,
        storyId: this.id
      });
    }
  }

  async prepare() {
    await this.runPhase(this.abortController.signal, 'preparing', async () => {
      this.story = await this.store.loadStory({
        storyId: this.id
      });
    });

    if (this.abortController.signal.aborted) {
      this.store.cleanupStory(this.story);
      throw PREPARE_ABORTED;
    }
  } // The two story "renders" are equal and have both loaded the same story


  isEqual(other) {
    return other && this.id === other.id && this.story && this.story === other.story;
  }

  isPreparing() {
    return ['preparing'].includes(this.phase);
  }

  isPending() {
    return ['rendering', 'playing'].includes(this.phase);
  }

  context() {
    return this.store.getStoryContext(this.story);
  }

  async renderToElement(canvasElement) {
    this.canvasElement = canvasElement; // FIXME: this comment
    // Start the first (initial) render. We don't await here because we need to return the "cleanup"
    // function below right away, so if the user changes story during the first render we can cancel
    // it without having to first wait for it to finish.
    // Whenever the selection changes we want to force the component to be remounted.

    return this.render({
      initial: true,
      forceRemount: true
    });
  }

  async render({
    initial = false,
    forceRemount = false
  } = {}) {
    if (!this.story) throw new Error('cannot render when not prepared');
    const {
      id,
      componentId,
      title,
      name,
      applyLoaders,
      unboundStoryFn,
      playFunction
    } = this.story;

    if (forceRemount && !initial) {
      // NOTE: we don't check the cancel actually worked here, so the previous
      // render could conceivably still be running after this call.
      // We might want to change that in the future.
      this.cancelRender();
      this.abortController = createController();
    } // We need a stable reference to the signal -- if a re-mount happens the
    // abort controller may be torn down (above) before we actually check the signal.


    const abortSignal = this.abortController.signal;

    try {
      let loadedContext;
      await this.runPhase(abortSignal, 'loading', async () => {
        loadedContext = await applyLoaders(Object.assign({}, this.context(), {
          viewMode: this.viewMode
        }));
      });
      if (abortSignal.aborted) return;
      const renderStoryContext = Object.assign({}, loadedContext, this.context(), {
        abortSignal,
        canvasElement: this.canvasElement
      });
      const renderContext = Object.assign({
        componentId,
        title,
        kind: title,
        id,
        name,
        story: name
      }, this.callbacks, {
        forceRemount: forceRemount || this.notYetRendered,
        storyContext: renderStoryContext,
        storyFn: () => unboundStoryFn(renderStoryContext),
        unboundStoryFn
      });
      await this.runPhase(abortSignal, 'rendering', async () => this.renderToScreen(renderContext, this.canvasElement));
      this.notYetRendered = false;
      if (abortSignal.aborted) return;

      if (forceRemount && playFunction) {
        this.disableKeyListeners = true;
        await this.runPhase(abortSignal, 'playing', async () => playFunction(renderContext.storyContext));
        await this.runPhase(abortSignal, 'played');
        this.disableKeyListeners = false;
        if (abortSignal.aborted) return;
      }

      await this.runPhase(abortSignal, 'completed', async () => this.channel.emit(STORY_RENDERED, id));
    } catch (err) {
      this.callbacks.showException(err);
    }
  }

  async rerender() {
    return this.render();
  }

  async remount() {
    return this.render({
      forceRemount: true
    });
  } // If the story is torn down (either a new story is rendered or the docs page removes it)
  // we need to consider the fact that the initial render may not be finished
  // (possibly the loaders or the play function are still running). We use the controller
  // as a method to abort them, ASAP, but this is not foolproof as we cannot control what
  // happens inside the user's code.


  cancelRender() {
    this.abortController.abort();
  }

  async teardown(options = {}) {
    this.cancelRender(); // If the story has loaded, we need to cleanup

    if (this.story) this.store.cleanupStory(this.story); // Check if we're done rendering/playing. If not, we may have to reload the page.
    // Wait several ticks that may be needed to handle the abort, then try again.
    // Note that there's a max of 5 nested timeouts before they're no longer "instant".

    for (let i = 0; i < 3; i += 1) {
      if (!this.isPending()) return; // eslint-disable-next-line no-await-in-loop

      await new Promise(resolve => setTimeout(resolve, 0));
    } // If we still haven't completed, reload the page (iframe) to ensure we have a clean slate
    // for the next render. Since the reload can take a brief moment to happen, we want to stop
    // further rendering by awaiting a never-resolving promise (which is destroyed on reload).


    global.window.location.reload();
    await new Promise(() => {});
  }

}
StoryRender.displayName = "StoryRender";