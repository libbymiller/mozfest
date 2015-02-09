console.log('hello');

var faye = require('faye');

var fs = require('fs');
//var spawn = require('child_process').spawn;
var exec = require('child_process').exec;
var path = require('path');
var Promise = require('es6-promise').Promise;

var http = require('http');

var client = new faye.Client('http://10.0.0.200:9292/faye');

client.subscribe('/foo', handle);

	var print = path.resolve('print');
	console.log('print', print);
// sendPrint(path.resolve('./data/hello'));

function msgContents(msg) {
	return new Promise(function (resolve, reject) {
		// var fileName = 'data-' + Date.now();
		// var filepath = path.resolve('./data/' + fileName);
		// image(msg);
		var output =  JSON.stringify(msg, undefined, 2);
		// console.log(filepath);
		console.log(output);
		resolve(output);
		// fs.writeFileSync(filepath,output);
	    // sendPrint(filepath)
	});
}

function fetchImage(msg) {
	return new Promise(function (resolve, reject) {
		var imagePath = msg.images.split(',')[0];
		var url = 'http://10.0.0.200:7070/' + imagePath;
		console.log('url', url);
		http.get(url, function (res) {
			resolve({ msg: msg, res: res, imagePath: imagePath });
		});
	});
}

function saveImage(obj) {
	return new Promise(function (resolve, reject) {
		var filepath = obj.imagePath;
		var f = fs.createWriteStream(filepath);
		obj.res.on('data', function (chunk) {
			f.write(chunk);
		})
		obj.res.on('end', function () {
			f.end();
			resolve(obj);
		})
	});
}

var jp2a = path.resolve('/usr/bin/jp2a');

function imageToAscii(obj) {
	console.log('imageToAscii', obj.imagePath);
	return new Promise(function (resolve, reject) {
		if (obj.imagePath) {
			exec([jp2a, '--width=80', '-i', obj.imagePath].join(' '), function (err, stdout) {
				if (err) {
					reject(obj);
				} else {
					obj.ascii = stdout;
				}
				resolve(obj);
			});
		} else {
			reject();
		}
	})
}

function failure(e) {
	console.error('failuer', e.stack);
}

function handle(msg) {

	try {
		console.log('msg', typeof msg,  msg);
		var msg = msg[0];

		var msgPromise = msgContents(msg);
		var asciiImagePromise = fetchImage(msg)
								.then(saveImage)
								.then(imageToAscii)
								.catch(failure);

	    Promise.all([msgPromise, asciiImagePromise])
	    		.then(writeFile)
	    		.then(printFile)
	    		.catch(failure);		
	} catch(e) {
		console.error(e.stack);
	}

}


function printFile(obj) {
	console.log('print', arguments);
	console.log('printing', obj.printFile)
//	exec(print, [obj.printFile]);
        var cmnd = "sudo chown pi:pi /dev/usb/lp0; cat "+obj.printFile+"  >  /dev/usb/lp0";
        console.log("command is "+cmnd);
	exec(cmnd);
}

function writeFile(params) {
	var contents = params[0],
		obj = params[1];

	var header = 'MOZFEST 2014\n*** YOUR SOUVENIR FROM THE ETHICAL DILEMMA CAFE ****\n\n';

	console.log('write file', arguments);
	return new Promise(function (resolve, reject) {
		var fileName = 'data-' + Date.now() + '.txt';
		var filepath = path.resolve('./data/' + fileName);
		fs.writeFileSync(filepath, header + contents + '\n\n\n\n' + obj.ascii);
		obj.printFile = filepath;
	    resolve(obj);
	});
}
