/**
 * @typedef {Object} ElanPluginParams
 * @property {string|HTMLElement} container CSS selector or HTML element where
 * the ELAN information should be rendered.
 * @property {string} url The location of ELAN XML data
 * @property {?boolean} deferInit Set to true to manually call
 * @property {?Object} tiers If set only shows the data tiers with the `TIER_ID`
 * in this map.
 */

/**
 * Downloads and renders ELAN audio transcription documents alongside the
 * waveform.
 *
 * @implements {PluginClass}
 * @extends {Observer}
 * @example
 * // es6
 * import ElanPlugin from 'wavesurfer.elan.js';
 *
 * // commonjs
 * var ElanPlugin = require('wavesurfer.elan.js');
 *
 * // if you are using <script> tags
 * var ElanPlugin = window.WaveSurfer.elan;
 *
 * // ... initialising wavesurfer with the plugin
 * var wavesurfer = WaveSurfer.create({
 *   // wavesurfer options ...
 *   plugins: [
 *     ElanPlugin.create({
 *       // plugin options ...
 *     })
 *   ]
 * });
 */
export default class ElanPlugin {
    /**
     * Elan plugin definition factory
     *
     * This function must be used to create a plugin definition which can be
     * used by wavesurfer to correctly instantiate the plugin.
     *
     * @param  {ElanPluginParams} params parameters use to initialise the plugin
     * @return {PluginDefinition} an object representing the plugin
     */
    static create(params) {
        return {
            name: 'elan',
            deferInit: params && params.deferInit ? params.deferInit : false,
            params: params,
            instance: ElanPlugin
        };
    }

    Types = {
        ALIGNABLE_ANNOTATION: 'ALIGNABLE_ANNOTATION',
        REF_ANNOTATION: 'REF_ANNOTATION'
    };

    constructor(params, ws) {
        this.data = null;
        this.params = params;
        this.container =
            'string' == typeof params.container
                ? document.querySelector(params.container)
                : params.container;

        if (!this.container) {
            throw Error('No container for ELAN');
        }
    }

    init() {
        this.bindClick();

        if (this.params.url) {
            this.load(this.params.url);
        }
    }

    destroy() {
        this.container.removeEventListener('click', this._onClick);
        this.container.removeChild(this.table);
    }

    load(url) {
        this.loadXML(url, xml => {
            this.data = this.parseElan(xml);
            this.render();
            this.fireEvent('ready', this.data);
        });
    }

    loadXML(url, callback) {
        const xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.responseType = 'document';
        xhr.send();
        xhr.addEventListener('load', e => {
            callback && callback(e.target.responseXML);
        });
    }

    parseElan(xml) {
        const _forEach = Array.prototype.forEach;
        const _map = Array.prototype.map;

        const data = {
            media: {},
            timeOrder: {},
            tiers: [],
            annotations: {},
            alignableAnnotations: []
        };

        const header = xml.querySelector('HEADER');
        const inMilliseconds =
            header.getAttribute('TIME_UNITS') == 'milliseconds';
        const media = header.querySelector('MEDIA_DESCRIPTOR');
        data.media.url = media.getAttribute('MEDIA_URL');
        data.media.type = media.getAttribute('MIME_TYPE');

        const timeSlots = xml.querySelectorAll('TIME_ORDER TIME_SLOT');
        const timeOrder = {};
        _forEach.call(timeSlots, slot => {
            let value = parseFloat(slot.getAttribute('TIME_VALUE'));
            // If in milliseconds, convert to seconds with rounding
            if (inMilliseconds) {
                value = Math.round(value * 1e2) / 1e5;
            }
            timeOrder[slot.getAttribute('TIME_SLOT_ID')] = value;
        });

        data.tiers = _map.call(xml.querySelectorAll('TIER'), tier => ({
            id: tier.getAttribute('TIER_ID'),
            linguisticTypeRef: tier.getAttribute('LINGUISTIC_TYPE_REF'),
            defaultLocale: tier.getAttribute('DEFAULT_LOCALE'),
            annotations: _map.call(
                tier.querySelectorAll('REF_ANNOTATION, ALIGNABLE_ANNOTATION'),
                node => {
                    const annot = {
                        type: node.nodeName,
                        id: node.getAttribute('ANNOTATION_ID'),
                        ref: node.getAttribute('ANNOTATION_REF'),
                        value: node
                            .querySelector('ANNOTATION_VALUE')
                            .textContent.trim()
                    };

                    if (this.Types.ALIGNABLE_ANNOTATION == annot.type) {
                        // Add start & end to alignable annotation
                        annot.start =
                            timeOrder[node.getAttribute('TIME_SLOT_REF1')];
                        annot.end =
                            timeOrder[node.getAttribute('TIME_SLOT_REF2')];
                        // Add to the list of alignable annotations
                        data.alignableAnnotations.push(annot);
                    }

                    // Additionally, put into the flat map of all annotations
                    data.annotations[annot.id] = annot;

                    return annot;
                }
            )
        }));

        // Create JavaScript references between annotations
        data.tiers.forEach(tier => {
            tier.annotations.forEach(annot => {
                if (null != annot.ref) {
                    annot.reference = data.annotations[annot.ref];
                }
            });
        });

        // Sort alignable annotations by start & end
        data.alignableAnnotations.sort((a, b) => {
            let d = a.start - b.start;
            if (d == 0) {
                d = b.end - a.end;
            }
            return d;
        });

        data.length = data.alignableAnnotations.length;

        return data;
    }

