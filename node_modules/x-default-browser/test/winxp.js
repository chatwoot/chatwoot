var assert = require('assert')
var detect = require('rewire')('../lib/detect-windows');

var execResponse = {
    code: 0,
    stdout: "",
    stderr: ""
};

var execStub = function(cmd, cb) {
    cb(execResponse.code, execResponse.stdout, execResponse.stderr);
};

detect.__set__('exec', execStub);

describe("Windows XP tests", function () {
    beforeEach(function() {
        execResponse.code = 0;
        execResponse.stdout = "";
        execResponse.stderr = "";
    });

    it('detects chrome', function (done) {
        execResponse.stdout = '    <NO NAME>	REG_SZ	Google Chrome';

        detect(function(err, res){
            assert.equal(res.isChrome, true);
            assert.equal(res.isChromium, false);
            assert.equal(res.isWebkit, true);
            assert.equal(res.commonName, 'chrome');
            assert.equal(res.identity, 'google chrome');
            done(err);
        });
    });

    it('detects chromium', function (done) {
        execResponse.stdout = '    <NO NAME>	REG_SZ	Chromium.4FBATGJXTE7MCNSOMJSKZZMNLU';

        detect(function(err, res){
            assert.equal(res.isChrome, false);
            assert.equal(res.isChromium, true);
            assert.equal(res.isWebkit, true);
            assert.equal(res.commonName, 'chromium');
            assert.equal(res.identity, 'chromium.4fbatgjxte7mcnsomjskzzmnlu');
            done(err);
        });
    });

    it('detects firefox', function (done) {
        execResponse.stdout = '    <NO NAME>	REG_SZ	FIREFOX.EXE';

        detect(function(err, res){
            assert.equal(res.isFirefox, true);
            assert.equal(res.isWebkit, false);
            assert.equal(res.commonName, 'firefox');
            assert.equal(res.identity, 'firefox.exe');
            done(err);
        });
    });

    it('detects ie', function (done) {
        execResponse.code = 1;

        detect(function(err, res){
            assert.equal(res.isIE, true);
            assert.equal(res.isWebkit, false);
            assert.equal(res.commonName, 'ie');
            assert.equal(res.identity, 'iexplore.exe');
            done(err);
        });
    });
});
