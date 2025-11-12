import { PostHogCore } from "../index.mjs";
const version = '2.0.0-alpha';
class PostHogCoreTestClient extends PostHogCore {
    getFlags(distinctId) {
        let groups = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : {}, personProperties = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : {}, groupProperties = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {}, extraPayload = arguments.length > 4 && void 0 !== arguments[4] ? arguments[4] : {};
        return super.getFlags(distinctId, groups, personProperties, groupProperties, extraPayload);
    }
    getPersistedProperty(key) {
        return this.mocks.storage.getItem(key);
    }
    setPersistedProperty(key, value) {
        return this.mocks.storage.setItem(key, value);
    }
    fetch(url, options) {
        return this.mocks.fetch(url, options);
    }
    getLibraryId() {
        return 'posthog-core-tests';
    }
    getLibraryVersion() {
        return version;
    }
    getCustomUserAgent() {
        return 'posthog-core-tests';
    }
    constructor(mocks, apiKey, options){
        super(apiKey, options), this.mocks = mocks;
        this.setupBootstrap(options);
    }
}
const createTestClient = function(apiKey, options, setupMocks) {
    let storageCache = arguments.length > 3 && void 0 !== arguments[3] ? arguments[3] : {};
    const mocks = {
        fetch: jest.fn(),
        storage: {
            getItem: jest.fn((key)=>storageCache[key]),
            setItem: jest.fn((key, val)=>{
                storageCache[key] = null == val ? void 0 : val;
            })
        }
    };
    mocks.fetch.mockImplementation(()=>Promise.resolve({
            status: 200,
            text: ()=>Promise.resolve('ok'),
            json: ()=>Promise.resolve({
                    status: 'ok'
                })
        }));
    null == setupMocks || setupMocks(mocks);
    return [
        new PostHogCoreTestClient(mocks, apiKey, {
            disableCompression: true,
            ...options
        }),
        mocks
    ];
};
export { PostHogCoreTestClient, createTestClient };
