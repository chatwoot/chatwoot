import WebAudio from './webaudio';
import * as util from './util';

/**
 * MediaElement backend
 */
export default class MediaElement extends WebAudio {
    /**
     * Construct the backend
     *
     * @param {WavesurferParams} params Wavesurfer parameters
     */
    constructor(params) {
        super(params);
        /** @private */
        this.params = params;

        /**
         * Initially a dummy media element to catch errors. Once `_load` is
         * called, this will contain the actual `HTMLMediaElement`.
         * @private
         */
        this.media = {
            currentTime: 0,
            duration: 0,
            paused: true,
            playbackRate: 1,
            play() {},
            pause() {},
            volume: 0
        };

        /** @private */
        this.mediaType = params.mediaType.toLowerCase();
        /** @private */
        this.elementPosition = params.elementPosition;
        /** @private */
        this.peaks = null;
        /** @private */
        this.playbackRate = 1;
        /** @private */
        this.volume = 1;
        /** @private */
        this.isMuted = false;
        /** @private */
        this.buffer = null;
        /** @private */
        this.onPlayEnd = null;
        /** @private */
        this.mediaListeners = {};
    }

    /**
     * Initialise the backend, called in `wavesurfer.createBackend()`
     */
    init() {
        this.setPlaybackRate(this.params.audioRate);
        this.createTimer();
    }

    /**
     * Attach event listeners to media element.
     */
    _setupMediaListeners() {
        this.mediaListeners.error = () => {
            this.fireEvent('error', 'Error loading media element');
        };
        this.mediaListeners.canplay = () => {
            this.fireEvent('canplay');
        };
        this.mediaListeners.ended = () => {
            this.fireEvent('finish');
        };
        // listen to and relay play, pause and seeked events to enable
        // playback control from the external media element
        this.mediaListeners.play = () => {
            this.fireEvent('play');
        };
        this.mediaListeners.pause = () => {
            this.fireEvent('pause');
        };
        this.mediaListeners.seeked = event => {
            this.fireEvent('seek');
        };
        this.mediaListeners.volumechange = event => {
            this.isMuted = this.media.muted;
            if (this.isMuted) {
                this.volume = 0;
            } else {
                this.volume = this.media.volume;
            }
            this.fireEvent('volume');
        };

        // reset event listeners
        Object.keys(this.mediaListeners).forEach(id => {
            this.media.removeEventListener(id, this.mediaListeners[id]);
            this.media.addEventListener(id, this.mediaListeners[id]);
        });
    }

    /**
     * Create a timer to provide a more precise `audioprocess` event.
     */
    createTimer() {
        const onAudioProcess = () => {
            if (this.isPaused()) {
                return;
            }
            this.fireEvent('audioprocess', this.getCurrentTime());

            // Call again in the next frame
            util.frame(onAudioProcess)();
        };

        this.on('play', onAudioProcess);

        // Update the progress one more time to prevent it from being stuck in
        // case of lower framerates
        this.on('pause', () => {
            this.fireEvent('audioprocess', this.getCurrentTime());
        });
    }

    /**
     * Create media element with url as its source,
     * and append to container element.
     *
     * @param {string} url Path to media file
     * @param {HTMLElement} container HTML element
     * @param {number[]|Number.<Array[]>} peaks Array of peak data
     * @param {string} preload HTML 5 preload attribute value
     * @throws Will throw an error if the `url` argument is not a valid media
     * element.
     */
    load(url, container, peaks, preload) {
        const media = document.createElement(this.mediaType);
        media.controls = this.params.mediaControls;
        media.autoplay = this.params.autoplay || false;
        media.preload = preload == null ? 'auto' : preload;
        media.src = url;
        media.style.width = '100%';

        const prevMedia = container.querySelector(this.mediaType);
        if (prevMedia) {
            container.removeChild(prevMedia);
        }
        container.appendChild(media);

        this._load(media, peaks, preload);
    }

    /**
     * Load existing media element.
     *
     * @param {HTMLMediaElement} elt HTML5 Audio or Video element
     * @param {number[]|Number.<Array[]>} peaks Array of peak data
     */
    loadElt(elt, peaks) {
        elt.controls = this.params.mediaControls;
        elt.autoplay = this.params.autoplay || false;

        this._load(elt, peaks, elt.preload);
    }

    /**
     * Method called by both `load` (from url)
     * and `loadElt` (existing media element) methods.
     *
     * @param {HTMLMediaElement} media HTML5 Audio or Video element
     * @param {number[]|Number.<Array[]>} peaks Array of peak data
     * @param {string} preload HTML 5 preload attribute value
     * @throws Will throw an error if the `media` argument is not a valid media
     * element.
     * @private
     */
    _load(media, peaks, preload) {
        // verify media element is valid
        if (
            !(media instanceof HTMLMediaElement) ||
            typeof media.addEventListener === 'undefined'
        ) {
            throw new Error('media parameter is not a valid media element');
        }

        // load must be called manually on iOS, otherwise peaks won't draw
        // until a user interaction triggers load --> 'ready' event
        //
        // note that we avoid calling media.load here when given peaks and preload == 'none'
        // as this almost always triggers some browser fetch of the media.
        if (typeof media.load == 'function' && !(peaks && preload == 'none')) {
            // Resets the media element and restarts the media resource. Any
            // pending events are discarded. How much media data is fetched is
            // still affected by the preload attribute.
            media.load();
        }

        this.media = media;
        this._setupMediaListeners();
        this.peaks = peaks;
        this.onPlayEnd = null;
        this.buffer = null;
        this.isMuted = media.muted;
        this.setPlaybackRate(this.playbackRate);
        this.setVolume(this.volume);
    }

