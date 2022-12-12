/* eslint-enable complexity, no-redeclare, no-var, one-var */

import FFT from './fft';

/**
 * @typedef {Object} SpectrogramPluginParams
 * @property {string|HTMLElement} container Selector of element or element in
 * which to render
 * @property {number} fftSamples=512 Number of samples to fetch to FFT. Must be
 * a power of 2.
 * @property {boolean} splitChannels=false Render with separate spectrograms for
 * the channels of the audio
 * @property {boolean} labels Set to true to display frequency labels.
 * @property {number} noverlap Size of the overlapping window. Must be <
 * fftSamples. Auto deduced from canvas size by default.
 * @property {string} windowFunc='hann' The window function to be used. One of
 * these: `'bartlett'`, `'bartlettHann'`, `'blackman'`, `'cosine'`, `'gauss'`,
 * `'hamming'`, `'hann'`, `'lanczoz'`, `'rectangular'`, `'triangular'`
 * @property {?number} alpha Some window functions have this extra value.
 * (Between 0 and 1)
 * @property {number} pixelRatio=wavesurfer.params.pixelRatio to control the
 * size of the spectrogram in relation with its canvas. 1 = Draw on the whole
 * canvas. 2 = Draw on a quarter (1/2 the length and 1/2 the width)
 * @property {number} frequencyMin=0 Min frequency to scale spectrogram.
 * @property {number} frequencyMax=12000 Max frequency to scale spectrogram.
 * Set this to samplerate/2 to draw whole range of spectrogram.
 * @property {?boolean} deferInit Set to true to manually call
 * `initPlugin('spectrogram')`
 * @property {?number[][]} colorMap A 256 long array of 4-element arrays.
 * Each entry should contain a float between 0 and 1 and specify
 * r, g, b, and alpha.
 */

/**
 * Render a spectrogram visualisation of the audio.
 *
 * @implements {PluginClass}
 * @extends {Observer}
 * @example
 * // es6
 * import SpectrogramPlugin from 'wavesurfer.spectrogram.js';
 *
 * // commonjs
 * var SpectrogramPlugin = require('wavesurfer.spectrogram.js');
 *
 * // if you are using <script> tags
 * var SpectrogramPlugin = window.WaveSurfer.spectrogram;
 *
 * // ... initialising wavesurfer with the plugin
 * var wavesurfer = WaveSurfer.create({
 *   // wavesurfer options ...
 *   plugins: [
 *     SpectrogramPlugin.create({
 *       // plugin options ...
 *     })
 *   ]
 * });
 */
export default class SpectrogramPlugin {
    /**
     * Spectrogram plugin definition factory
     *
     * This function must be used to create a plugin definition which can be
     * used by wavesurfer to correctly instantiate the plugin.
     *
     * @param  {SpectrogramPluginParams} params Parameters used to initialise the plugin
     * @return {PluginDefinition} An object representing the plugin.
     */
    static create(params) {
        return {
            name: 'spectrogram',
            deferInit: params && params.deferInit ? params.deferInit : false,
            params: params,
            staticProps: {
                FFT: FFT
            },
            instance: SpectrogramPlugin
        };
    }

