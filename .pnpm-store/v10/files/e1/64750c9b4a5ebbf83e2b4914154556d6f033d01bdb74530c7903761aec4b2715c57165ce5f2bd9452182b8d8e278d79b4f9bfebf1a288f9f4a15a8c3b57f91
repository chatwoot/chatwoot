var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
import BasePlugin from './base-plugin.js';
import Decoder from './decoder.js';
import * as dom from './dom.js';
import Fetcher from './fetcher.js';
import Player from './player.js';
import Renderer from './renderer.js';
import Timer from './timer.js';
import WebAudioPlayer from './webaudio.js';
const defaultOptions = {
    waveColor: '#999',
    progressColor: '#555',
    cursorWidth: 1,
    minPxPerSec: 0,
    fillParent: true,
    interact: true,
    dragToSeek: false,
    autoScroll: true,
    autoCenter: true,
    sampleRate: 8000,
};
class WaveSurfer extends Player {
    /** Create a new WaveSurfer instance */
    static create(options) {
        return new WaveSurfer(options);
    }
    /** Create a new WaveSurfer instance */
    constructor(options) {
        const media = options.media ||
            (options.backend === 'WebAudio' ? new WebAudioPlayer() : undefined);
        super({
            media,
            mediaControls: options.mediaControls,
            autoplay: options.autoplay,
            playbackRate: options.audioRate,
        });
        this.plugins = [];
        this.decodedData = null;
        this.subscriptions = [];
        this.mediaSubscriptions = [];
        this.abortController = null;
        this.options = Object.assign({}, defaultOptions, options);
        this.timer = new Timer();
        const audioElement = media ? undefined : this.getMediaElement();
        this.renderer = new Renderer(this.options, audioElement);
        this.initPlayerEvents();
        this.initRendererEvents();
        this.initTimerEvents();
        this.initPlugins();
        // Read the initial URL before load has been called
        const initialUrl = this.options.url || this.getSrc() || '';
        // Init and load async to allow external events to be registered
        Promise.resolve().then(() => {
            this.emit('init');
            // Load audio if URL or an external media with an src is passed,
            // of render w/o audio if pre-decoded peaks and duration are provided
            const { peaks, duration } = this.options;
            if (initialUrl || (peaks && duration)) {
                // Swallow async errors because they cannot be caught from a constructor call.
                // Subscribe to the wavesurfer's error event to handle them.
                this.load(initialUrl, peaks, duration).catch(() => null);
            }
        });
    }
    updateProgress(currentTime = this.getCurrentTime()) {
        this.renderer.renderProgress(currentTime / this.getDuration(), this.isPlaying());
        return currentTime;
    }
    initTimerEvents() {
        // The timer fires every 16ms for a smooth progress animation
        this.subscriptions.push(this.timer.on('tick', () => {
            if (!this.isSeeking()) {
                const currentTime = this.updateProgress();
                this.emit('timeupdate', currentTime);
                this.emit('audioprocess', currentTime);
            }
        }));
    }
    initPlayerEvents() {
        if (this.isPlaying()) {
            this.emit('play');
            this.timer.start();
        }
        this.mediaSubscriptions.push(this.onMediaEvent('timeupdate', () => {
            const currentTime = this.updateProgress();
            this.emit('timeupdate', currentTime);
        }), this.onMediaEvent('play', () => {
            this.emit('play');
            this.timer.start();
        }), this.onMediaEvent('pause', () => {
            this.emit('pause');
            this.timer.stop();
        }), this.onMediaEvent('emptied', () => {
            this.timer.stop();
        }), this.onMediaEvent('ended', () => {
            this.emit('finish');
        }), this.onMediaEvent('seeking', () => {
            this.emit('seeking', this.getCurrentTime());
        }), this.onMediaEvent('error', (err) => {
            this.emit('error', err.error);
        }));
    }
    initRendererEvents() {
        this.subscriptions.push(
        // Seek on click
        this.renderer.on('click', (relativeX, relativeY) => {
            if (this.options.interact) {
                this.seekTo(relativeX);
                this.emit('interaction', relativeX * this.getDuration());
                this.emit('click', relativeX, relativeY);
            }
        }), 
        // Double click
        this.renderer.on('dblclick', (relativeX, relativeY) => {
            this.emit('dblclick', relativeX, relativeY);
        }), 
        // Scroll
        this.renderer.on('scroll', (startX, endX, scrollLeft, scrollRight) => {
            const duration = this.getDuration();
            this.emit('scroll', startX * duration, endX * duration, scrollLeft, scrollRight);
        }), 
        // Redraw
        this.renderer.on('render', () => {
            this.emit('redraw');
        }), 
        // RedrawComplete
        this.renderer.on('rendered', () => {
            this.emit('redrawcomplete');
        }), 
        // DragStart
        this.renderer.on('dragstart', (relativeX) => {
            this.emit('dragstart', relativeX);
        }), 
        // DragEnd
        this.renderer.on('dragend', (relativeX) => {
            this.emit('dragend', relativeX);
        }));
        // Drag
        {
            let debounce;
            this.subscriptions.push(this.renderer.on('drag', (relativeX) => {
                if (!this.options.interact)
                    return;
                // Update the visual position
                this.renderer.renderProgress(relativeX);
                // Set the audio position with a debounce
                clearTimeout(debounce);
                let debounceTime;
                if (this.isPlaying()) {
                    debounceTime = 0;
                }
                else if (this.options.dragToSeek === true) {
                    debounceTime = 200;
                }
                else if (typeof this.options.dragToSeek === 'object' && this.options.dragToSeek !== undefined) {
                    debounceTime = this.options.dragToSeek['debounceTime'];
                }
                debounce = setTimeout(() => {
                    this.seekTo(relativeX);
                }, debounceTime);
                this.emit('interaction', relativeX * this.getDuration());
                this.emit('drag', relativeX);
            }));
        }
    }
    initPlugins() {
        var _a;
        if (!((_a = this.options.plugins) === null || _a === void 0 ? void 0 : _a.length))
            return;
        this.options.plugins.forEach((plugin) => {
            this.registerPlugin(plugin);
        });
    }
    unsubscribePlayerEvents() {
        this.mediaSubscriptions.forEach((unsubscribe) => unsubscribe());
        this.mediaSubscriptions = [];
    }
    /** Set new wavesurfer options and re-render it */
    setOptions(options) {
        this.options = Object.assign({}, this.options, options);
        this.renderer.setOptions(this.options);
        if (options.audioRate) {
            this.setPlaybackRate(options.audioRate);
        }
        if (options.mediaControls != null) {
            this.getMediaElement().controls = options.mediaControls;
        }
    }
    /** Register a wavesurfer.js plugin */
    registerPlugin(plugin) {
        plugin._init(this);
        this.plugins.push(plugin);
        // Unregister plugin on destroy
        this.subscriptions.push(plugin.once('destroy', () => {
            this.plugins = this.plugins.filter((p) => p !== plugin);
        }));
        return plugin;
    }
    /** For plugins only: get the waveform wrapper div */
    getWrapper() {
        return this.renderer.getWrapper();
    }
    /** For plugins only: get the scroll container client width */
    getWidth() {
        return this.renderer.getWidth();
    }
    /** Get the current scroll position in pixels */
    getScroll() {
        return this.renderer.getScroll();
    }
    /** Set the current scroll position in pixels */
    setScroll(pixels) {
        return this.renderer.setScroll(pixels);
    }
    /** Move the start of the viewing window to a specific time in the audio (in seconds) */
    setScrollTime(time) {
        const percentage = time / this.getDuration();
        this.renderer.setScrollPercentage(percentage);
    }
    /** Get all registered plugins */
    getActivePlugins() {
        return this.plugins;
    }
    loadAudio(url, blob, channelData, duration) {
        return __awaiter(this, void 0, void 0, function* () {
            var _a;
            this.emit('load', url);
            if (!this.options.media && this.isPlaying())
                this.pause();
            this.decodedData = null;
            // Fetch the entire audio as a blob if pre-decoded data is not provided
            if (!blob && !channelData) {
                const fetchParams = this.options.fetchParams || {};
                if (window.AbortController && !fetchParams.signal) {
                    this.abortController = new AbortController();
                    fetchParams.signal = (_a = this.abortController) === null || _a === void 0 ? void 0 : _a.signal;
                }
                const onProgress = (percentage) => this.emit('loading', percentage);
                blob = yield Fetcher.fetchBlob(url, onProgress, fetchParams);
            }
            // Set the mediaelement source
            this.setSrc(url, blob);
            // Wait for the audio duration
            const audioDuration = yield new Promise((resolve) => {
                const staticDuration = duration || this.getDuration();
                if (staticDuration) {
                    resolve(staticDuration);
                }
                else {
                    this.mediaSubscriptions.push(this.onMediaEvent('loadedmetadata', () => resolve(this.getDuration()), { once: true }));
                }
            });
            // Set the duration if the player is a WebAudioPlayer without a URL
            if (!url && !blob) {
                const media = this.getMediaElement();
                if (media instanceof WebAudioPlayer) {
                    media.duration = audioDuration;
                }
            }
            // Decode the audio data or use user-provided peaks
            if (channelData) {
                this.decodedData = Decoder.createBuffer(channelData, audioDuration || 0);
            }
            else if (blob) {
                const arrayBuffer = yield blob.arrayBuffer();
                this.decodedData = yield Decoder.decode(arrayBuffer, this.options.sampleRate);
            }
            if (this.decodedData) {
                this.emit('decode', this.getDuration());
                this.renderer.render(this.decodedData);
            }
            this.emit('ready', this.getDuration());
        });
    }
    /** Load an audio file by URL, with optional pre-decoded audio data */
    load(url, channelData, duration) {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                return yield this.loadAudio(url, undefined, channelData, duration);
            }
            catch (err) {
                this.emit('error', err);
                throw err;
            }
        });
    }
    /** Load an audio blob */
    loadBlob(blob, channelData, duration) {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                return yield this.loadAudio('', blob, channelData, duration);
            }
            catch (err) {
                this.emit('error', err);
                throw err;
            }
        });
    }
    /** Zoom the waveform by a given pixels-per-second factor */
    zoom(minPxPerSec) {
        if (!this.decodedData) {
            throw new Error('No audio loaded');
        }
        this.renderer.zoom(minPxPerSec);
        this.emit('zoom', minPxPerSec);
    }
    /** Get the decoded audio data */
    getDecodedData() {
        return this.decodedData;
    }
    /** Get decoded peaks */
    exportPeaks({ channels = 2, maxLength = 8000, precision = 10000 } = {}) {
        if (!this.decodedData) {
            throw new Error('The audio has not been decoded yet');
        }
        const maxChannels = Math.min(channels, this.decodedData.numberOfChannels);
        const peaks = [];
        for (let i = 0; i < maxChannels; i++) {
            const channel = this.decodedData.getChannelData(i);
            const data = [];
            const sampleSize = channel.length / maxLength;
            for (let i = 0; i < maxLength; i++) {
                const sample = channel.slice(Math.floor(i * sampleSize), Math.ceil((i + 1) * sampleSize));
                let max = 0;
                for (let x = 0; x < sample.length; x++) {
                    const n = sample[x];
                    if (Math.abs(n) > Math.abs(max))
                        max = n;
                }
                data.push(Math.round(max * precision) / precision);
            }
            peaks.push(data);
        }
        return peaks;
    }
    /** Get the duration of the audio in seconds */
    getDuration() {
        let duration = super.getDuration() || 0;
        // Fall back to the decoded data duration if the media duration is incorrect
        if ((duration === 0 || duration === Infinity) && this.decodedData) {
            duration = this.decodedData.duration;
        }
        return duration;
    }
    /** Toggle if the waveform should react to clicks */
    toggleInteraction(isInteractive) {
        this.options.interact = isInteractive;
    }
    /** Jump to a specific time in the audio (in seconds) */
    setTime(time) {
        super.setTime(time);
        this.updateProgress(time);
        this.emit('timeupdate', time);
    }
    /** Seek to a percentage of audio as [0..1] (0 = beginning, 1 = end) */
    seekTo(progress) {
        const time = this.getDuration() * progress;
        this.setTime(time);
    }
    /** Play or pause the audio */
    playPause() {
        return __awaiter(this, void 0, void 0, function* () {
            return this.isPlaying() ? this.pause() : this.play();
        });
    }
    /** Stop the audio and go to the beginning */
    stop() {
        this.pause();
        this.setTime(0);
    }
    /** Skip N or -N seconds from the current position */
    skip(seconds) {
        this.setTime(this.getCurrentTime() + seconds);
    }
    /** Empty the waveform */
    empty() {
        this.load('', [[0]], 0.001);
    }
    /** Set HTML media element */
    setMediaElement(element) {
        this.unsubscribePlayerEvents();
        super.setMediaElement(element);
        this.initPlayerEvents();
    }
    exportImage() {
        return __awaiter(this, arguments, void 0, function* (format = 'image/png', quality = 1, type = 'dataURL') {
            return this.renderer.exportImage(format, quality, type);
        });
    }
    /** Unmount wavesurfer */
    destroy() {
        var _a;
        this.emit('destroy');
        (_a = this.abortController) === null || _a === void 0 ? void 0 : _a.abort();
        this.plugins.forEach((plugin) => plugin.destroy());
        this.subscriptions.forEach((unsubscribe) => unsubscribe());
        this.unsubscribePlayerEvents();
        this.timer.destroy();
        this.renderer.destroy();
        super.destroy();
    }
}
WaveSurfer.BasePlugin = BasePlugin;
WaveSurfer.dom = dom;
export default WaveSurfer;
