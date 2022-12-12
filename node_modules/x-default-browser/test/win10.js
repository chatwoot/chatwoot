var assert = require('assert')
var detect = require('rewire')('../lib/detect-windows10');

var execResponse = {
    code: 0,
    stdout: "",
    stderr: ""
};

var execStub = function(cmd, cb) {
    cb(execResponse.code, execResponse.stdout, execResponse.stderr);
};

detect.__set__('exec', execStub);

describe("Windows 10 tests", function () {
    beforeEach(function() {
        execResponse.code = 0;
        execResponse.stdout = "";
        execResponse.stderr = "";
    });

    it('detects chrome', function (done) {
        execResponse.stdout = '    ProgId    REG_SZ    ChromeHTML\r\n';

        detect(function(err, res){
            assert.equal(res.isChrome, true);
            assert.equal(res.isChromium, false);
            assert.equal(res.isWebkit, true);
            assert.equal(res.isBlink, true);
            assert.equal(res.commonName, 'chrome');
            done(err);
        });
    });

    it('detects opera', function (done) {
        execResponse.stdout = '    ProgId    REG_SZ    OperaHTML.ZNP4RVJ2ZT4O4SBFSACRM4VZ3U\r\n';

        detect(function(err, res){
            assert.equal(res.isOpera, true);
            assert.equal(res.isChrome, false);
            assert.equal(res.isChromium, false);
            assert.equal(res.isWebkit, true);
            assert.equal(res.isBlink, true);
            assert.equal(res.commonName, 'opera');
            done(err);
        });
    });

    it('detects safari', function (done) {
        execResponse.stdout = '    ProgId    REG_SZ    SafariURL\r\n';

        detect(function(err, res){
            assert.equal(res.isSafari, true);
            assert.equal(res.isChrome, false);
            assert.equal(res.isChromium, false);
            assert.equal(res.isWebkit, true);
            assert.equal(res.isBlink, false);
            assert.equal(res.commonName, 'safari');
            done(err);
        });
    });

    it('detects firefox', function (done) {
        execResponse.stdout = '    ProgId    REG_SZ    FirefoxURL\r\n';

        detect(function(err, res){
            assert.equal(res.isFirefox, true);
            assert.equal(res.isWebkit, false);
            assert.equal(res.commonName, 'firefox');
            done(err);
        });
    });

    it('detects ie', function (done) {
        execResponse.stdout = '    ProgId    REG_SZ    IE.HTTP';

        detect(function(err, res){
            assert.equal(res.isIE, true);
            assert.equal(res.isWebkit, false);
            assert.equal(res.commonName, 'ie');
            done(err);
        });
    });

    it('detects edge', function (done) {
        execResponse.stdout = '    ProgId    REG_SZ    AppXq0fevzme2pys62n3e0fbqa7peapykr8v\r\n';

        detect(function(err, res){
            assert.equal(res.isEdge, true);
            assert.equal(res.isIE, false);
            assert.equal(res.isWebkit, false);
            assert.equal(res.commonName, 'edge');
            done(err);
        });
    });
});
