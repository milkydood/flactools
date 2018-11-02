#!/usr/bin/nodejs

var exec = require('child_process').exec;
var glob = require('glob');

var encargs = ['flac', '-8', '-s', '-V'];
var wavs = [];

function encone(){
	if (wav = wavs.shift()) {
		console.log('Encoding ' + wav + ' ...');
		exec(encargs.join(' ') + ' ' + wav, function(err, stdout, stderr) {
			if (stderr)  { console.error(stderr); }
			encone();
		});
	}
}

// 'main'
glob( (process.argv[2] || '.') + '/*.wav', function(err, wavlist) {
	wavs = wavlist;
	if (! wavs.length) {
		console.error('No files found to encode');
		process.exit(1);
	}
	exec('grep -c ^processor /proc/cpuinfo' , function(err, cores, stderr) {
		for (i=0; i < cores; i++ ) { encone(); }
	});
})
