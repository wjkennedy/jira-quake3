
  var Module = typeof Module != 'undefined' ? Module : {};

  if (!Module['expectedDataFileDownloads']) Module['expectedDataFileDownloads'] = 0;
  Module['expectedDataFileDownloads']++;
  (() => {
    // Do not attempt to redownload the virtual filesystem data when in a pthread or a Wasm Worker context.
    var isPthread = typeof ENVIRONMENT_IS_PTHREAD != 'undefined' && ENVIRONMENT_IS_PTHREAD;
    var isWasmWorker = typeof ENVIRONMENT_IS_WASM_WORKER != 'undefined' && ENVIRONMENT_IS_WASM_WORKER;
    if (isPthread || isWasmWorker) return;
    var isNode = globalThis.process && globalThis.process.versions && globalThis.process.versions.node && globalThis.process.type != 'renderer';
    async function loadPackage(metadata) {

      var PACKAGE_PATH = '';
      if (typeof window === 'object') {
        PACKAGE_PATH = window['encodeURIComponent'](window.location.pathname.substring(0, window.location.pathname.lastIndexOf('/')) + '/');
      } else if (typeof process === 'undefined' && typeof location !== 'undefined') {
        // web worker
        PACKAGE_PATH = encodeURIComponent(location.pathname.substring(0, location.pathname.lastIndexOf('/')) + '/');
      }
      var PACKAGE_NAME = 'dosbox_fs.data';
      var REMOTE_PACKAGE_BASE = 'dosbox_fs.data';
      var REMOTE_PACKAGE_NAME = Module['locateFile'] ? Module['locateFile'](REMOTE_PACKAGE_BASE, '') : REMOTE_PACKAGE_BASE;
      var REMOTE_PACKAGE_SIZE = metadata['remote_package_size'];

      async function fetchRemotePackage(packageName, packageSize) {
        if (isNode) {
          var contents = require('fs').readFileSync(packageName);
          return new Uint8Array(contents).buffer;
        }
        if (!Module['dataFileDownloads']) Module['dataFileDownloads'] = {};
        try {
          var response = await fetch(packageName);
        } catch (e) {
          throw new Error(`Network Error: ${packageName}`, {e});
        }
        if (!response.ok) {
          throw new Error(`${response.status}: ${response.url}`);
        }

        const chunks = [];
        const headers = response.headers;
        const total = Number(headers.get('Content-Length') || packageSize);
        let loaded = 0;

        Module['setStatus'] && Module['setStatus']('Downloading data...');
        const reader = response.body.getReader();

        while (1) {
          var {done, value} = await reader.read();
          if (done) break;
          chunks.push(value);
          loaded += value.length;
          Module['dataFileDownloads'][packageName] = {loaded, total};

          let totalLoaded = 0;
          let totalSize = 0;

          for (const download of Object.values(Module['dataFileDownloads'])) {
            totalLoaded += download.loaded;
            totalSize += download.total;
          }

          Module['setStatus'] && Module['setStatus'](`Downloading data... (${totalLoaded}/${totalSize})`);
        }

        const packageData = new Uint8Array(chunks.map((c) => c.length).reduce((a, b) => a + b, 0));
        let offset = 0;
        for (const chunk of chunks) {
          packageData.set(chunk, offset);
          offset += chunk.length;
        }
        return packageData.buffer;
      }

      var fetchPromise;
      var fetched = Module['getPreloadedPackage'] && Module['getPreloadedPackage'](REMOTE_PACKAGE_NAME, REMOTE_PACKAGE_SIZE);

      if (!fetched) {
        // Note that we don't use await here because we want to execute the
        // the rest of this function immediately.
        fetchPromise = fetchRemotePackage(REMOTE_PACKAGE_NAME, REMOTE_PACKAGE_SIZE);
      }

    async function runWithFS(Module) {

      function assert(check, msg) {
        if (!check) throw new Error(msg);
      }
Module['FS_createPath']("/", "C", true, true);

    for (var file of metadata['files']) {
      var name = file['filename']
      Module['addRunDependency'](`fp ${name}`);
    }

      async function processPackageData(arrayBuffer) {
        assert(arrayBuffer, 'Loading data file failed.');
        assert(arrayBuffer.constructor.name === ArrayBuffer.name, 'bad input to processPackageData ' + arrayBuffer.constructor.name);
        var byteArray = new Uint8Array(arrayBuffer);
        var curr;
        // Reuse the bytearray from the XHR as the source for file reads.
          for (var file of metadata['files']) {
            var name = file['filename'];
            var data = byteArray.subarray(file['start'], file['end']);
            // canOwn this data in the filesystem, it is a slice into the heap that will never change
        Module['FS_createDataFile'](name, null, data, true, true, true);
        Module['removeRunDependency'](`fp ${name}`);
          }
          Module['removeRunDependency']('datafile_dosbox_fs.data');
      }
      Module['addRunDependency']('datafile_dosbox_fs.data');

      if (!Module['preloadResults']) Module['preloadResults'] = {};

      Module['preloadResults'][PACKAGE_NAME] = {fromCache: false};
      if (!fetched) {
        fetched = await fetchPromise;
      }
      processPackageData(fetched);

    }
    if (Module['calledRun']) {
      runWithFS(Module);
    } else {
      if (!Module['preRun']) Module['preRun'] = [];
      Module['preRun'].push(runWithFS); // FS is not initialized yet, wait for it
    }

    }
    loadPackage({"files": [{"filename": "/C/123.CNF", "start": 0, "end": 203}, {"filename": "/C/123.EXE", "start": 203, "end": 18571}, {"filename": "/C/123.LLD", "start": 18571, "end": 34990}, {"filename": "/C/123.SET", "start": 34990, "end": 66894}, {"filename": "/C/123.ZIP", "start": 66894, "end": 195976}, {"filename": "/C/123HLP.ZIP", "start": 195976, "end": 556193}, {"filename": "/C/123HLP2.ZIP", "start": 556193, "end": 760984}, {"filename": "/C/ADDINS.ZIP", "start": 760984, "end": 827545}, {"filename": "/C/ADDINS2.ZIP", "start": 827545, "end": 847217}, {"filename": "/C/COPYING", "start": 847217, "end": 865212}, {"filename": "/C/INSDSK24.RI", "start": 865212, "end": 868322}, {"filename": "/C/INSTALL", "start": 868322, "end": 872323}, {"filename": "/C/INSTALL.EXE", "start": 872323, "end": 977460}, {"filename": "/C/INSTALL.ZIP", "start": 977460, "end": 1030713}, {"filename": "/C/INSTXT24.RI", "start": 1030713, "end": 1061172}, {"filename": "/C/LEARNWYS.ZIP", "start": 1061172, "end": 1103671}, {"filename": "/C/LIBRARY.ZIP", "start": 1103671, "end": 1335066}, {"filename": "/C/LOTUS.ZIP", "start": 1335066, "end": 1399655}, {"filename": "/C/LOTUS2.ZIP", "start": 1399655, "end": 1411803}, {"filename": "/C/PGRAPH.ZIP", "start": 1411803, "end": 1525308}, {"filename": "/C/PKUNZIP.EXE", "start": 1525308, "end": 1548836}, {"filename": "/C/README.md", "start": 1548836, "end": 1557473}, {"filename": "/C/SERIAL.DAT", "start": 1557473, "end": 1557489}, {"filename": "/C/SMRTICON.ZIP", "start": 1557489, "end": 1586122}, {"filename": "/C/THANKS", "start": 1586122, "end": 1587094}, {"filename": "/C/TRANS.ZIP", "start": 1587094, "end": 1851486}, {"filename": "/C/TUTOR.ZIP", "start": 1851486, "end": 1853599}, {"filename": "/C/TUTOR1.ZIP", "start": 1853599, "end": 2172864}, {"filename": "/C/WYSCLIP.ZIP", "start": 2172864, "end": 2198397}, {"filename": "/C/WYSCLIP1.ZIP", "start": 2198397, "end": 2204288}, {"filename": "/C/WYSCLIP2.ZIP", "start": 2204288, "end": 2218801}, {"filename": "/C/WYSCLIP3.ZIP", "start": 2218801, "end": 2235536}, {"filename": "/C/WYSCLIP4.ZIP", "start": 2235536, "end": 2274009}, {"filename": "/C/WYSCLIP5.ZIP", "start": 2274009, "end": 2296403}, {"filename": "/C/WYSGO1.ZIP", "start": 2296403, "end": 2461143}, {"filename": "/C/WYSGO2.ZIP", "start": 2461143, "end": 2577921}, {"filename": "/C/WYSGO3.ZIP", "start": 2577921, "end": 2590643}, {"filename": "/C/WYSIFL.ZIP", "start": 2590643, "end": 2820819}, {"filename": "/C/WYSIWYG.ZIP", "start": 2820819, "end": 2996409}, {"filename": "/C/WYSSUB.ZIP", "start": 2996409, "end": 3165452}, {"filename": "/C/ZAP.EXE", "start": 3165452, "end": 3173645}, {"filename": "/C/lotus_disks.zip", "start": 3173645, "end": 3173645}, {"filename": "/autoexec.bat", "start": 3173645, "end": 3173915}], "remote_package_size": 3173915});

  })();