    constructor(params, ws) {
        this.params = params;
        this.wavesurfer = ws;
        this.util = ws.util;

        this.frequenciesDataUrl = params.frequenciesDataUrl;
        this._onScroll = e => {
            this.updateScroll(e);
        };
        this._onRender = () => {
            this.render();
        };
        this._onWrapperClick = e => {
            this._wrapperClickHandler(e);
        };
        this._onReady = () => {
            const drawer = (this.drawer = ws.drawer);

            this.container =
                'string' == typeof params.container
                    ? document.querySelector(params.container)
                    : params.container;

            if (!this.container) {
                throw Error('No container for WaveSurfer spectrogram');
            }
            if (params.colorMap) {
                if (params.colorMap.length < 256) {
                    throw new Error('Colormap must contain 256 elements');
                }
                for (let i = 0; i < params.colorMap.length; i++) {
                    const cmEntry = params.colorMap[i];
                    if (cmEntry.length !== 4) {
                        throw new Error(
                            'ColorMap entries must contain 4 values'
                        );
                    }
                }
                this.colorMap = params.colorMap;
            } else {
                this.colorMap = [];
                for (let i = 0; i < 256; i++) {
                    const val = (255 - i) / 256;
                    this.colorMap.push([val, val, val, 1]);
                }
            }
            this.width = drawer.width;
            this.pixelRatio = this.params.pixelRatio || ws.params.pixelRatio;
            this.fftSamples =
                this.params.fftSamples || ws.params.fftSamples || 512;
            this.height = this.fftSamples / 2;
            this.noverlap = params.noverlap;
            this.windowFunc = params.windowFunc;
            this.alpha = params.alpha;
            this.splitChannels = params.splitChannels;
            this.channels = this.splitChannels ? ws.backend.buffer.numberOfChannels : 1;

            // Getting file's original samplerate is difficult(#1248).
            // So set 12kHz default to render like wavesurfer.js 5.x.
            this.frequencyMin = params.frequencyMin || 0;
            this.frequencyMax = params.frequencyMax || 12000;

            this.createWrapper();
            this.createCanvas();
            this.render();

            drawer.wrapper.addEventListener('scroll', this._onScroll);
            ws.on('redraw', this._onRender);
        };
    }

    init() {
        // Check if wavesurfer is ready
        if (this.wavesurfer.isReady) {
            this._onReady();
        } else {
            this.wavesurfer.once('ready', this._onReady);
        }
    }

    destroy() {
        this.unAll();
        this.wavesurfer.un('ready', this._onReady);
        this.wavesurfer.un('redraw', this._onRender);
        this.drawer && this.drawer.wrapper.removeEventListener('scroll', this._onScroll);
        this.wavesurfer = null;
        this.util = null;
        this.params = null;
        if (this.wrapper) {
            this.wrapper.removeEventListener('click', this._onWrapperClick);
            this.wrapper.parentNode.removeChild(this.wrapper);
            this.wrapper = null;
        }
    }

    createWrapper() {
        const prevSpectrogram = this.container.querySelector('spectrogram');
        if (prevSpectrogram) {
            this.container.removeChild(prevSpectrogram);
        }
        const wsParams = this.wavesurfer.params;
        this.wrapper = document.createElement('spectrogram');
        // if labels are active
        if (this.params.labels) {
            const labelsEl = (this.labelsEl = document.createElement('canvas'));
            labelsEl.classList.add('spec-labels');
            this.drawer.style(labelsEl, {
                left: 0,
                position: 'absolute',
                zIndex: 9,
                height: `${this.height * this.channels / this.pixelRatio}px`,
                width: `${55 / this.pixelRatio}px`
            });
            this.wrapper.appendChild(labelsEl);
            this.loadLabels(
                'rgba(68,68,68,0.5)',
                '12px',
                '10px',
                '',
                '#fff',
                '#f7f7f7',
                'center',
                '#specLabels'
            );
        }

        this.drawer.style(this.wrapper, {
            display: 'block',
            position: 'relative',
            userSelect: 'none',
            webkitUserSelect: 'none',
            height: `${this.height * this.channels / this.pixelRatio}px`
        });

        if (wsParams.fillParent || wsParams.scrollParent) {
            this.drawer.style(this.wrapper, {
                width: '100%',
                overflowX: 'hidden',
                overflowY: 'hidden'
            });
        }
        this.container.appendChild(this.wrapper);

        this.wrapper.addEventListener('click', this._onWrapperClick);
    }

    _wrapperClickHandler(event) {
        event.preventDefault();
        const relX = 'offsetX' in event ? event.offsetX : event.layerX;
        this.fireEvent('click', relX / this.width || 0);
    }

    createCanvas() {
        const canvas = (this.canvas = this.wrapper.appendChild(
            document.createElement('canvas')
        ));

        this.spectrCc = canvas.getContext('2d');

        this.util.style(canvas, {
            position: 'absolute',
            zIndex: 4
        });
    }

    render() {
        this.updateCanvasStyle();

        if (this.frequenciesDataUrl) {
            this.loadFrequenciesData(this.frequenciesDataUrl);
        } else {
            this.getFrequencies(this.drawSpectrogram);
        }
    }

