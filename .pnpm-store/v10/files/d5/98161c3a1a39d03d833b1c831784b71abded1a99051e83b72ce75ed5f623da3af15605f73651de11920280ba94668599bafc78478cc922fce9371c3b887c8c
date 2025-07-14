var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
import { makeDraggable } from './draggable.js';
import EventEmitter from './event-emitter.js';
class Renderer extends EventEmitter {
    constructor(options, audioElement) {
        super();
        this.timeouts = [];
        this.isScrollable = false;
        this.audioData = null;
        this.resizeObserver = null;
        this.lastContainerWidth = 0;
        this.isDragging = false;
        this.subscriptions = [];
        this.subscriptions = [];
        this.options = options;
        const parent = this.parentFromOptionsContainer(options.container);
        this.parent = parent;
        const [div, shadow] = this.initHtml();
        parent.appendChild(div);
        this.container = div;
        this.scrollContainer = shadow.querySelector('.scroll');
        this.wrapper = shadow.querySelector('.wrapper');
        this.canvasWrapper = shadow.querySelector('.canvases');
        this.progressWrapper = shadow.querySelector('.progress');
        this.cursor = shadow.querySelector('.cursor');
        if (audioElement) {
            shadow.appendChild(audioElement);
        }
        this.initEvents();
    }
    parentFromOptionsContainer(container) {
        let parent;
        if (typeof container === 'string') {
            parent = document.querySelector(container);
        }
        else if (container instanceof HTMLElement) {
            parent = container;
        }
        if (!parent) {
            throw new Error('Container not found');
        }
        return parent;
    }
    initEvents() {
        const getClickPosition = (e) => {
            const rect = this.wrapper.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            const relativeX = x / rect.width;
            const relativeY = y / rect.height;
            return [relativeX, relativeY];
        };
        // Add a click listener
        this.wrapper.addEventListener('click', (e) => {
            const [x, y] = getClickPosition(e);
            this.emit('click', x, y);
        });
        // Add a double click listener
        this.wrapper.addEventListener('dblclick', (e) => {
            const [x, y] = getClickPosition(e);
            this.emit('dblclick', x, y);
        });
        // Drag
        if (this.options.dragToSeek === true || typeof this.options.dragToSeek === 'object') {
            this.initDrag();
        }
        // Add a scroll listener
        this.scrollContainer.addEventListener('scroll', () => {
            const { scrollLeft, scrollWidth, clientWidth } = this.scrollContainer;
            const startX = scrollLeft / scrollWidth;
            const endX = (scrollLeft + clientWidth) / scrollWidth;
            this.emit('scroll', startX, endX, scrollLeft, scrollLeft + clientWidth);
        });
        // Re-render the waveform on container resize
        if (typeof ResizeObserver === 'function') {
            const delay = this.createDelay(100);
            this.resizeObserver = new ResizeObserver(() => {
                delay()
                    .then(() => this.onContainerResize())
                    .catch(() => undefined);
            });
            this.resizeObserver.observe(this.scrollContainer);
        }
    }
    onContainerResize() {
        const width = this.parent.clientWidth;
        if (width === this.lastContainerWidth && this.options.height !== 'auto')
            return;
        this.lastContainerWidth = width;
        this.reRender();
    }
    initDrag() {
        this.subscriptions.push(makeDraggable(this.wrapper, 
        // On drag
        (_, __, x) => {
            this.emit('drag', Math.max(0, Math.min(1, x / this.wrapper.getBoundingClientRect().width)));
        }, 
        // On start drag
        (x) => {
            this.isDragging = true;
            this.emit('dragstart', Math.max(0, Math.min(1, x / this.wrapper.getBoundingClientRect().width)));
        }, 
        // On end drag
        (x) => {
            this.isDragging = false;
            this.emit('dragend', Math.max(0, Math.min(1, x / this.wrapper.getBoundingClientRect().width)));
        }));
    }
    getHeight(optionsHeight, optionsSplitChannel) {
        var _a;
        const defaultHeight = 128;
        const numberOfChannels = ((_a = this.audioData) === null || _a === void 0 ? void 0 : _a.numberOfChannels) || 1;
        if (optionsHeight == null)
            return defaultHeight;
        if (!isNaN(Number(optionsHeight)))
            return Number(optionsHeight);
        if (optionsHeight === 'auto') {
            const height = this.parent.clientHeight || defaultHeight;
            if (optionsSplitChannel === null || optionsSplitChannel === void 0 ? void 0 : optionsSplitChannel.every((channel) => !channel.overlay))
                return height / numberOfChannels;
            return height;
        }
        return defaultHeight;
    }
    initHtml() {
        const div = document.createElement('div');
        const shadow = div.attachShadow({ mode: 'open' });
        const cspNonce = this.options.cspNonce && typeof this.options.cspNonce === 'string' ? this.options.cspNonce.replace(/"/g, '') : '';
        shadow.innerHTML = `
      <style${cspNonce ? ` nonce="${cspNonce}"` : ''}>
        :host {
          user-select: none;
          min-width: 1px;
        }
        :host audio {
          display: block;
          width: 100%;
        }
        :host .scroll {
          overflow-x: auto;
          overflow-y: hidden;
          width: 100%;
          position: relative;
        }
        :host .noScrollbar {
          scrollbar-color: transparent;
          scrollbar-width: none;
        }
        :host .noScrollbar::-webkit-scrollbar {
          display: none;
          -webkit-appearance: none;
        }
        :host .wrapper {
          position: relative;
          overflow: visible;
          z-index: 2;
        }
        :host .canvases {
          min-height: ${this.getHeight(this.options.height, this.options.splitChannels)}px;
        }
        :host .canvases > div {
          position: relative;
        }
        :host canvas {
          display: block;
          position: absolute;
          top: 0;
          image-rendering: pixelated;
        }
        :host .progress {
          pointer-events: none;
          position: absolute;
          z-index: 2;
          top: 0;
          left: 0;
          width: 0;
          height: 100%;
          overflow: hidden;
        }
        :host .progress > div {
          position: relative;
        }
        :host .cursor {
          pointer-events: none;
          position: absolute;
          z-index: 5;
          top: 0;
          left: 0;
          height: 100%;
          border-radius: 2px;
        }
      </style>

      <div class="scroll" part="scroll">
        <div class="wrapper" part="wrapper">
          <div class="canvases" part="canvases"></div>
          <div class="progress" part="progress"></div>
          <div class="cursor" part="cursor"></div>
        </div>
      </div>
    `;
        return [div, shadow];
    }
    /** Wavesurfer itself calls this method. Do not call it manually. */
    setOptions(options) {
        if (this.options.container !== options.container) {
            const newParent = this.parentFromOptionsContainer(options.container);
            newParent.appendChild(this.container);
            this.parent = newParent;
        }
        if (options.dragToSeek === true || typeof this.options.dragToSeek === 'object') {
            this.initDrag();
        }
        this.options = options;
        // Re-render the waveform
        this.reRender();
    }
    getWrapper() {
        return this.wrapper;
    }
    getWidth() {
        return this.scrollContainer.clientWidth;
    }
    getScroll() {
        return this.scrollContainer.scrollLeft;
    }
    setScroll(pixels) {
        this.scrollContainer.scrollLeft = pixels;
    }
    setScrollPercentage(percent) {
        const { scrollWidth } = this.scrollContainer;
        const scrollStart = scrollWidth * percent;
        this.setScroll(scrollStart);
    }
    destroy() {
        var _a, _b;
        this.subscriptions.forEach((unsubscribe) => unsubscribe());
        this.container.remove();
        (_a = this.resizeObserver) === null || _a === void 0 ? void 0 : _a.disconnect();
        (_b = this.unsubscribeOnScroll) === null || _b === void 0 ? void 0 : _b.call(this);
    }
    createDelay(delayMs = 10) {
        let timeout;
        let reject;
        const onClear = () => {
            if (timeout)
                clearTimeout(timeout);
            if (reject)
                reject();
        };
        this.timeouts.push(onClear);
        return () => {
            return new Promise((resolveFn, rejectFn) => {
                onClear();
                reject = rejectFn;
                timeout = setTimeout(() => {
                    timeout = undefined;
                    reject = undefined;
                    resolveFn();
                }, delayMs);
            });
        };
    }
    // Convert array of color values to linear gradient
    convertColorValues(color) {
        if (!Array.isArray(color))
            return color || '';
        if (color.length < 2)
            return color[0] || '';
        const canvasElement = document.createElement('canvas');
        const ctx = canvasElement.getContext('2d');
        const gradientHeight = canvasElement.height * (window.devicePixelRatio || 1);
        const gradient = ctx.createLinearGradient(0, 0, 0, gradientHeight);
        const colorStopPercentage = 1 / (color.length - 1);
        color.forEach((color, index) => {
            const offset = index * colorStopPercentage;
            gradient.addColorStop(offset, color);
        });
        return gradient;
    }
    getPixelRatio() {
        return Math.max(1, window.devicePixelRatio || 1);
    }
    renderBarWaveform(channelData, options, ctx, vScale) {
        const topChannel = channelData[0];
        const bottomChannel = channelData[1] || channelData[0];
        const length = topChannel.length;
        const { width, height } = ctx.canvas;
        const halfHeight = height / 2;
        const pixelRatio = this.getPixelRatio();
        const barWidth = options.barWidth ? options.barWidth * pixelRatio : 1;
        const barGap = options.barGap ? options.barGap * pixelRatio : options.barWidth ? barWidth / 2 : 0;
        const barRadius = options.barRadius || 0;
        const barIndexScale = width / (barWidth + barGap) / length;
        const rectFn = barRadius && 'roundRect' in ctx ? 'roundRect' : 'rect';
        ctx.beginPath();
        let prevX = 0;
        let maxTop = 0;
        let maxBottom = 0;
        for (let i = 0; i <= length; i++) {
            const x = Math.round(i * barIndexScale);
            if (x > prevX) {
                const topBarHeight = Math.round(maxTop * halfHeight * vScale);
                const bottomBarHeight = Math.round(maxBottom * halfHeight * vScale);
                const barHeight = topBarHeight + bottomBarHeight || 1;
                // Vertical alignment
                let y = halfHeight - topBarHeight;
                if (options.barAlign === 'top') {
                    y = 0;
                }
                else if (options.barAlign === 'bottom') {
                    y = height - barHeight;
                }
                ctx[rectFn](prevX * (barWidth + barGap), y, barWidth, barHeight, barRadius);
                prevX = x;
                maxTop = 0;
                maxBottom = 0;
            }
            const magnitudeTop = Math.abs(topChannel[i] || 0);
            const magnitudeBottom = Math.abs(bottomChannel[i] || 0);
            if (magnitudeTop > maxTop)
                maxTop = magnitudeTop;
            if (magnitudeBottom > maxBottom)
                maxBottom = magnitudeBottom;
        }
        ctx.fill();
        ctx.closePath();
    }
    renderLineWaveform(channelData, _options, ctx, vScale) {
        const drawChannel = (index) => {
            const channel = channelData[index] || channelData[0];
            const length = channel.length;
            const { height } = ctx.canvas;
            const halfHeight = height / 2;
            const hScale = ctx.canvas.width / length;
            ctx.moveTo(0, halfHeight);
            let prevX = 0;
            let max = 0;
            for (let i = 0; i <= length; i++) {
                const x = Math.round(i * hScale);
                if (x > prevX) {
                    const h = Math.round(max * halfHeight * vScale) || 1;
                    const y = halfHeight + h * (index === 0 ? -1 : 1);
                    ctx.lineTo(prevX, y);
                    prevX = x;
                    max = 0;
                }
                const value = Math.abs(channel[i] || 0);
                if (value > max)
                    max = value;
            }
            ctx.lineTo(prevX, halfHeight);
        };
        ctx.beginPath();
        drawChannel(0);
        drawChannel(1);
        ctx.fill();
        ctx.closePath();
    }
    renderWaveform(channelData, options, ctx) {
        ctx.fillStyle = this.convertColorValues(options.waveColor);
        // Custom rendering function
        if (options.renderFunction) {
            options.renderFunction(channelData, ctx);
            return;
        }
        // Vertical scaling
        let vScale = options.barHeight || 1;
        if (options.normalize) {
            const max = Array.from(channelData[0]).reduce((max, value) => Math.max(max, Math.abs(value)), 0);
            vScale = max ? 1 / max : 1;
        }
        // Render waveform as bars
        if (options.barWidth || options.barGap || options.barAlign) {
            this.renderBarWaveform(channelData, options, ctx, vScale);
            return;
        }
        // Render waveform as a polyline
        this.renderLineWaveform(channelData, options, ctx, vScale);
    }
    renderSingleCanvas(data, options, width, height, offset, canvasContainer, progressContainer) {
        const pixelRatio = this.getPixelRatio();
        const canvas = document.createElement('canvas');
        canvas.width = Math.round(width * pixelRatio);
        canvas.height = Math.round(height * pixelRatio);
        canvas.style.width = `${width}px`;
        canvas.style.height = `${height}px`;
        canvas.style.left = `${Math.round(offset)}px`;
        canvasContainer.appendChild(canvas);
        const ctx = canvas.getContext('2d');
        this.renderWaveform(data, options, ctx);
        // Draw a progress canvas
        if (canvas.width > 0 && canvas.height > 0) {
            const progressCanvas = canvas.cloneNode();
            const progressCtx = progressCanvas.getContext('2d');
            progressCtx.drawImage(canvas, 0, 0);
            // Set the composition method to draw only where the waveform is drawn
            progressCtx.globalCompositeOperation = 'source-in';
            progressCtx.fillStyle = this.convertColorValues(options.progressColor);
            // This rectangle acts as a mask thanks to the composition method
            progressCtx.fillRect(0, 0, canvas.width, canvas.height);
            progressContainer.appendChild(progressCanvas);
        }
    }
    renderMultiCanvas(channelData, options, width, height, canvasContainer, progressContainer) {
        const pixelRatio = this.getPixelRatio();
        const { clientWidth } = this.scrollContainer;
        const totalWidth = width / pixelRatio;
        let singleCanvasWidth = Math.min(Renderer.MAX_CANVAS_WIDTH, clientWidth, totalWidth);
        let drawnIndexes = {};
        // Adjust width to avoid gaps between canvases when using bars
        if (options.barWidth || options.barGap) {
            const barWidth = options.barWidth || 0.5;
            const barGap = options.barGap || barWidth / 2;
            const totalBarWidth = barWidth + barGap;
            if (singleCanvasWidth % totalBarWidth !== 0) {
                singleCanvasWidth = Math.floor(singleCanvasWidth / totalBarWidth) * totalBarWidth;
            }
        }
        // Draw a single canvas
        const draw = (index) => {
            if (index < 0 || index >= numCanvases)
                return;
            if (drawnIndexes[index])
                return;
            drawnIndexes[index] = true;
            const offset = index * singleCanvasWidth;
            const clampedWidth = Math.min(totalWidth - offset, singleCanvasWidth);
            if (clampedWidth <= 0)
                return;
            const data = channelData.map((channel) => {
                const start = Math.floor((offset / totalWidth) * channel.length);
                const end = Math.floor(((offset + clampedWidth) / totalWidth) * channel.length);
                return channel.slice(start, end);
            });
            this.renderSingleCanvas(data, options, clampedWidth, height, offset, canvasContainer, progressContainer);
        };
        // Clear canvases to avoid too many DOM nodes
        const clearCanvases = () => {
            if (Object.keys(drawnIndexes).length > Renderer.MAX_NODES) {
                canvasContainer.innerHTML = '';
                progressContainer.innerHTML = '';
                drawnIndexes = {};
            }
        };
        // Calculate how many canvases to render
        const numCanvases = Math.ceil(totalWidth / singleCanvasWidth);
        // Render all canvases if the waveform doesn't scroll
        if (!this.isScrollable) {
            for (let i = 0; i < numCanvases; i++) {
                draw(i);
            }
            return;
        }
        // Lazy rendering
        const viewPosition = this.scrollContainer.scrollLeft / totalWidth;
        const startCanvas = Math.floor(viewPosition * numCanvases);
        // Draw the canvases in the viewport first
        draw(startCanvas - 1);
        draw(startCanvas);
        draw(startCanvas + 1);
        // Subscribe to the scroll event to draw additional canvases
        if (numCanvases > 1) {
            this.unsubscribeOnScroll = this.on('scroll', () => {
                const { scrollLeft } = this.scrollContainer;
                const canvasIndex = Math.floor((scrollLeft / totalWidth) * numCanvases);
                clearCanvases();
                draw(canvasIndex - 1);
                draw(canvasIndex);
                draw(canvasIndex + 1);
            });
        }
    }
    renderChannel(channelData, _a, width, channelIndex) {
        var { overlay } = _a, options = __rest(_a, ["overlay"]);
        // A container for canvases
        const canvasContainer = document.createElement('div');
        const height = this.getHeight(options.height, options.splitChannels);
        canvasContainer.style.height = `${height}px`;
        if (overlay && channelIndex > 0) {
            canvasContainer.style.marginTop = `-${height}px`;
        }
        this.canvasWrapper.style.minHeight = `${height}px`;
        this.canvasWrapper.appendChild(canvasContainer);
        // A container for progress canvases
        const progressContainer = canvasContainer.cloneNode();
        this.progressWrapper.appendChild(progressContainer);
        // Render the waveform
        this.renderMultiCanvas(channelData, options, width, height, canvasContainer, progressContainer);
    }
    render(audioData) {
        return __awaiter(this, void 0, void 0, function* () {
            var _a;
            // Clear previous timeouts
            this.timeouts.forEach((clear) => clear());
            this.timeouts = [];
            // Clear the canvases
            this.canvasWrapper.innerHTML = '';
            this.progressWrapper.innerHTML = '';
            // Width
            if (this.options.width != null) {
                this.scrollContainer.style.width =
                    typeof this.options.width === 'number' ? `${this.options.width}px` : this.options.width;
            }
            // Determine the width of the waveform
            const pixelRatio = this.getPixelRatio();
            const parentWidth = this.scrollContainer.clientWidth;
            const scrollWidth = Math.ceil(audioData.duration * (this.options.minPxPerSec || 0));
            // Whether the container should scroll
            this.isScrollable = scrollWidth > parentWidth;
            const useParentWidth = this.options.fillParent && !this.isScrollable;
            // Width of the waveform in pixels
            const width = (useParentWidth ? parentWidth : scrollWidth) * pixelRatio;
            // Set the width of the wrapper
            this.wrapper.style.width = useParentWidth ? '100%' : `${scrollWidth}px`;
            // Set additional styles
            this.scrollContainer.style.overflowX = this.isScrollable ? 'auto' : 'hidden';
            this.scrollContainer.classList.toggle('noScrollbar', !!this.options.hideScrollbar);
            this.cursor.style.backgroundColor = `${this.options.cursorColor || this.options.progressColor}`;
            this.cursor.style.width = `${this.options.cursorWidth}px`;
            this.audioData = audioData;
            this.emit('render');
            // Render the waveform
            if (this.options.splitChannels) {
                // Render a waveform for each channel
                for (let i = 0; i < audioData.numberOfChannels; i++) {
                    const options = Object.assign(Object.assign({}, this.options), (_a = this.options.splitChannels) === null || _a === void 0 ? void 0 : _a[i]);
                    this.renderChannel([audioData.getChannelData(i)], options, width, i);
                }
            }
            else {
                // Render a single waveform for the first two channels (left and right)
                const channels = [audioData.getChannelData(0)];
                if (audioData.numberOfChannels > 1)
                    channels.push(audioData.getChannelData(1));
                this.renderChannel(channels, this.options, width, 0);
            }
            // Must be emitted asynchronously for backward compatibility
            Promise.resolve().then(() => this.emit('rendered'));
        });
    }
    reRender() {
        var _a;
        (_a = this.unsubscribeOnScroll) === null || _a === void 0 ? void 0 : _a.call(this);
        delete this.unsubscribeOnScroll;
        // Return if the waveform has not been rendered yet
        if (!this.audioData)
            return;
        // Remember the current cursor position
        const { scrollWidth } = this.scrollContainer;
        const { right: before } = this.progressWrapper.getBoundingClientRect();
        // Re-render the waveform
        this.render(this.audioData);
        // Adjust the scroll position so that the cursor stays in the same place
        if (this.isScrollable && scrollWidth !== this.scrollContainer.scrollWidth) {
            const { right: after } = this.progressWrapper.getBoundingClientRect();
            let delta = after - before;
            // to limit compounding floating-point drift
            // we need to round to the half px furthest from 0
            delta *= 2;
            delta = delta < 0 ? Math.floor(delta) : Math.ceil(delta);
            delta /= 2;
            this.scrollContainer.scrollLeft += delta;
        }
    }
    zoom(minPxPerSec) {
        this.options.minPxPerSec = minPxPerSec;
        this.reRender();
    }
    scrollIntoView(progress, isPlaying = false) {
        const { scrollLeft, scrollWidth, clientWidth } = this.scrollContainer;
        const progressWidth = progress * scrollWidth;
        const startEdge = scrollLeft;
        const endEdge = scrollLeft + clientWidth;
        const middle = clientWidth / 2;
        if (this.isDragging) {
            // Scroll when dragging close to the edge of the viewport
            const minGap = 30;
            if (progressWidth + minGap > endEdge) {
                this.scrollContainer.scrollLeft += minGap;
            }
            else if (progressWidth - minGap < startEdge) {
                this.scrollContainer.scrollLeft -= minGap;
            }
        }
        else {
            if (progressWidth < startEdge || progressWidth > endEdge) {
                this.scrollContainer.scrollLeft = progressWidth - (this.options.autoCenter ? middle : 0);
            }
            // Keep the cursor centered when playing
            const center = progressWidth - scrollLeft - middle;
            if (isPlaying && this.options.autoCenter && center > 0) {
                this.scrollContainer.scrollLeft += Math.min(center, 10);
            }
        }
        // Emit the scroll event
        {
            const newScroll = this.scrollContainer.scrollLeft;
            const startX = newScroll / scrollWidth;
            const endX = (newScroll + clientWidth) / scrollWidth;
            this.emit('scroll', startX, endX, newScroll, newScroll + clientWidth);
        }
    }
    renderProgress(progress, isPlaying) {
        if (isNaN(progress))
            return;
        const percents = progress * 100;
        this.canvasWrapper.style.clipPath = `polygon(${percents}% 0, 100% 0, 100% 100%, ${percents}% 100%)`;
        this.progressWrapper.style.width = `${percents}%`;
        this.cursor.style.left = `${percents}%`;
        this.cursor.style.transform = `translateX(-${Math.round(percents) === 100 ? this.options.cursorWidth : 0}px)`;
        if (this.isScrollable && this.options.autoScroll) {
            this.scrollIntoView(progress, isPlaying);
        }
    }
    exportImage(format, quality, type) {
        return __awaiter(this, void 0, void 0, function* () {
            const canvases = this.canvasWrapper.querySelectorAll('canvas');
            if (!canvases.length) {
                throw new Error('No waveform data');
            }
            // Data URLs
            if (type === 'dataURL') {
                const images = Array.from(canvases).map((canvas) => canvas.toDataURL(format, quality));
                return Promise.resolve(images);
            }
            // Blobs
            return Promise.all(Array.from(canvases).map((canvas) => {
                return new Promise((resolve, reject) => {
                    canvas.toBlob((blob) => {
                        blob ? resolve(blob) : reject(new Error('Could not export image'));
                    }, format, quality);
                });
            }));
        });
    }
}
Renderer.MAX_CANVAS_WIDTH = 8000;
Renderer.MAX_NODES = 10;
export default Renderer;
