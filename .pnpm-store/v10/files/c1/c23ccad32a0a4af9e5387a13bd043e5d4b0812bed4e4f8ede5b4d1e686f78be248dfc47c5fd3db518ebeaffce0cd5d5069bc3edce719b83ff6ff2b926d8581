import { SUPPORT_ASYNC, SUPPORT_DOCUMENT, SUPPORT_CACHE, SUPPORT_SERIALIZE, SUPPORT_WORKER, SUPPORT_ENCODER } from "./config.js";
import Document from "./document.js";
import Index from "./index.js";
import WorkerIndex from "./worker/index.js";
import { registerCharset, registerLanguage } from "./global.js";
import charset_default from "./lang/latin/default.js"
import charset_simple from "./lang/latin/simple.js"
import charset_balance from "./lang/latin/balance.js"
import charset_advanced from "./lang/latin/advanced.js"
import charset_extra from "./lang/latin/extra.js"

/** @export */ Document.prototype.add;
/** @export */ Document.prototype.append;
/** @export */ Document.prototype.search;
/** @export */ Document.prototype.update;
/** @export */ Document.prototype.remove;
/** @export */ Document.prototype.contain;
/** @export */ Document.prototype.get;
/** @export */ Document.prototype.set;

/** @export */ Index.prototype.add;
/** @export */ Index.prototype.append;
/** @export */ Index.prototype.search;
/** @export */ Index.prototype.update;
/** @export */ Index.prototype.remove;
/** @export */ Index.prototype.contain;

if(SUPPORT_CACHE){

/** @export */ Index.prototype.searchCache;
/** @export */ Document.prototype.searchCache;
}

if(SUPPORT_ASYNC){

/** @export */ Document.prototype.addAsync;
/** @export */ Document.prototype.appendAsync;
/** @export */ Document.prototype.searchAsync;
/** @export */ Document.prototype.updateAsync;
/** @export */ Document.prototype.removeAsync;

/** @export */ Index.prototype.addAsync;
/** @export */ Index.prototype.appendAsync;
/** @export */ Index.prototype.searchAsync;
/** @export */ Index.prototype.updateAsync;
/** @export */ Index.prototype.removeAsync;
}

if(SUPPORT_SERIALIZE){

/** @export */ Index.prototype.export;
/** @export */ Index.prototype.import;
/** @export */ Document.prototype.export;
/** @export */ Document.prototype.import;
}

if(SUPPORT_ENCODER){

    registerCharset("latin:default", charset_default);
    registerCharset("latin:simple", charset_simple);
    registerCharset("latin:balance", charset_balance);
    registerCharset("latin:advanced", charset_advanced);
    registerCharset("latin:extra", charset_extra);
}

const root = self;
let tmp;

const FlexSearch = {

    "Index": Index,
    "Document": SUPPORT_DOCUMENT ? Document : null,
    "Worker": SUPPORT_WORKER ? WorkerIndex : null,
    "registerCharset": registerCharset,
    "registerLanguage": registerLanguage
};

if((tmp = root["define"]) && tmp["amd"]){

    tmp([], function(){

        return FlexSearch;
    });
}
else if(root["exports"]){

    root["exports"] = FlexSearch;
}
else{

    root["FlexSearch"] = FlexSearch;
}
