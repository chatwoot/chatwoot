var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
function watchProgress(response, progressCallback) {
    return __awaiter(this, void 0, void 0, function* () {
        if (!response.body || !response.headers)
            return;
        const reader = response.body.getReader();
        const contentLength = Number(response.headers.get('Content-Length')) || 0;
        let receivedLength = 0;
        // Process the data
        const processChunk = (value) => __awaiter(this, void 0, void 0, function* () {
            // Add to the received length
            receivedLength += (value === null || value === void 0 ? void 0 : value.length) || 0;
            const percentage = Math.round((receivedLength / contentLength) * 100);
            progressCallback(percentage);
        });
        const read = () => __awaiter(this, void 0, void 0, function* () {
            let data;
            try {
                data = yield reader.read();
            }
            catch (_a) {
                // Ignore errors because we can only handle the main response
                return;
            }
            // Continue reading data until done
            if (!data.done) {
                processChunk(data.value);
                yield read();
            }
        });
        read();
    });
}
function fetchBlob(url, progressCallback, requestInit) {
    return __awaiter(this, void 0, void 0, function* () {
        // Fetch the resource
        const response = yield fetch(url, requestInit);
        if (response.status >= 400) {
            throw new Error(`Failed to fetch ${url}: ${response.status} (${response.statusText})`);
        }
        // Read the data to track progress
        watchProgress(response.clone(), progressCallback);
        return response.blob();
    });
}
const Fetcher = {
    fetchBlob,
};
export default Fetcher;
