Promise = require('bluebird')
fs = Promise.promisifyAll(require('fs'))
MasterBootRecord = require('mbr')

BOOT_RECORD_SIZE = 512

###*
# @summary Read the boot record of an image file
# @protected
# @function
#
# @description It returns a 512 bytes buffer.
#
# @param {String} image - image path
# @param {Number=0} position - byte position
# @returns Promise<Buffer>
#
# @example
#	bootRecord.read('path/to/rpi.img', 0).then (buffer) ->
#		console.log(buffer)
###
exports.read = (image, position = 0) ->
	result = new Buffer(BOOT_RECORD_SIZE)

	fs.openAsync(image, 'r+').then (fd) ->
		return fs.readAsync(fd, result, 0, BOOT_RECORD_SIZE, position).return(fd)
	.then (fd) ->
		return fs.closeAsync(fd)
	.return(result)

###*
# @summary Parse a boot record buffer
# @protected
# @function
#
# @param {Buffer} buffer - mbr buffer
# @returns {Object} the parsed mbr
#
# @example
#	bootRecord.read 'path/to/rpi.img', 0, (error, buffer) ->
#		throw error if error?
#		parsedBootRecord = bootRecord.parse(buffer)
#		console.log(parsedBootRecord)
###
exports.parse = (mbrBuffer) ->
	return new MasterBootRecord(mbrBuffer)

###*
# @summary Get an Extended Boot Record from an offset
# @protected
# @function
#
# @description Attempts to parse the EBR as well.
#
# @param {String} image - image path
# @param {Number} position - byte position
# @returns Promise<Object>
#
# @example
#	bootRecord.getExtended('path/to/rpi.img', 2048).then (ebr) ->
#		console.log(ebr)
###
exports.getExtended = getExtended = (image, position) ->
	exports.read(image, position).then (buffer) ->
		try
			result = exports.parse(buffer)
		catch
			return

		return result

###*
# @summary Get the Master Boot Record from an image
# @protected
# @function
#
# @param {String} image - image path
# @returns Promise<Object>
#
# @example
#	bootRecord.getMaster('path/to/rpi.img').then (mbr) ->
#		console.log(mbr)
###
exports.getMaster = getMaster = (image) ->
	exports.read(image, 0).then(exports.parse)

exports.getAll = (path, offset) ->
	Promise.try ->
		if not offset
			getMaster(path)
		else
			getExtended(path, offset)
	.get('partitions')
	.filter (partition) ->
		partition.type != 0
	.map (partition, i) ->
		if partition.type == 5
			getAll(path, partition.firstLBA * 512)
			.then (parts) ->
				return [ partition ].concat(parts)
			.catch ->
				# there was no ext partition there
				return [ partition ]
		else
			return [ partition ]
	.then (parts) ->
		[].concat(parts...) # flatten