    updateCanvasStyle() {
        const width = Math.round(this.width / this.pixelRatio) + 'px';
        this.canvas.width = this.width;
        this.canvas.height = this.height * this.channels;
        this.canvas.style.width = width;
    }

    drawSpectrogram(frequenciesData, my) {
        if (!isNaN(frequenciesData[0][0])) { // data is 1ch [sample, freq] format
            // to [channel, sample, freq] format
            frequenciesData = [frequenciesData];
        }

        const spectrCc = my.spectrCc;
        const height = my.height;
        const width = my.width;
        const freqFrom = my.buffer.sampleRate / 2;
        const freqMin = my.frequencyMin;
        const freqMax = my.frequencyMax;

        if (!spectrCc) {
            return;
        }

        for (let c = 0; c < frequenciesData.length; c++) { // for each channel
            const pixels = my.resample(frequenciesData[c]);
            const imageData = new ImageData(width, height);

            for (let i = 0; i < pixels.length; i++) {
                for (let j = 0; j < pixels[i].length; j++) {
                    const colorMap = my.colorMap[pixels[i][j]];
                    const redIndex = ((height - j) * width + i) * 4;
                    imageData.data[redIndex] = colorMap[0] * 255;
                    imageData.data[redIndex + 1] = colorMap[1] * 255;
                    imageData.data[redIndex + 2] = colorMap[2] * 255;
                    imageData.data[redIndex + 3] = colorMap[3] * 255;
                }
            }

            // scale and stack spectrograms
            createImageBitmap(imageData).then(renderer =>
                spectrCc.drawImage(renderer,
                    0, height * (1 - freqMax / freqFrom), // source x, y
                    width, height * (freqMax - freqMin) / freqFrom, // source width, height
                    0, height * c, // destination x, y
                    width, height // destination width, height
                )
            );
        }
    }

    getFrequencies(callback) {
        const fftSamples = this.fftSamples;
        const buffer = (this.buffer = this.wavesurfer.backend.buffer);
        const channels = this.channels;

        if (!buffer) {
            this.fireEvent('error', 'Web Audio buffer is not available');
            return;
        }

        // This may differ from file samplerate. Browser resamples audio.
        const sampleRate = buffer.sampleRate;
        const frequencies = [];

        let noverlap = this.noverlap;
        if (!noverlap) {
            const uniqueSamplesPerPx = buffer.length / this.canvas.width;
            noverlap = Math.max(0, Math.round(fftSamples - uniqueSamplesPerPx));
        }

        const fft = new FFT(
            fftSamples,
            sampleRate,
            this.windowFunc,
            this.alpha
        );

        for (let c = 0; c < channels; c++) { // for each channel
            const channelData = buffer.getChannelData(c);
            const channelFreq = [];
            let currentOffset = 0;

            while (currentOffset + fftSamples < channelData.length) {
                const segment = channelData.slice(
                    currentOffset,
                    currentOffset + fftSamples
                );
                const spectrum = fft.calculateSpectrum(segment);
                const array = new Uint8Array(fftSamples / 2);
                let j;
                for (j = 0; j < fftSamples / 2; j++) {
                    array[j] = Math.max(-255, Math.log10(spectrum[j]) * 45);
                }
                channelFreq.push(array);
                // channelFreq: [sample, freq]

                currentOffset += fftSamples - noverlap;
            }
            frequencies.push(channelFreq);
            // frequencies: [channel, sample, freq]
        }
        callback(frequencies, this);
    }

    loadFrequenciesData(url) {
        const request = this.util.fetchFile({ url: url });

        request.on('success', data =>
            this.drawSpectrogram(JSON.parse(data), this)
        );
        request.on('error', e => this.fireEvent('error', e));

        return request;
    }

    freqType(freq) {
        return freq >= 1000 ? (freq / 1000).toFixed(1) : Math.round(freq);
    }

    unitType(freq) {
        return freq >= 1000 ? 'KHz' : 'Hz';
    }

