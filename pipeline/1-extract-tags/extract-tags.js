"use strict";

//
// Modified from:
//
//    https://github.com/matiasdahl/osm-extract-amenities
//

var js_escape = require('js-string-escape');
var _ = require('underscore');
var assert = require('assert');

/**
 *  Error messages
 */

var print_usage_and_exit = function() {
    console.log('Usage: node extract-tags.js [node|way|relation] <osm input-filename>');
    process.exit(1);
};

var fatal_abort = function() {
    console.log('Internal consistency error. Element handler does not receive map elements in sorted order.');
    process.exit(1);
};

/**
 * Read in command line
 */

var element_type = process.argv[2];
if (['node', 'way', 'relation'].indexOf(element_type)<0) print_usage_and_exit();

var filename = process.argv[3];
if (!filename) print_usage_and_exit();

/**
 *  Program output
 */

// Which tags to extract:
var selected_tags = [
             'amenity',
             'barrier', 
		     'building',
		     'highway',
		     'landuse', 
		     'man_made', 
		     'natural', 
		     'railway', 
		     'shop', 
		     'sport',
		     'surface',
		     'tourism'
		     ];

var columns = ['id', 'version', 'visible', 'sec1970', 'pos1', 'pos2'];

console.log(columns.concat(selected_tags).join('\t'));

var escape_tabs = function(str) {
    return str.split('\t').join('\\t');
};

// Escape newlines, remove leading/trailing spaces and enclose the string in quotes.
var cleanup_string = function(str) {
    return str ? escape_tabs(js_escape(str).trim()) : "";
};

// Return array with values for the 'pos1' and 'pos2' columns.
var position = function (map_obj) {
    if (map_obj.type == 'node') {
        return [map_obj.lat, map_obj.lon];
    } else if (map_obj.type == 'way') {
        var pos1 = map_obj.nodes_count > 0 ? map_obj.node_refs(0) : 'NA';
        return [pos1, 'NA'];
    }
    return ['NA', 'NA'];
};

var output = function(map_obj) {
    var out_array = [map_obj.id,
                     map_obj.version,
                     map_obj.visible,
                     map_obj.timestamp_seconds_since_epoch,
                     position(map_obj).join('\t')];

    var extract_tag = function(tag) {
	  	return (map_obj.tags())[tag];
    };

    var out_tags = selected_tags.map(extract_tag);
    
    console.log(out_array.concat(out_tags).join('\t'));
};

/**
 *  The logic in the object handler will not work if the elements do not
 *  arrive ordered by 'id' and 'version':
 *
 *  When a new element arrive, its relation to the previous should satisfy:
 *  previous.id <= new.id and if previous.id = new.id, then
 *  previous.version < new.version. In practice, data exports seem
 *  to order the elements in the above way. However, I was unable to find
 *  a documentation for this. The script will abort if the above condition
 *  is not true.
 *
 */

var last_id = -1;
var last_version = -1;

var assert_order = function(new_obj) {
    if (new_obj.id < last_id) {
        fatal_abort();
    } else if (new_obj.id == last_id) {
        if (new_obj.version <= last_version) {
            fatal_abort();
        }
    }
    last_id = new_obj.id;
    last_version = new_obj.version;
};

/**
 *  Main part. Handle map elements.
 */

var osmium = require('osmium');
var reader = new osmium.Reader(filename);
var handler = new osmium.Handler();

var kl_intersect = function(l1, dict) {
	return l1.map(function(k) { return k in dict })
	         .some(function(x) { return (x === true) });
}

////

var k = {'a':1, 'b': 2, 'c': 3}
assert(kl_intersect([], k) == false)
assert(kl_intersect(['x', 'xx', 'y'], k) == false)
assert(kl_intersect(['x', 'xx', 'b'], k) == true)
assert(kl_intersect(['x', 'c', 'y'], k) == true)

////

var last_id_of_interest = -1;

var object_handler = function(map_obj) {
    assert_order(map_obj);

    if (last_id_of_interest !== map_obj.id) {
        // Unseen element id.
        if (!kl_intersect(selected_tags, map_obj.tags())) return;
        // Element is tagged as one of the selected tags. Remember its id 
        // and output all future versions.
        last_id_of_interest = map_obj.id;
    }
    output(map_obj);
};

handler.on(element_type, object_handler);
osmium.apply(reader, handler);