    render() {
        // apply tiers filter
        let tiers = this.data.tiers;
        if (this.params.tiers) {
            tiers = tiers.filter(tier => tier.id in this.params.tiers);
        }

        // denormalize references to alignable annotations
        const backRefs = {};
        let indeces = {};
        tiers.forEach((tier, index) => {
            tier.annotations.forEach(annot => {
                if (
                    annot.reference &&
                    annot.reference.type == this.Types.ALIGNABLE_ANNOTATION
                ) {
                    if (!(annot.reference.id in backRefs)) {
                        backRefs[annot.ref] = {};
                    }
                    backRefs[annot.ref][index] = annot;
                    indeces[index] = true;
                }
            });
        });
        indeces = Object.keys(indeces).sort();

        this.renderedAlignable = this.data.alignableAnnotations.filter(
            alignable => backRefs[alignable.id]
        );

        // table
        const table = (this.table = document.createElement('table'));
        table.className = 'wavesurfer-annotations';

        // head
        const thead = document.createElement('thead');
        const headRow = document.createElement('tr');
        thead.appendChild(headRow);
        table.appendChild(thead);
        const th = document.createElement('th');
        th.textContent = 'Time';
        th.className = 'wavesurfer-time';
        headRow.appendChild(th);
        indeces.forEach(index => {
            const tier = tiers[index];
            const th = document.createElement('th');
            th.className = 'wavesurfer-tier-' + tier.id;
            th.textContent = tier.id;
            if (this.params.tiers) { th.style.width = this.params.tiers[tier.id]; }
            headRow.appendChild(th);
        });

        // body
        const tbody = document.createElement('tbody');
        table.appendChild(tbody);
        this.renderedAlignable.forEach(alignable => {
            const row = document.createElement('tr');
            row.id = 'wavesurfer-alignable-' + alignable.id;
            tbody.appendChild(row);

            const td = document.createElement('td');
            td.className = 'wavesurfer-time';
            td.textContent =
                alignable.start.toFixed(1) + '–' + alignable.end.toFixed(1);
            row.appendChild(td);

            const backRef = backRefs[alignable.id];
            indeces.forEach(index => {
                const tier = tiers[index];
                const td = document.createElement('td');
                const annotation = backRef[index];
                if (annotation) {
                    td.id = 'wavesurfer-annotation-' + annotation.id;
                    td.dataset.ref = alignable.id;
                    td.dataset.start = alignable.start;
                    td.dataset.end = alignable.end;
                    td.textContent = annotation.value;
                }
                td.className = 'wavesurfer-tier-' + tier.id;
                row.appendChild(td);
            });
        });

        this.container.innerHTML = '';
        this.container.appendChild(table);
    }

    bindClick() {
        this._onClick = e => {
            const ref = e.target.dataset.ref;
            if (null != ref) {
                const annot = this.data.annotations[ref];
                if (annot) {
                    this.fireEvent('select', annot.start, annot.end);
                }
            }
        };
        this.container.addEventListener('click', this._onClick);
    }

    getRenderedAnnotation(time) {
        let result;
        this.renderedAlignable.some(annotation => {
            if (annotation.start <= time && annotation.end >= time) {
                result = annotation;
                return true;
            }
            return false;
        });
        return result;
    }

    getAnnotationNode(annotation) {
        return document.getElementById('wavesurfer-alignable-' + annotation.id);
    }
}