    loadLabels(
        bgFill,
        fontSizeFreq,
        fontSizeUnit,
        fontType,
        textColorFreq,
        textColorUnit,
        textAlign,
        container
    ) {
        const frequenciesHeight = this.height;
        bgFill = bgFill || 'rgba(68,68,68,0)';
        fontSizeFreq = fontSizeFreq || '12px';
        fontSizeUnit = fontSizeUnit || '10px';
        fontType = fontType || 'Helvetica';
        textColorFreq = textColorFreq || '#fff';
        textColorUnit = textColorUnit || '#fff';
        textAlign = textAlign || 'center';
        container = container || '#specLabels';
        const bgWidth = 55;
        const getMaxY = frequenciesHeight || 512;
        const labelIndex = 5 * (getMaxY / 256);
        const freqStart = this.frequencyMin;
        const step = (this.frequencyMax - freqStart) / labelIndex;

        // prepare canvas element for labels
        const ctx = this.labelsEl.getContext('2d');
        this.labelsEl.height = this.height * this.channels;
        this.labelsEl.width = bgWidth;

        if (!ctx) {
            return;
        }

        for (let c = 0; c < this.channels; c++) { // for each channel
            // fill background
            ctx.fillStyle = bgFill;
            ctx.fillRect(0, c * getMaxY, bgWidth, (1 + c) * getMaxY);
            ctx.fill();
            let i;

            // render labels
            for (i = 0; i <= labelIndex; i++) {
                ctx.textAlign = textAlign;
                ctx.textBaseline = 'middle';

                const freq = freqStart + step * i;
                const label = this.freqType(freq);
                const units = this.unitType(freq);
                const yLabelOffset = 2;
                const x = 16;
                let y;

                if (i == 0) {
                    y = (1 + c) * getMaxY + i - 10;
                    // unit label
                    ctx.fillStyle = textColorUnit;
                    ctx.font = fontSizeUnit + ' ' + fontType;
                    ctx.fillText(units, x + 24, y);
                    // freq label
                    ctx.fillStyle = textColorFreq;
                    ctx.font = fontSizeFreq + ' ' + fontType;
                    ctx.fillText(label, x, y);
                } else {
                    y = (1 + c) * getMaxY - i * 50 + yLabelOffset;
                    // unit label
                    ctx.fillStyle = textColorUnit;
                    ctx.font = fontSizeUnit + ' ' + fontType;
                    ctx.fillText(units, x + 24, y);
                    // freq label
                    ctx.fillStyle = textColorFreq;
                    ctx.font = fontSizeFreq + ' ' + fontType;
                    ctx.fillText(label, x, y);
                }
            }
        }
    }

    updateScroll(e) {
        if (this.wrapper) {
            this.wrapper.scrollLeft = e.target.scrollLeft;
        }
    }

    resample(oldMatrix) {
        const columnsNumber = this.width;
        const newMatrix = [];

        const oldPiece = 1 / oldMatrix.length;
        const newPiece = 1 / columnsNumber;
        let i;

        for (i = 0; i < columnsNumber; i++) {
            const column = new Array(oldMatrix[0].length);
            let j;

            for (j = 0; j < oldMatrix.length; j++) {
                const oldStart = j * oldPiece;
                const oldEnd = oldStart + oldPiece;
                const newStart = i * newPiece;
                const newEnd = newStart + newPiece;

                const overlap =
                    oldEnd <= newStart || newEnd <= oldStart
                        ? 0
                        : Math.min(
                            Math.max(oldEnd, newStart),
                            Math.max(newEnd, oldStart)
                        ) -
                        Math.max(
                            Math.min(oldEnd, newStart),
                            Math.min(newEnd, oldStart)
                        );
                let k;
                /* eslint-disable max-depth */
                if (overlap > 0) {
                    for (k = 0; k < oldMatrix[0].length; k++) {
                        if (column[k] == null) {
                            column[k] = 0;
                        }
                        column[k] += (overlap / newPiece) * oldMatrix[j][k];
                    }
                }
                /* eslint-enable max-depth */
            }

            const intColumn = new Uint8Array(oldMatrix[0].length);
            let m;

            for (m = 0; m < oldMatrix[0].length; m++) {
                intColumn[m] = column[m];
            }

            newMatrix.push(intColumn);
        }

        return newMatrix;
    }
}
