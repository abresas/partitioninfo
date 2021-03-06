var Promise, partition;

Promise = require('bluebird');

partition = require('./partition');


/**
 * @module partitioninfo
 */


/**
 * @summary Get information from a partition
 * @public
 * @function
 *
 * @param {String} image - image path
 * @param {Object} definition - partition definition
 * @param {Number} definition.primary - primary partition
 * @param {Number} [definition.logical] - logical partition
 *
 * @returns {Promise<Object>} partition information
 *
 * @example
 * partitioninfo.get 'foo/bar.img',
 * 	primary: 4
 * 	logical: 1
 * .then (information) ->
 * 	console.log(information.offset)
 * 	console.log(information.size)
 */

exports.get = function(image, definition) {
  return partition.getPartitionFromDefinition(image, definition).then(function(parsedPartition) {
    return Promise.props({
      offset: partition.getPartitionOffset(parsedPartition),
      size: partition.getPartitionSize(parsedPartition)
    });
  });
};
