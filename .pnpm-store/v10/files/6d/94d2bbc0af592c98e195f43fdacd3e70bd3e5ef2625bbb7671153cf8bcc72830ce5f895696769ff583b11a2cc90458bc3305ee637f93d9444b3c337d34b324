const wait = async (t)=>{
    await new Promise((r)=>setTimeout(r, t));
};
const waitForPromises = async ()=>{
    await new Promise((resolve)=>{
        jest.useRealTimers();
        setTimeout(resolve, 10);
        jest.useFakeTimers();
    });
};
const parseBody = (mockCall)=>{
    const options = mockCall[1];
    expect(options.method).toBe('POST');
    return JSON.parse(options.body || '');
};
const createImperativePromise = ()=>{
    let resolve;
    const promise = new Promise((r)=>{
        resolve = r;
    });
    return [
        promise,
        (val)=>null == resolve ? void 0 : resolve(val)
    ];
};
const delay = (ms)=>new Promise((resolve)=>{
        setTimeout(resolve, ms);
    });
export { createImperativePromise, delay, parseBody, wait, waitForPromises };
