var iframe;
if (iframe === undefined) {
    iframe = document.createElement('iframe');
    iframe.style.display = 'none';
    document.body.appendChild(iframe);
    console = {
        log: function(objects) {
            this._log('LOG', objects);
        },
        warn: function(objects) {
            this._log('WARN', objects);
        },
        error: function(objects) {
            this._log('ERROR', objects);
        },
        debug: function(objects) {
            this._log('DEBUG', objects);
        },
        info: function(objects) {
            this._log('INFO', objects);
        },
        _log: function(level, objects) {
            this._logs.push(level + ' ' + objects);
            iframe.src = 'clien:log';
        },
        _logs: []
    };
}

var a = document.getElementsByTagName('x');
console.log(a);
for (var i = 0; i < a.length; ++i) {
    var width = parseInt(document.defaultView.getComputedStyle(a[i], null)['width']);
    console.log(i + ': ' + width);
    if (width > 300) {
        a[i].style.width = '300px';
    }
}