    /**
     * Used by `wavesurfer.isPlaying()` and `wavesurfer.playPause()`
     *
     * @return {boolean} Media paused or not
     */
    isPaused() {
        return !this.media || this.media.paused;
    }

    /**
     * Used by `wavesurfer.getDuration()`
     *
     * @return {number} Duration
     */
    getDuration() {
        if (this.explicitDuration) {
            return this.explicitDuration;
        }
        let duration = (this.buffer || this.media).duration;
        if (duration >= Infinity) {
            // streaming audio
            duration = this.media.seekable.end(0);
        }
        return duration;
    }

    /**
     * Returns the current time in seconds relative to the audio-clip's
     * duration.
     *
     * @return {number} Current time
     */
    getCurrentTime() {
        return this.media && this.media.currentTime;
    }

    /**
     * Get the position from 0 to 1
     *
     * @return {number} Current position
     */
    getPlayedPercents() {
        return this.getCurrentTime() / this.getDuration() || 0;
    }

    /**
     * Get the audio source playback rate.
     *
     * @return {number} Playback rate
     */
    getPlaybackRate() {
        return this.playbackRate || this.media.playbackRate;
    }

    /**
     * Set the audio source playback rate.
     *
     * @param {number} value Playback rate
     */
    setPlaybackRate(value) {
        this.playbackRate = value || 1;
        this.media.playbackRate = this.playbackRate;
    }

    /**
     * Used by `wavesurfer.seekTo()`
     *
     * @param {number} start Position to start at in seconds
     */
    seekTo(start) {
        if (start != null && !isNaN(start)) {
            this.media.currentTime = start;
        }
        this.clearPlayEnd();
    }

    /**
     * Plays the loaded audio region.
     *
     * @param {number} start Start offset in seconds, relative to the beginning
     * of a clip.
     * @param {number} end When to stop, relative to the beginning of a clip.
     * @emits MediaElement#play
     * @return {Promise} Result
     */
    play(start, end) {
        this.seekTo(start);
        const promise = this.media.play();
        end && this.setPlayEnd(end);

        return promise;
    }

    /**
     * Pauses the loaded audio.
     *
     * @emits MediaElement#pause
     * @return {Promise} Result
     */
    pause() {
        let promise;

        if (this.media) {
            promise = this.media.pause();
        }
        this.clearPlayEnd();

        return promise;
    }

    /**
     * Set the play end
     *
     * @param {number} end Where to end
     */
    setPlayEnd(end) {
        this.clearPlayEnd();

        this._onPlayEnd = time => {
            if (time >= end) {
                this.pause();
                this.seekTo(end);
            }
        };
        this.on('audioprocess', this._onPlayEnd);
    }

    /** @private */
    clearPlayEnd() {
        if (this._onPlayEnd) {
            this.un('audioprocess', this._onPlayEnd);
            this._onPlayEnd = null;
        }
    }

    /**
     * Compute the max and min value of the waveform when broken into
     * <length> subranges.
     *
     * @param {number} length How many subranges to break the waveform into.
     * @param {number} first First sample in the required range.
     * @param {number} last Last sample in the required range.
     * @return {number[]|Number.<Array[]>} Array of 2*<length> peaks or array of
     * arrays of peaks consisting of (max, min) values for each subrange.
     */
    getPeaks(length, first, last) {
        if (this.buffer) {
            return super.getPeaks(length, first, last);
        }
        return this.peaks || [];
    }

    /**
     * Set the sink id for the media player
     *
     * @param {string} deviceId String value representing audio device id.
     * @returns {Promise} A Promise that resolves to `undefined` when there
     * are no errors.
     */
    setSinkId(deviceId) {
        if (deviceId) {
            if (!this.media.setSinkId) {
                return Promise.reject(
                    new Error('setSinkId is not supported in your browser')
                );
            }
            return this.media.setSinkId(deviceId);
        }

        return Promise.reject(new Error('Invalid deviceId: ' + deviceId));
    }

    /**
     * Get the current volume
     *
     * @return {number} value A floating point value between 0 and 1.
     */
    getVolume() {
        return this.volume;
    }

    /**
     * Set the audio volume
     *
     * @param {number} value A floating point value between 0 and 1.
     */
    setVolume(value) {
        this.volume = value;
        // no need to change when it's already at that volume
        if (this.media.volume !== this.volume) {
            this.media.volume = this.volume;
        }
    }

    /**
     * Enable or disable muted audio
     *
     * @since 4.0.0
     * @param {boolean} muted Specify `true` to mute audio.
     */
    setMute(muted) {
        // This causes a volume change to be emitted too through the
        // volumechange event listener.
        this.isMuted = this.media.muted = muted;
    }

    /**
     * This is called when wavesurfer is destroyed
     *
     */
    destroy() {
        this.pause();
        this.unAll();
        this.destroyed = true;

        // cleanup media event listeners
        Object.keys(this.mediaListeners).forEach(id => {
            if (this.media) {
                this.media.removeEventListener(id, this.mediaListeners[id]);
            }
        });

        if (
            this.params.removeMediaElementOnDestroy &&
            this.media &&
            this.media.parentNode
        ) {
            this.media.parentNode.removeChild(this.media);
        }

        this.media = null;
    }
}
