
(function(){

/*
	SOME ASCII ART DESCRIBING VIEWS

	SINGLE AppView (contains functionality to create new message)
		SINGLE MessageListView(top level only)
			MANY MessageAndRepliesView
				MessageRootView (edit and display the main message + associated media)
				CommentsView (each comments view contains another comments view along with a reply box at the bottom)
					- CommentsView
					- MessageReplyView

Comments View Details

Comment 1
	reply 1
		input for new reply again
	reply 2
		input for new reply again
	input for new reply
Comment 2
	input for new reply
input for new comment

*/
if(!_.isFunction(Number.prototype.fileSize)) {
	// extend Number to get fileSize out of it.
	Object.defineProperty(Number.prototype,'fileSize',{value:function(a,b,c,d){
	 return (a=a?[1e3,'k','B']:[1024,'K','iB'],b=Math,c=b.log,
	 d=c(this)/c(a[0])|0,this/b.pow(a[0],d)).toFixed(2)
	 +' '+(d?(a[1]+'MGTPEZY')[--d]+a[2]:'Bytes');
	},writable:false,enumerable:false});
}

this.initMessagingApp = function(view, node) {
  var p = jQuery.Deferred(),
      renderDeferred = jQuery.Deferred();
  view.on("render", function() {
    renderDeferred.resolve();
  });
  if(window.App) {
    App.init(p, view, node, renderDeferred);
  } else {
    jQuery.ajax({
      url: node.collection.get('site').get('cable_js_url'),
      dataType: 'script',
      cache: true
    }).done(function(script, textStatus){
      App.init(p, view, node, renderDeferred);
    })
    .fail(function(jqhxr, settings, exception){
      // FIXME update these errors etc...
      p.reject('Failed to fetch ActionCable script');
    });
  }
  return p.promise();
};

var isAdvancedUpload = function() {
	// DISABLE advanced drag and drop upload
	return false;
		// var div = document.createElement( 'div' );
		// return ( ( 'draggable' in div ) || ( 'ondragstart' in div && 'ondrop' in div ) ) && 'FormData' in window && 'FileReader' in window;
},
showConfirm = function(message, confirmCallback, title, buttonLabels) {
            if (((_ref = window.navigator) != null ? (_ref1 = _ref.notification) != null ? _ref1.confirm : void 0 : void 0) != null) {
                window.navigator.notification.confirm(message, confirmCallback, title, buttonLabels);
            } else {
                confirmCallback.call(this, (confirm(message) ? 1 : 2));
            }
        },
 _superClass = Backbone.Model.prototype,
 _syncMethodForModels = {
	sync: function() {
      return Backbone.ajaxSync.apply(this, arguments);
	}
},
AbstractModel = Backbone.Model.extend(_syncMethodForModels).extend({
	destroy: function(options) {
		options = options || {};
		if(this.collection) {
			options.contentType = 'application/json';
			options.data = JSON.stringify({client_guid: (this.collection && this.collection.client_guid)});
		}
		// super call
		return Backbone.Model.prototype.destroy.call(this, options);
	}
}),
AbstractCollection = Backbone.Collection.extend(_syncMethodForModels),
BackboneModelFileUpload = Backbone.Model.extend({

    // ! Default file attribute - can be overwritten
    fileAttribute: 'file',

    // @ Save - overwritten
    save: function(key, val, options) {

      // Variables
      var attrs, attributes = this.attributes,
          that = this;

      // Signature parsing - taken directly from original Backbone.Model.save
      // and it states: 'Handle both "key", value and {key: value} -style arguments.'
      if (key == null || typeof key === 'object') {
        attrs = key;
        options = val;
      } else {
        (attrs = {})[key] = val;
      }

      // Validate & wait options - taken directly from original Backbone.Model.save
      options = _.extend({validate: true}, options);
      if (attrs && !options.wait) {
        if (!this.set(attrs, options)) return false;
      } else {
        if (!this._validate(attrs, options)) return false;
      }

      // Merge data temporarily for formdata
      var mergedAttrs = _.extend({}, attributes, attrs);

      if (attrs && options.wait) {
        this.attributes = mergedAttrs;
      }

      // Check for "formData" flag and check for if file exist.
      if ( options.formData === true
        || options.formData !== false
        && mergedAttrs[ this.fileAttribute ]
        && mergedAttrs[ this.fileAttribute ] instanceof File
        || mergedAttrs[ this.fileAttribute ] instanceof FileList
        || mergedAttrs[ this.fileAttribute ] instanceof Blob ) {

        // Flatten Attributes reapplying File Object
        var formAttrs = _.clone( mergedAttrs ),
          fileAttr = mergedAttrs[ this.fileAttribute ];
        formAttrs = this._flatten( formAttrs );
        formAttrs[ this.fileAttribute ] = fileAttr;

        // Converting Attributes to Form Data
        var formData = new FormData();
        _.each( formAttrs, function( value, key ){
          if (value instanceof FileList || (key === that.fileAttribute && value instanceof Array)) {
            _.each(value, function(file) {
              formData.append( key, file );
            });
          }
          else {
            formData.append( key, value );
          }
        });

        // Set options for AJAX call
        options.data = formData;
        options.processData = false;
        options.contentType = false;

        // Handle "progress" events
        if (!options.xhr) {
          options.xhr = function(){
            var xhr = Backbone.$.ajaxSettings.xhr();
            xhr.upload.addEventListener('progress', _.bind(that._progressHandler, that), false);
            return xhr
          }
        }
      }

      // Resume back to original state
      if (attrs && options.wait) this.attributes = attributes;

      // Continue to call the existing "save" method
      return _superClass.save.call(this, attrs, options);

    },

    // _ FlattenObject gist by "penguinboy".  Thank You!
    // https://gist.github.com/penguinboy/762197
    // NOTE for those who use "<1.0.0".  The notation changed to nested brackets
    _flatten: function flatten( obj ) {
      var output = {};
      for (var i in obj) {
        if (!obj.hasOwnProperty(i)) continue;
        if (typeof obj[i] == 'object') {
          var flatObject = flatten(obj[i]);
          for (var x in flatObject) {
            if (!flatObject.hasOwnProperty(x)) continue;
            output[i + '[' + x + ']'] = flatObject[x];
          }
        } else {
          output[i] = obj[i];
        }
      }
      return output;

    },

    // An "Unflatten" tool which is something normally should be on the backend
    // But this is a guide to how you would unflatten the object
    _unflatten: function unflatten(obj, output) {
      var re = /^([^\[\]]+)\[(.+)\]$/g;
      output = output || {};
      for (var key in obj) {
        var value = obj[key];
        if (!key.toString().match(re)) {
          var tempOut = {};
          tempOut[key] = value;
          _.extend(output, tempOut);
        } else {
          var keys = _.compact(key.split(re)), tempOut = {};
          tempOut[keys[1]] = value;
          output[keys[0]] = unflatten( tempOut, output[keys[0]] )
        }
      }
      return output;
    },

    // _ Get the Progress of the uploading file
    _progressHandler: function( event ) {
      if (event.lengthComputable) {
        var percentComplete = event.loaded / event.total;
        this.trigger( 'progress', percentComplete, event.loaded, event.total);
      }
    }
  }),
// a user model to demo with
User = Backbone.Model.extend({
	// demo user
	constructor: function(attrs, options) {
		options = options || {};
		this.node = options.node;
		Backbone.Model.apply(this, arguments);
	},
	defaults: function() {
		var data = {
			avatar_url: "https://www.iconexperience.com/_img/o_collection_png/green_dark_grey/512x512/plain/user.png",
			display_name: "Unknown"
		}, node = this.node;

		if(node) {
			var user = node.collection.get('user');
			if(!user) {
				user = node.collection.get('client');
			}
			data = {
				display_name: user.get('display_name'),
				avatar_url: user.get('avatar_url')
			}
		}
		return data;
	}
}),
Message = AbstractModel.extend({
	defaults: {
		id: null,
		node_id: null, // get nodeid from page??? this shold be passed into the views somehow.
		title: '',
		message: '',
		sent: false,
		draft: false,
		push_notifiation: false,
		parent_id: null,
		message_view_permission: [],
		message_reply_permission: [],
		message_reply_view_permission: [],
		valid_from_set: true,
		valid_to_set: true,
		can_update: true,
		can_destroy: true,
		can_reply: true
	},
	initialize: function(attributes, options){
		options = options || {}
		// setup replies
		// this.replies = new Messages();
		if(!attributes.updated_at) {
			this.set({updated_at: new Date()});
		}
		if(!attributes.created_at) {
			this.set({created_at: new Date()});
		}
		var node = options.node || this.collection.node;
		this.client_guid = options.client_guid || this.collection.client_guid
		if(node) {
			if(!attributes.owner) {
				this.set('owner', new User({},{node: node}));
			}
			// bind to this.files for convience.
			this.files = new Files([], {message: this, node: node, client_guid: this.client_guid});
			this.updateAttachments();
			this.on("change:attachments", this.updateAttachments, this);

			if(!attributes.node_id) {
				this.set({node_id: node.get('_id')});
			}
			// setup reply view permission by default to include "Owner"
			// not an array of length == 0
			if(!_.isArray(attributes.message_reply_view_permission) || attributes.message_reply_view_permission.length == 0) {
				this.set({
					message_reply_view_permission: _.chain(node.get('message_reply_view_permission'))
														.filter(function(p){ return p.class_name == 'AppGroup::Owner';})
														.map(function(p){ return p.id}).value()
				});
			}
		}
		this.listenTo(this, 'remove', this.removeAttachmentsIfNotSaved)
	},
	updateAttachments: function() {
		this.files.update(this.get('attachments'), {parse: true})
	},
	removeAttachmentsIfNotSaved: function() {
		if(this.isNew()) {
			this.files.each(function(file){
				console.log("REMOVING MODEL", file);
				file.destroy();
			});
		}
	},
	addFiles: function(files) {
		this.files.addFiles(files);
	},
	timeAgo: function() {
		return jQuery.timeago(this.get('updated_at'));
	},
	ownerName: function() {
		return this.get('owner').get('display_name');
	},
	ownerAvatarUrl: function() {
		return this.get('owner').get('avatar_url');
	},
	getHtml: function(key) {
		return _.escape(this.get(key));
	},
	validate: function(attrs, options) {
		options || (options = {});
		if(!options.validate) {
			return false;
		}
		var errors = false,
			e = function(name, value) {
				if(!_.isObject(errors)) { errors = {}; };
				if(!_.isArray(errors[name])) { errors[name] = []; };
				errors[name].push(value);
			},
			// return TRUE if string is OK
			checkStr = function(str){
				return _.isString(str) && str.trim().length > 0;
			},
			checkArray = function(array) {
				return _.isArray(array) && array.length > 0;
			},
			checkBoolean = function(boolean) {
				return _.isBoolean(boolean);
			};
		
		// make sure node_id is always set
		_.isNumber(attrs.node_id) || e('message', 'A message can not be saved without a associated node');

		if(!attrs.draft) {
			// if is a ROOT message we require a title
			if(!attrs.parent_id) {
				checkStr(attrs.title) || e('title', 'A Topic for this message is required.');
				_.each({'message_view_permission':'Who can see message'},function(label, name){
					checkArray(attrs[name]) || e(name, `Permission ${label} is empty`);
				}, this);
				_.each(['valid_to','valid_from'],function(name){
					_.isBoolean(attrs[`${name}_set`]) || e(`${name}_set`,"should be a boolean value only");
					if(!attrs[`${name}_set`]) {
						_.isDate(attrs[name]) || e(name,"A time is required");
					}
				});
				if(_.isDate(attrs.valid_to) && (attrs.valid_to < new Date())) {
					e('valid_to', "Expiry time should be in the future.");
				}
				if(_.isDate(attrs.valid_from) && (attrs.valid_from < new Date())) {
					e('valid_from', "Send time should be in the future.");
				}
				if(_.isDate(attrs.valid_to) && _.isDate(attrs.valid_from) && attrs.valid_to < attrs.valid_from) {
					e('valid_to', "Expiry time should be greater than Sending time");
				}
				_.isBoolean(attrs.push_notifiation) || e('push_notifiation',"should be a boolean value only");
				checkStr(attrs.message_category_id) || e('message_category_id', "a message category is required");
			}
			checkStr(attrs.message) || e('message', 'A body this for this message is required');
		}
		return errors;
	},
	buildReply: function() {
		var model = new this.constructor({
				parent_id: this.get('id'),
				node_id: this.get('node_id'),
				draft: true
			}, {node: this.collection.node, collection: this.collection});
		model._parent = this;
		model.collection = this.collection;
		return model;
	},
	parent: function() {
		if(this._parent) {
			return this._parent;
		}
		if(!this.collection) {
			return;
		}
		return this.collection.get(this.get('parent_id'));
	},
	levelName: function() {
		return this.constructor.MESSAGE_LEVELS[this.depth()] || "Message";
	},
	depth: function() {
		var parent = this.parent();
		if(!this.parent()) {
			return 0;
		} else {
			return this.parent().depth() + 1;
		}
	},
	canReply: function() {
		return (this.depth() < 2) && this.get("can_reply");
	},
	canDelete: function() {
		return this.get("can_destroy");
	},
	canEdit: function() {
		return this.get("can_update");
	},
	parse: function(resp) {
		// do the inverse of parse
		var specialKeys = _.flatten([this.constructor.ROOT_KEYS, this.constructor.SERVER_KEYS]);
		var json = _.pick(resp, specialKeys);
		// setup valid_to_set and valid_from_set
		_.each(['valid_to', 'valid_from'], function(dateType){
			var date = null;
			if(_.isString(json[dateType])) {
				var dateAsNumber = Date.parse(json[dateType]);
				if(dateAsNumber!=null) {
					date = new Date(dateAsNumber);
				}
			}
			json[dateType] = date;
			json[`${dateType}_set`] = (date == null);
		});
		json.updated_at = new Date(Date.parse(json.updated_at));
		json.created_at = new Date(Date.parse(json.created_at));
		json.owner = new User(resp.owner);
		// should be clean to default onto the response
		return _.defaults(json,_.omit(resp['message'],_.flatten([specialKeys,this.constructor.IGNORE_KEYS])));

	},
	toJSON: function() {
		// serialize this model for json
		var json = _.pick(this.attributes, this.constructor.ROOT_KEYS);
		if(this.get('valid_from_set')) {
			json.valid_from = null;
		}
		if(this.get('valid_to_set')) {
			json.valid_to = null;
		}
		// place the rest of the keys onto message property
		json['message'] = _.omit(this.attributes, _.flatten([this.constructor.ROOT_KEYS, this.constructor.IGNORE_KEYS, this.constructor.SERVER_KEYS]));
		// wrap paramater for rails
		json['attachment_ids'] = this.files.pluck('id');
		return {client_guid: (this.collection && this.collection.client_guid), message: json};
	}
},{
	MESSAGE_LEVELS: {
		0: "Message",
		1: "Comment",
		2: "Reply"
	},
	PERMISSION_NAMES: {
		'message_view_permission':'Who can see message',
		'message_reply_permission':'Who can reply',
		'message_reply_view_permission':'Who can see replies'
	},
	LABELS: {
		valid_from_set: 'Send now?',
		valid_from: 'Send at:',
		valid_to_set: 'Never expires?',
		valid_to: 'Expires at:'
	},
	ROOT_KEYS: ['message_category_id', 'parent_id', 'push_notifiation', 'valid_from', 'valid_to','message_view_permission', 'message_reply_permission', 'message_reply_view_permission'],
	IGNORE_KEYS: ['editing', 'valid_from_set', 'valid_to_set','sent','draft','owner'],
	SERVER_KEYS: ['id', 'updated_at', 'created_at', 'node_id', 'can_update', 'can_destroy', 'can_reply', 'attachments']
}),
Messages = AbstractCollection.extend({
	model: Message,
	getuuid: function() {
		// simple proxy onto the node
		return this.node.collection.getuuid();
	},
	initialize: function(models, options) {
		options = options || {}
		this.node = options.node;
		this.client_guid = lib.utils.guid();
		this.on('change:updated_at', this.sort, this);
	},
	url: function() {
		return `${this.node.collection.url()}/node/${this.node.get('_id')}/messages`;
	},
	unsaved: function() {
		return this.where({id: null});
	},
	comparator: function(a,b) {
		return b.get('updated_at').getTime() - a.get('updated_at').getTime();
	}	
	// sync: function(method, model, options) {
	// 	console.log("MESSAGES.SYNC", method, model, options);
	// }
}),
AWSS3File = BackboneModelFileUpload.extend({
	defaults: {
		"Content-Type": ''
	},
	initialize: function(attrs,options) {
		// fix up url and options
		// this.aws_signing_info = options.node.get('aws_signing_info');
		// this.set(this.aws_signing_info.form_values);
		// this.url = this.aws_signing_info.url;
		this.file = options.file;
		this.listenTo(this, 'change:file', this.setupThumbnailContentType);
		this.listenTo(this.file, 'change:form_values change:max_file_size change:min_file_size change:upload_url', this.updateFormValues);
	},
	aws_signing_info: {
		min_size: 1,
		max_size: 524288000 // 500MB
	},
	// this is the method to upload a file to aws s3
	url: null,
	fileAttribute: 'file',
	updateFormValues: function() {
		this.url = this.file.get('upload_url');
		this.aws_signing_info = {
			min_size: this.file.get('min_file_size'),
			max_size: this.file.get('max_file_size'),
		};
		// set the rest of the values
		this.set(this.file.get('form_values'));
	},
	setupThumbnailContentType: function(model, file) {

		if(this.isImage()) {
			var reader = new FileReader()
			_this = this;
			reader.onload = function() {
				_this.file.set({thumb_url: this.result});
			};
			reader.readAsDataURL(this.get('file'));
		} else if(this.isVideo()) {
			this.file.set({thumb_url: "https://d30y9cdsu7xlg0.cloudfront.net/png/565458-200.png" })
		}
	},
	parse: function(resp) {
		var $xml = $(resp),
			result = {};
		$xml.find("PostResponse > *").each(function(idx, e){
			result[e.nodeName.toLowerCase()] = e.textContent;
		});
		return result;
	},
	abort: function() {
		// abort an in progress event
		if(this.xhr) {
			this.aborted = true;
			this.xhr.abort("Upload cancelled");
		}
	},
	setFileName: function(name) {
		this.fileName = name;
	},
	validate: function(attrs, options) {
		options || (options = {});
		if(!options.validate) {
			return false;
		}
		var errors = false,
			e = function(name, value) {
				if(!_.isObject(errors)) { errors = {}; };
				if(!_.isArray(errors[name])) { errors[name] = []; };
				errors[name].push(value);
			},
		file = attrs[this.fileAttribute];
		if(!file) {
			e('file', 'A file is required to upload');
		} else {
			if(!_.contains(_.keys(this.constructor.MIME_TYPE_MAP), attrs['Content-Type'])) {
				// failing this try the filename and reset
				var extension = file.name.replace(/^.*\./, '').toLowerCase(), foundMimeType = false;
				_.each(this.constructor.MIME_TYPE_MAP, function(value, key, list){
					if(_.contains(value, extension)) {
						this.set({'Content-Type':key});
						foundMimeType = true;
						return false
					}
					return true;
				}, this);
				foundMimeType || e('file', `File type is invalid only image and video types are allowed.`);
			}
			if(file.size < this.aws_signing_info.min_size) {
				e('file', `File is too small at ${file.size.fileSize()} minimum size is ${this.aws_signing_info.min_size.fileSize()}`)
			}
			if(file.size > this.aws_signing_info.max_size) {
				e('file', `File is too large at ${file.size.fileSize()}, Maximum size allowed is ${this.aws_signing_info.max_size.fileSize()}`)
			}
		}
		//policy expiry check?
		this.previousError = errors;

		return errors;
	},
	isImage: function() {
		return this.get('Content-Type').startsWith('image/');
	},
	isVideo: function() {
		return this.get('Content-Type').startsWith('video/');
	},
	save: function() {
		var attrs = _.clone(this.attributes);
		attrs.key = attrs.key.replace('${filename}',this.fileName);
		this.constructor.__super__.save.call(this, attrs)
	},
	// force datatype to be XML
	sync: function(method, model, options) {
		this.previousError = false;
		this.aborted = false;
		options = options || {}
		options.dataType = "xml";
		this.xhr = Backbone.sync.call(this, method, model, options);
		return this.xhr;
		// if(method=="create") {
		// 	// give this model a FAKE ID for now
		// 	model.set({id: _.uniqueId('file_')});
		// }
		// model.set({updated_at: new Date()});
	}
	// on posting we need to set the other values correct for s3 here
},{
	MIME_TYPE_MAP: {
		"video/mp4": ["mp4", "m4v"],
		"video/ogg": ["ogg"],
		"video/webm": ["webm"],
		"image/gif": ["gif"],
		"image/jpeg": ["jpg", "jpeg"],
		"image/png": ["png"],
		"video/x-flv": ["flv"],
		"video/3gpp": ["3gp"],
		"video/avi" : ["avi"],
		"video/x-matroska" : ["mkv"],
		"video/quicktime": ["mov"],
		"video/x-ms-wmv": ["wmv"],
		"video/MP2T": ["ts"]
	},
	inferTypeFromName: function(name) {
		var extension = name.replace(/^.*\./, '').toLowerCase(),
			foundMimeType = false;
		_.each(this.MIME_TYPE_MAP, function(value, key, list){
			if(_.contains(value, extension)) {
				foundMimeType = key;
				return false;
			}
			return true;
		}, this);
		return foundMimeType;
	}

}),
File = AbstractModel.extend({
	defaults: {
	},
	// this is the method to send the details of the uploaded file to s3 to our server
	// sync: function(method, model, options) {
	// 	if(method=="create") {
	// 		// give this model a FAKE ID for now
	// 		model.set({id: _.uniqueId('file_')});
	// 	}
	// 	model.set({updated_at: new Date()});
	// 	console.log("FILE.SYNC", method, model, options);
	// },
	initialize: function(attrs, options) {
		options = options || {};
		this.file = new AWSS3File({},{node: options.node, file: this});
		if(!this.get('status')) {
			this.set({status:this.constructor.STATE_UPLOADING},{silent: true});
		}
		if(options.message) {
			this.set('message_id', options.message.id);
		}
		this.listenTo(this.file, 'progress', this.progress);
		this.listenTo(this.file, 'error', this.uploadError);
		this.listenTo(this.file, 'request', this.uploadStarted);
		this.listenTo(this.file, 'sync', this.uploadComplete);
		this.listenTo(this, 'destroy', this.cancelUpload);
	},
	uploadStarted: function(model, xhr, options) {
		this.trigger('uploadstart');	
	},
	cancelUpload: function() {
		this.set({status:this.constructor.STATE_ABORTED});
		this.file.abort();
	},
	uploadComplete: function() {
		// console.log("SYNC TRIGGERED ON FILE");
		// send the aws key to our server to continue processing in background
		this.save({
				status: this.constructor.STATE_UPLOADED,
				attachment_key: this.file.get('key')
			});
		this.trigger('uploadcomplete');
	},
	uploadError: function(model, xhr, options) {
		// try and make sense of the upload
		var errorText = "Unknown error";
		if(model.previousError && _.isArray(model.previousError['file'])) {
			errorText = model.previousError['file'].join("<br />");
		} else if(model.aborted) {
			errorText = 'Upload aborted';
		} else if(xhr.readyState == 0) {
			// request never completed provide the status Text
			errorText = `Failed to connect to server: ${xhr.statusText}`;
		} else if (xhr.readyState == 4) {
			// request completed error from aws
			errorText = `Request failed: ${xhr.statusText}`;
		}
		this.set({status: this.constructor.STATE_ERROR, errorText: errorText});
		this.trigger('uploaderror', errorText);
	},
	setFile: function(file, callback) {
		var reader = new FileReader()
			var _this = this;
			if(!file.type) {
				type = AWSS3File.inferTypeFromName(file.name);
			} else {
				type = file.type;
			}
		reader.onloadend = function() {
			_this.file.set(AWSS3File.prototype.fileAttribute, new Blob([new Uint8Array(this.result)], {type: type}));
			_this.file.set('Content-Type', type);
			_this.file.setFileName(file.name);
			_this.set({
				last_modified: new Date(file.lastModified),
				attachment_name: file.name,
				attachment_size: file.size,
				attachment_type: type
			});
			callback();
		};
		reader.readAsArrayBuffer(file);
		// this.file.on('all', console.log);
		// we also have to listen to this somehow to setup the paramaters for myself.
		// this.file.save();
	},
	isImage: function() {
		return this.get('attachment_type').startsWith('image/');
	},
	isVideo: function() {
		return this.get('attachment_type').startsWith('video/');
	},
	upload: function() {
		this.file.save(); // TODO process the result here error(destroy) / success(update key)
	},
	progress: function(percentComplete, loaded, total) {
		this.trigger('progress', percentComplete, loaded, total);
	},
	toJSON: function() {
		return {client_guid: (this.collection && this.collection.client_guid), attachment: _.pick(this.attributes, this.constructor.WHITELISTED_ATTRIBUTES)};
	},
	validate: function(attrs, options) {
		options || (options = {});
		if(!options.validate) {
			return false;
		}
		var errors = false,
					e = function(name, value) {
				if(!_.isObject(errors)) { errors = {}; };
				if(!_.isArray(errors[name])) { errors[name] = []; };
				errors[name].push(value);
			};
		// make sure the s3 file passes validation
		if(this.file.validate(this.file.attributes,{validate: true})) {
			e('file', 'Attached file isn\'t valid');
		}
		return errors;
	}
},{
	STATE_UPLOADING: 'uploading',
	STATE_UPLOADED: 'uploaded',
	STATE_PROCESSING: 'processing',
	STATE_PROCESSED: 'processed',
	STATE_ABORTED: 'aborted',
	STATE_ERROR: 'error',
	WHITELISTED_ATTRIBUTES: ['status','attachment_key', 'attachment_size', 'attachment_type', 'message_id']
}),
Files = AbstractCollection.extend({
	// this is the collection of files
	model: File,
	getuuid: function() {
		// simple proxy onto the node
		return this.node.collection.getuuid();
	},
	url: function() {
		return `${this.node.collection.url()}/node/${this.node.get('_id')}/attachments`;
	},
	initialize: function(models, options) {
		options = options || {};
		this.node = options.node;
		this.message = options.message;
		this.client_guid = options.client_guid;
	},
	// sync: function(method, model, options) {
	// 	console.log("FILES.SYNC", method, model, options);
	// },
	addFiles: function(files, options) {
		options = options || {};
		_.each(files, function(file) {
			var fileModel = new File({},{node: options.node, message: this.message});
			this.add(fileModel);
			_.defer(function(){
				fileModel.setFile(file, function(){
					if(!fileModel.validate(fileModel.attributes,{validate: true})) {
						fileModel.save({},{success:function(){
							fileModel.upload();
						}});
					} else {
						fileModel.upload(); // this will trigger the UI to update
					}
				});
			});
		}, this);
	}
}),
AbstractView = Backbone.View.extend({

	addView: function(view) {
		if(!this._subviews) {
			this._subviews = [];
		}
		this.listenTo(view, 'remove', this.removeView);
		this._subviews.push(view);
	},
	clearViews: function() {
		// clean up listeners on subviews and remove them from the dom
		_.each(this._subviews, function(view){
			this.stopListening(view); // no need for callbacks here
			view.remove();
		}, this);
		this._subviews = [];
	},
	removeView: function(view) {
		var idx = _.indexOf(this._subviews, view);
		if(idx > -1) {
			this.stopListening(view);
			// remove the view in place of this array
			this._subviews.splice(idx, 1);
		}
	},
	_sendEventToViews: function(evtName) {
		_.each(this._subviews, function(view) {
			view.trigger(evtName);
		});
	},
	propogateEventToSubViews: function(evtName) {
		this.on(evtName, _.bind(this._sendEventToViews, this, evtName), this);
	},
	getNode: function() {
		return this.options.node;
	},
	remove: function() {
		AbstractView.__super__.remove.apply(this, arguments);
		this.trigger('remove', this);
		return this;
	}

}),
AppView = AbstractView.extend({
	events: function() {
		var events = {};
		if(this.getNode().get('can_post')) {
			events['click .create_new_message'] = 'addBlankMessage';
		}
		return events;
	},
	addBlankMessage: function() {
		this.model.add(new Message({draft: true},{client_guid: this.model.client_guid, node: this.getNode()}));
	},
	initialize: function(options) {
		options = options || {}

		if(options.app) {
			// setup websockets
			this.app = options.app;
			// bind message  updates to the main model!
			// just send them into the main model
			this.listenTo(this.app, 'received', this.onReceived);
			this.app.init(true); // force start
		}
		// this is just called once to setup the view for the application only
		// setup timer
		// bind a timer to appView
		this.on("stoptimer",this.clearTock,this);
		this._timer = window.setInterval(_.bind(this.tock,this), 60000);
		this.propogateEventToSubViews('tock');
		// update the view
		this.model.fetch();
	},
	onReceived: function(message) {
		console.log("INCOMING MESSAGE", message);

		if(message.client_guid == this.model.client_guid) {
			console.log("IGNORING OWN MESSAGE!");
			return;
		}
		var type = message.type,
			data = (message.data);
		if(!_.isObject(data)) {
			console.log("IGNORING NON OBJECT MESSAGE");
			return;
		}
		if(type == "message") {
			// merge existing models to update data
			this.model.add(data, {parse: true, merge: true});
		} else if(message.type == "message_delete") {
			this.model.remove(data.id);
		} else  if(type == "attachment") {
			// merge into the correct message_id message
			var message = this.model.get(data.message_id);
			if(message) {
				message.files.add(data, {parse: true, merge: true})
			} else {
				_.each(this.model.unsaved(), function(message) {
					// send this update to all unsaved messages
					message.files.update(data, {parse: true, merge: true, add: false, remove: false});
				});
				// console.log("IGNORING ATTACHMENT MSG WITHOUT ATTACHMENT", message);
			}
		} else if(message.type == "attachment_delete") {
			var message = this.model.get(data.message_id);
			if(message) {
				message.files.remove(data.id);
			}
		} else {
			console.log("IGNORING UNKNOWN MESSAGE", message);
		}
	},
	tock: function() {
		this.listView.trigger("tock");
	},
	render: function() {
		this.$el.html('');
		this.listView = new MessageListView({ node: this.getNode(), model: this.model, parent_id: null, messageListViewClass: MessageAndRepliesView});
		this.addView(this.listView);
		this.$el.append(this.listView.render().el);

		if(this.getNode().get('can_post')) {
			this.$el.append(`<p><a href="#" class="create_new_message" data-iconpos="left" data-role="button" data-icon="plus">Compose message</a></p>`);
		}

		// this.$el.css({margin: '-15px'});
		_.defer(_.bind(function(){
			this.$el.trigger('create');
			// bind the children view to replies
			// var childrenList = new MessageListView({ el: this.$('.replies'), model: this.model.collection, parent_id: this.model.get('id'), messageListViewClass: MessageView});
		}, this));
		return this;
	},
	clearTock: function() {
		window.clearInterval(this._timer);
		this._timer = null;
	}
}),
FileView = AbstractView.extend({
	// each file represented on the list
	// thumbnail - upload status etc...
	events: {
		'click .remove': 'abort'
	},
	tagName: 'li',
	initialize: function() {
		// bind progress to the view
		this.listenTo(this.model, 'change:status', this.render);
		
		this.listenTo(this.model, 'change:attachment_name', this.updateName);
		this.listenTo(this.model, 'change:thumb_url', this.render);

		// this.listenTo(this.model, 'uploadstart', this.uploadStarted);
		this.listenTo(this.model, 'progress', this.updateProgress);
		this.listenTo(this.model, 'uploaderror', this.uploadError);
		// this.listenTo(this.model, 'uploadcomplete', this.uploadComplete);
		this.listenTo(this.model, 'destroy', this.remove);
		// this.listenTo(this.model, 'change:attachment_url', this.render);
	},
	abort: function() {
		this.model.destroy();
	},
	updateName: function() {
		this.$('h3').text(this.model.get('attachment_name'));
	},
	updateProgress: function(pct) {
		this.$('.ui-slider-bg').css({width: `${pct * 100}%`});
		this.$('.statustext').text(`Upload ${Math.round(pct * 100)}% complete.`)
	},
	uploadError: function(text) {
		// remove progressbar
		this.$('.ui-slider').remove();
		this.$("a").addClass('remove');
		this.$('.statustext').text(`${_.escape(text)}`)
	},
	refreshList: function(callback) {
		_.defer(_.bind(function(){
			// update the listview after adding the li elements
			this.$el.closest('[data-role=listview]').listview('refresh');
			// bind the children view to replies
			// var childrenList = new MessageListView({ el: this.$('.replies'), model: this.model.collection, parent_id: this.model.get('id'), messageListViewClass: MessageView});
			if(callback) {
				callback.call(this);
			}
		}, this));
	},
	render: function(){
		if(!this._rendered) {
			this._rendered = true;
			this.$el.html(`
				<a>
					<h3 data-keep="true" style="margin-top: 0;">${_.escape(this.model.get('attachment_name'))}</h3>
				</a>
				<a class="remove" data-icon="delete">Remove</a>
				`);
		} else {
			// clean out for new state
			this.$("a:first").children().not("[data-keep]").remove();
		}
		var status = this.model.get('status');
		// console.log(`rendering file view status is ${status}!!!`);

		if(status == File.STATE_UPLOADING) {
			this.$("a:first").append(`
					<div class="ui-slider ui-btn-down-a ui-btn-corner-all">
						<div class="ui-slider-bg ui-btn-active ui-btn-corner-all" style="width: 0%;"></div>
					</div>
					<p class="statustext">Upload starting.</p>
				`);
			this.$('.ui-slider').css({
				width: '96%',
				margin: '-6px 2% 6px'
			});
		} else if(status == File.STATE_UPLOADED) {
			this.$("a:first").append(`
					<div class="wobblebar-loader"></div>
					<p class="statustext">Waiting to process</p>
				`);			
		} else if(status == File.STATE_PROCESSING) {
			this.$("a:first").append(`
					<div class="wobblebar-loader"></div>
					<p class="statustext">Processing file</p>
				`);	
		} else if(status == File.STATE_PROCESSED) {
			this.$("a:first").append(`
					<p class="statustext">Finished</p>
				`);			
		} else if(status == File.STATE_ERROR) {
			this.$("a:first").append(`
					<p class="statustext">Error Processing File</p>
				`);			
		} else {
			this.$("a:first").append(`
					<p class="statustext">Unknown State - ${status}</p>
				`);			
		}

		// if we have a thumbnail url add it in
		if(this.model.get('thumb_url')) {
			this.$("a:first").prepend(`
					<img class="ui-li-thumb" src="${this.model.get('thumb_url')}" />
				`);
		}
		this.refreshList();
		return this;
	}
}),
FileViewRO = AbstractView.extend({
	initialize: function() {
		this.listenTo(this.model, 'remove', this.remove);
		this.listenTo(this.model, 'change', this.render);
	},
	render: function() {
		var status = this.model.get('status');
		this.$el.show();
		if(status == File.STATE_ERROR) {
			this.$el.hide();
			this.$el.html('');
		} else if(status != File.STATE_PROCESSED) {
			this.$el.html(`
				<p>File is processing</p>
				<div class="wobblebar-loader"></div>
				`);
		} else {
			if(this.model.isImage()) {
				this.$el.html(`<img width="100%" src="${_.escape(this.model.get('resized_url'))}" />`);
			} else if(this.model.isVideo()) {
				this.$el.html(`<video width="100%" poster="${_.escape(this.model.get('resized_url'))}" controls>
						<source src="${_.escape(this.model.get('playlist_url'))}"  />
						Sorry no video
					</video>`);
			}
		}
		return this;
	}
}),
FilesListView = AbstractView.extend({
	events: function() {
		if(this.cordovaCamera) {
			return {
					'click .takePhoto': 'takeCameraImage',
					'click .uploadLibrary': 'uploadCameraImage'
				}

		} else {
			return {
					'change input[type=file]': 'processFiles'
				}
		}
	},
	cordovaCamera: false,
	initialize: function() {
		this.listenTo(this.model, 'add', this.addOne);
		this.listenTo(this.model, 'reset', this.addAll);
		this.propogateEventToSubViews('tock');
		this.addAll();
		// console.log("INIT", this.options, arguments);
		if(window.navigator && window.navigator.camera && window.navigator.camera) {
			this.cordovaCamera = true;
		}
	},
	addOne: function(file){
		var view = new this.SUBVIEW_CLASS({node: this.getNode(), model: file});
		this.$(this.ROOT_SELECTOR).append(view.render().el);
		this.addView(view);
	},
	addAll: function(){
		this.clearViews();
		this.$("ul > li").slice(1).remove();
		this.model.each(this.addOne, this);
	},
	takeCameraImage: function() {
		this.addCameraImage(Camera.PictureSourceType.CAMERA);
	},
	uploadCameraImage: function() {
		this.addCameraImage(Camera.PictureSourceType.PHOTOLIBRARY);
	},
	addCameraImage: function(sourceType) {
		window.navigator.camera.getPicture(
			_.bind(this._addPictureSuccess, this),
			_.bind(this._addPictureError, this),
			{
				destinationType: Camera.DestinationType.FILE_URI,
				sourceType: sourceType,
				mediaType: Camera.MediaType.ALLMEDIA

			});
	},
	_addPictureSuccess: function(imgUri) {
		var a = document.createElement("a");
		a.href = imgUri;
		// console.log(imgUri);
		window.resolveLocalFileSystemURL(a.href, _.bind(function(fileEntry) {
			// console.log("FILEENTRY", fileEntry);
			fileEntry.file(_.bind(function(entry){
				// console.log("FILE", entry);
				this.model.addFiles([entry], {node: this.getNode()});
			}, this), function() {
				console.log("error getting file entry");
			});
			// console.log(fileEntry);
		}, this), _.bind(function(){
			console.log("FILEENTRY FAILED", arguments);
		}));
		// console.log("SUCCESS", arguments);
	},
	_addPictureError: function(message) {
		console.log("FAILURE", arguments);
	},
	// this is the browser version
	processFiles: function(evt) {
		evt.preventDefault();
		this.model.addFiles(this.$(':input[type=file]')[0].files, {node: this.getNode()});
		this.$(':input[type=file]').val('');
		return false;
	},
	render: function() {
		if(this.cordovaCamera) {
			this.$el.html(`
				<ul data-role="listview">
					<li data-role="list-divider" class="ui-grid-a">
			            <div class="ui-block-a">
			            	<a class="takePhoto" data-role="button" data-icon="star">Take photo</a>
			            </div>
			            <div class="ui-block-b">
			            	<a class="uploadLibrary" data-icon="grid" data-role="button">Choose file</a>
			            </div>
			            <div style="clear: both;"></div>
					</li>
				</ul>
				`).attr({"data-role":'fieldcontain'});
		} else {
			var acceptListForFile = _.chain(AWSS3File.MIME_TYPE_MAP).map(function(value, key){
				return _.flatten([key,_.map(value, function(v){return `.${v}`;})]);
			}).flatten().value().join(",");
			this.$el.html(`
				<ul data-role="listview">
					<li data-role="list-divider">
						<label for="${this.cid}_file" data-icon="plus" data-iconpos="right" data-role="button">Add Images &amp; Videos</label>
				        <input accept="${acceptListForFile}" type="file" name="files[]" multiple name="file" id="${this.cid}_file" style="display: none;">
					</li>
				</ul>
				`).attr({"data-role":'fieldcontain'});

		}
		this.addAll();

		// var _this = this;

		// this.$(":input[type=file]").fileupload({
  //       url: '/demo',
  //       dataType: 'json',
  //       done: function (e, data) {
  //           $.each(data.result.files, function (index, file) {
  //               $('<p/>').text(file.name).appendTo(_this.$('.files'));
  //           });
  //       },
  //       progressall: function (e, data) {
  //           var progress = parseInt(data.loaded / data.total * 100, 10);
  //           _this.$('.progress .progress-bar').css(
  //               'width',
  //               progress + '%'
  //           );
  //       }
  //   }).prop('disabled', !$.support.fileInput)
  //       .parent().addClass($.support.fileInput ? undefined : 'disabled');
		_.defer(_.bind(function(){
			this.$el.trigger('create');
		}, this));
		return this;
	},
	// List of files embedded within the Message Editor
	// handle the list
	// handle adding new files
	SUBVIEW_CLASS: FileView,
	ROOT_SELECTOR: "ul"
}),
FilesListViewRO = FilesListView.extend({
	events: {}, // no events
	addAll: function() {
		this.clearViews();
		// clear html DOM
		this.$(".media > *").remove();
		this.model.each(this.addOne, this);
	},
	render: function() {
		this.$el.html(`
				<div class="media">
				</div>
			`);
		this.addAll();
		return this;
	},
	SUBVIEW_CLASS: FileViewRO,
	ROOT_SELECTOR: ".media"
}),
// the main message list view
MessageListView = AbstractView.extend({
	render: function() {
		return this;
	},
	initialize: function() {
		this.listenTo(this.model, 'add', this.addOne);
		this.listenTo(this.model, 'reset', this.addAll);
		this.listenTo(this.model, 'sort', this.resort);
		this.propogateEventToSubViews('tock');
		this.addAll();
	},
	addOne: function(message){
		// TODO should add messages in correct location! by date created
		if(message.get('parent_id')==this.options.parent_id) {
			var view = new this.options.messageListViewClass({node: this.getNode(), model: message});
			this.$el.prepend(view.render().el);
			this.addView(view);
		}
	},
	addAll: function(){
		this.clearViews();
		this.$el.html('');
		this.model.each(this.addOne, this);
		this.resort();
	},
	resort: function() {
		this._subviews = _.sortBy(this._subviews, function(v) {
			return this.model.indexOf(v.model);
		},this);
		_.each(this._subviews, function(v) {
			this.$el.append(v.$el);
		}, this);
	}
}),
MessageAndRepliesView = AbstractView.extend({
	// view holds a message view and a replies view
	// replies view only gets initialised once the message has an id
	// bind the title of this to 
	initialize: function() {
		this.listenTo(this.model, 'remove', this.remove);
		this.listenTo(this.model, 'change:title', this.updateTitle);
		this.listenTo(this.model, 'change:id', this.initializeChildren);
		this.listenTo(this.model, 'change:updated_at', this.updateTimeAgo);
		this.listenTo(this.model, 'change:owner', this.updateOwner);
		this.propogateEventToSubViews('tock');
		this.on('tock', this.updateTimeAgo, this);
	},
	className: function() {
		return `ui-body ui-body-${this.getNode().get('content')['theme'] || 'a'}`;
	},
	render: function() {
		this.$el.html(`
				<div>
					<img style="float: left; height: 2em; width: 2em; margin: none; margin-right: 0.5em;" src="${this.model.ownerAvatarUrl()}" />
					<h3>${this.model.getHtml('title')}</h3>
					<small><span class="${this.cid}_timeago">${this.model.timeAgo()}</span> by <a href="#" class='owner_name'>${_.escape(this.model.ownerName())}</a></small>
				</div>

			`);
		// initial main message view
		var view = new MessageRootView({node: this.getNode(), model: this.model});
		this.$el.append(view.render().el);
		this.addView(view);
		this.initializeChildren();

		return this;
	},
	updateOwner: function() {
		this.$('img').attr('src', this.model.ownerAvatarUrl());
		this.$('.owner_name').text(this.model.ownerName());

	},
	updateTimeAgo: function() {
		this.$(`.${this.cid}_timeago`).text(this.model.timeAgo());
	},
	updateTitle: function() {
		this.$('h3').text(this.model.get('title'));
	},
	initializeChildren: function(model, id, options) {
		if(this.model.get('id')) {
			var view = new CommentsView({model: this.model, parent_id: id});
			this.addView(view);
			this.$el.append(view.render().el);
		}
	}
}),
// a top level message probrably has sub views btw
AbstractMessageView = AbstractView.extend({
	destroy: function(e) {
		e.preventDefault();
		// TODO confirm with user? only if values entered?
		this._destroyCancelConfirmation('Really delete this?', function(){
			this.model.destroy();
		});
	},
	initialize: function() {
		throw "Abstract View not able to use directly please extend";
	},
	abstractInitialize: function() {
		this.replyModel = this.model.buildReply();
		this.listenTo(this.model, 'error', this.invalid);
		this.listenTo(this.model, 'change', this.render);
		this.listenTo(this.model, 'remove', this.remove);
		this.listenTo(this.model, 'change:id', this.updateParentIdOnReply);
		this.propogateEventToSubViews('tock');
	},
	updateParentIdOnReply: function() {
		this.replyModel.set('parent_id', this.model.get('id'));
	},
	cancel: function(e) {
		e.preventDefault();
		this._destroyCancelConfirmation('Discard Changes?', function(){
			this.model.set({draft: false, editing: false}, {validate: false});
		});
	},
	_destroyCancelConfirmation: function(message, callbackIfOk) {
		if(this.formNotChanged()) {
			callbackIfOk.call(this);
		} else  {
			showConfirm(message, _.bind(function(result) {
				if(result==1) {
					callbackIfOk.call(this);
				};
			}, this), 'Confirm', ['Yes','No']);
		}
	},
	// return true if the form hasn't changed
	formNotChanged: function() {
		if (!this.isComposeMode()) { return false; }
		var formValues = this.getFormValues();
		var attrs = _.pick.apply(this, _.flatten([this.model.attributes,_.keys(formValues)]));
		// console.log("EQUAL", attrs, formValues);
		return _.isEqual(attrs, formValues);
	},
	isComposeMode: function() {
		return this.model.get('draft');
	},
	val: function(name) {
		return this.$(`:input[name=${name}]`).val();
	},
	update: function(e) {
		// update the model
		e.preventDefault(); 
		this.model.save(_.extend(this.getFormValues(), {
			draft: false,
			editing: false
		}), {validate: true});
		return false;
	},
	invalid: function(model, errors) {
		// remove existing errors
		console.log(errors);
		this.$('div[data-role=fieldcontain]').removeClass('has-errors').find('p.error').remove();
		// place error element into view
		var _this = this;
		_.each(errors, function(errArray, name) {
			var fieldcontain = _this.$(`:input[name=${name}]`).closest('[data-role=fieldcontain]').addClass('has-errors');
			_.each(errArray, function(error) {
				fieldcontain.append(`<p class="error">${error}</p>`);
			});
		});
	}
}),
MessageRootView = AbstractMessageView.extend({
	events: function() {
		var events = {}
		if(this.model.canEdit()) {
			_.extend(events, {
				'click a.update' : 'update',
				'click a.edit' : 'edit',
				'submit form.message_form' : 'update',
				'click a.cancel' : 'cancel',
				'change select[name=valid_from_set]' : 'showHideDateInputs',
				'change select[name=valid_to_set]' : 'showHideDateInputs'
			});
		}
		if(this.model.canDelete()) {
			_.extend(events, {
				'click a.delete' : 'destroy',
			});
		}
		if(isAdvancedUpload()) {
			events['drop form'] = 'filedrop';
			_.each('drag dragstart dragend dragover dragenter dragleave drop'.split(' '), function(e){
				events[`${e} form`] = 'dragPreventDefaults';
			});
			_.each('dragover dragenter'.split(' '), function(e){
				events[`${e} form`] = 'dragenter';
			});
			_.each('dragleave dragend drop'.split(' '), function(e){
				events[`${e} form`] = 'dragstop';
			});
		}
		console.log(events);
		return events;
	},
	dragPreventDefaults: function(e) {
		console.log('prevented');
		e.preventDefault();
		e.stopPropagation();
	},
	dragenter: function(e) {
		console.log('enter', e);
		this.$("form").addClass('is-dragover');
	},
	dragstop: function(e) {
		console.log('exit');
		this.$("form").removeClass('is-dragover');
	},
	filedrop: function(e) {
		console.log('drop');
		// send files to the other view to process
		this.model.addFiles(e.originalEvent.dataTransfer.files,{node: this.getNode});
	},
	initialize: function() {
		this.abstractInitialize();
	},
	showHideDateInputs: function(evt) {
		var target = $(evt.target);
		target.parent(".ui-controlgroup-controls").find("input[type=datetime-local]").toggle(target.val()==0);
	},
	_dateToLocalDateString: function(date) {
	    function pad(number) {
	      if (number < 10) {
	        return '0' + number;
	      }
	      return number;
	    }
	    if(!_.isDate(date)) {
	    	return '';
	    }
	      return date.getFullYear() +
	        '-' + pad(date.getMonth() + 1) +
	        '-' + pad(date.getDate()) +
	        'T' + pad(date.getHours()) +
	        ':' + pad(date.getMinutes()) +
	        ':' + pad(date.getSeconds());
	},
	getFormValues: function() {
		var values = {
			title: this.val('title'),
			message: this.val('message'),
			push_notifiation: this.val('push_notifiation')=="1",
			message_category_id: this.val('message_category_id'),
			link_node_id: this.val('link_node_id')
		};
		// TODO REMOVED VAOID_FROM&TO FOR NOW TEMP FIX
		// _.each(['valid_from', 'valid_to'], function(type){
		// 	values[`${type}_set`] = this.val(`${type}_set`)=="1";
		// 	var dateString = this.val(type);
		// 	if(dateString) {
		// 		values[type] = new Date(dateString);	
		// 	}
		// }, this);
		_.each(_.keys(this.model.constructor.PERMISSION_NAMES),function(permission_name){
			values[permission_name] = this.val(permission_name) || [];
			//_.pluck(this.$(`:input[name^=${permission_name}_]`).serializeArray(),'value');
		},this);
		return values;
	},
	edit: function() {
		this.model.set({draft: true, editing: true}, {validate: false});
	},
	_slideHtml: function(name, label, yes, no) {
    		return `
	        	${label?`<label for="${this.cid}_${name}">${label}</label>`:''}
				<select name="${name}" id="${this.cid}_${name}" data-role="slider">
					<option value="0" ${!this.model.get(name)?" selected":""}>${no}</option>
					<option value="1" ${this.model.get(name)?" selected":""}>${yes}</option>
				</select> 	        	
	        `;
	},
	render: function() {
		this.clearViews(); // clear out subviews
		if(this.isComposeMode()) {

			this.$el.html(`<form class='message_form'></form>`);
			var form = this.$(".message_form");

			form.append(`
	        <div data-role="fieldcontain">
	            <label for="${this.cid}_title">Title:</label>
	            <input id="${this.cid}_title" name="title" value="${this.model.getHtml('title')}" placeholder="Topic">
	        </div>
	        <div data-role="fieldcontain">
	            <label for="${this.cid}_message">Message:</label>
	            <textarea id="${this.cid}_message" name="message" placeholder="Message">${this.model.getHtml('message')}</textarea>
	        </div>
	        <div data-role="fieldcontain">
	            <label for="${this.cid}_link_node_id">Link to page:</label>
				<select id="${this.cid}_link_node_id" name="link_node_id">
					<option value="">No Page</option>
	    			${_.map(this.getNode().collection.get('nodeindex').get('nodes'),function(data, id){
						return `<option value="${_.escape(data.id)}" ${this.model.get('link_node_id')==data.id?'selected':''}>${_.escape(data.title)}</option>`;
	    			}, this).join('')}
				</select>	            
	        </div>

	        `);
	        // DISABLED FOR NOW
	   //      _.each(['valid_from', 'valid_to'],function(type){
		  //     	var fieldcontain = $(`
		  //     		<div data-role="fieldcontain">
		  //     			<fieldset data-role="controlgroup" data-type="horizontal">
		  //     				<legend>${this.model.constructor.LABELS[type]}</legend>
		  //     			</fieldset>
		  //     		</div>
		  //     		`).appendTo(form).find("fieldset");

				// fieldcontain.append(this._slideHtml(`${type}_set`, false, type=="valid_from"?'Now':'Never', 'At'));
				// $(`<input id="${this.cid}_${type}" name="${type}" value="${this._dateToLocalDateString(this.model.get(type))}" type="datetime-local">`).appendTo(fieldcontain);
	   //      }, this);

	        if(this.getNode().get('message_push_enabled')) {
	        	form.append(`<div data-role="fieldcontain">
	        		${this._slideHtml('push_notifiation', 'Send push notification', 'Yes', 'No')}
	        		</div>`);
	        }
	      //   _.each(this.model.constructor.PERMISSION_NAMES,function(permission_text,permission_name) {
	      //   	var permissions = this.getNode().get(permission_name);
	      //   	if(_.isArray(permissions) && permissions.length > 0) {
		     //    	var fieldset = $(`
				   //      <div data-role="fieldcontain">
				   //      	<fieldset data-role="controlgroup">
				   //      		<legend>${_.escape(permission_text)}</legend>
				   //      	</fieldset>
				   //      </div>`).appendTo(form).find('fieldset');
		    	// 	_.each(permissions,function(perm, idx){
		    	// 		fieldset.append(`
			    //     		<input type="checkbox" id="${this.cid}_${permission_name}_${idx}" name="${permission_name}_${idx}" value="${_.escape(perm.value)}" ${_.contains(this.model.get(permission_name),perm.value)?'checked':''}>
			    //     		<label for="${this.cid}_${permission_name}_${idx}">${_.escape(perm.name)}</label>
		     //    		`);
		    	// 	},this);
		    	// }
	      //   },this);
	      if(this.getNode().get('message_categories').length == 1) {
	      	// keep same category as it may have changed
	      	form.append(`<input type="hidden" name="message_category_id" value="${this.model.get('message_category_id') || this.getNode().get('message_categories')[0].id}" />`);
	      } else {
		      form.append(`
				<div data-role="fieldcontain">
					<label for="${this.cid}_message_category_id">Message Category:</label>
					<select name="message_category_id" id="${this.cid}_message_category_id">
						<option value="">Message Category</option>
		    			${_.map(this.getNode().get('message_categories'),function(category){
							return `<option value="${_.escape(category.id)}" ${this.model.get('message_category_id')==category.id?'selected':''}>${_.escape(category.name)}</option>`;
		    			}, this).join('')}
					</select>
				</div>
		      	`);

	      }

	      	// THIS IS THE PERMISSIONS SECTIONcategory
	      	var fieldcontain = $(`
	      		<div data-role="fieldcontain">
	      			<fieldset data-role="controlgroup">
	      				<legend>Permissions</legend>
	      			</fieldset>
	      		</div>
	      		`).appendTo(form).find("fieldset");
	        _.each(this.model.constructor.PERMISSION_NAMES,function(permission_text,permission_name) {
	        	var permissions = this.getNode().get(permission_name);
	        	if(_.isArray(permissions) && permissions.length > 0) {
		        	var fieldset = $(`
		        		<label for="${this.cid}_${permission_name}">${_.escape(permission_text)}</label>
		        		<select data-native-menu="false" id="${this.cid}_${permission_name}" name="${permission_name}" multiple="true">
		        			<option value="">${_.escape(permission_text)}</option>
		        			${_.map(permissions,function(perm){
								return `<option value="${_.escape(perm.id)}" ${_.contains(this.model.get(permission_name),perm.id)?'selected':''}>${_.escape(perm.name)}</option>`;
		        			}, this).join('')}
		        		</select>
				        `).appendTo(fieldcontain).find('select');
		    	}
	        },this);
	        // add the files list view to the form at this point
	        this.filesListView = new FilesListView({dragElement: form, node: this.getNode(), message: this.model, model: this.model.files});
			this.addView(this.filesListView);
			form.append(this.filesListView.render().el);

	        form.append(`
	        <fieldset class="ui-grid-a">
	            <div class="ui-block-a"><a class="update" data-role="button" data-icon="check">${this.model.get('editing')?'Edit':'Send'}</a></div>
	            <div class="ui-block-b"><a class="${this.model.get('editing')?'cancel':'delete'}" data-icon="delete" data-role="button">Cancel</a></div>
	        </fieldset>
	        	`);

		} else {
			// show a message :)
			this.$el.html(`
						<p>${this.model.getHtml('message')}</p>
						`);
			// put a link to a page
			if(this.model.get('link_node_id')) {
				var page = this.getNode().collection.get('nodeindex').get('nodes')[this.model.get('link_node_id')];
				if(page) {
					this.$el.append(`<p><a href="${_.escape(page.name)}">${_.escape(page.title)}</a></p>`);
				}
			}
	        // add the files list view to the form at this point
	        this.filesListView = new FilesListViewRO({messageView: this, node: this.getNode(), message: this.model, model: this.model.files});
			this.addView(this.filesListView);
			this.$el.append(this.filesListView.render().el);

			if(this.model.canEdit() || this.model.canDelete()) {
				var $flexbox = $('<div style="display: flex;"></div>');
				this.$el.append($flexbox);
				if(this.model.canEdit()) {
					$flexbox.append(`<a href="#" style="flex-grow:1;" data-role="button" data-icon="gear" data-mini="true" class="edit">Update</a>`);
				}
				if(this.model.canDelete()) {
					$flexbox.append(`<a href="#" style="flex-grow:1;" data-role="button" data-icon="delete" data-mini="true" class="delete">Delete</a>`);
				}
			}
			// this view should also include a box to do a reply :)
			// add reply view between the <p> and the <div>
			// var replyView = (new MessageReplyView({model: this.replyModel})).render();
			// this.$("p").after(replyView.el);
		}
		// initialize jquery mobile widgets
		_.defer(_.bind(function(){
			this.$el.trigger('create');
	        this.$(':input[name$=_set]').trigger('change');
			// bind the children view to replies
			// var childrenList = new MessageListView({ el: this.$('.replies'), model: this.model.collection, parent_id: this.model.get('id'), messageListViewClass: MessageView});
			if(this.isComposeMode()) {
				// scroll to the top of the messages
				$("html").scrollTop(this.$el.offset().top);
			}
		}, this));

		return this;
	}
}),
// this is the little mini form for a messgae reply.
MessageReplyView = AbstractMessageView.extend({
	events: {
		'submit form.reply_form' : 'update',
		'click a.reply_button' : 'update',
		'change input[name=message]' : 'saveDraft'
	},
	initialize: function(options) {
		this.abstractInitialize();
	},
	saveDraft: function() {
		this.model.set({message: this.val('message')},{validate: false, silent: true});
	},
	getFormValues: function() {
		return {
			message: this.val('message')
		};
	},
	render: function() {
		if(this.isComposeMode()) {
			this.$el.html(`
						<form class="reply_form">
							<div data-role="fieldcontain">
								<div style="display: flex;">
									<input style="flex-grow: 1;" type="text" placeholder="${this.model.levelName()}" name="message" id="${this.cid}_message" value="${this.model.getHtml('message')}" />
									<a class="reply_button" data-role="button" data-icon="check">${this.model.levelName()}</a>
								</div>
							</div>
						</form>
					`);
		} else {
			this.$el.html(`<p>${this.model.getHtml('message')}</p>`);
		}
		// initialize jquery mobile widgets
		_.defer(_.bind(function(){
			this.$el.trigger('create');
			// bind the children view to replies
			// var childrenList = new MessageListView({ el: this.$('.replies'), model: this.model.collection, parent_id: this.model.get('id'), messageListViewClass: MessageView});
		}, this));

		return this;

	}
}),
CommentsView = AbstractMessageView.extend({
	// basic layout of this
	// list of CommentsViews bound with parent_id restriction
	// MessageReplyView
	// model is in collection 
	initialize: function() {
		// no op
		this.abstractInitialize();
		this.listenTo(this.replyModel, 'change:id', this.replaceReplyView);
		this.listenTo(this.model, 'change:updated_at', this.updateTimeAgo);
		this.on('tock', this.updateTimeAgo, this);
	},
	replaceReplyView: function(model, valueId, options) {
		if(valueId) {
			// move model to collection
			this.model.collection.add(model);
			// remove all callbacks on this model
			this.stopListening(model);

			// build a new rpely model and rebind and render!
			this.replyModel = this.model.buildReply();
			this.listenTo(this.replyModel, 'change:id', this.replaceReplyView);
			this.render();
		}
	},
	updateTimeAgo: function() {
		this.$(`.${this.cid}_timeago`).text(this.model.timeAgo());
	},
	render: function() {
		this.$el.html(`<div style="padding-left: 10px;"></div>`);
		if(this.model.get('parent_id')) {
			// exclude the top level message from this view
			this.$('> div').append(`
					<img style="float: left; height: 2em; width: 2em; margin: none; margin-right: 0.5em;" src="${this.model.ownerAvatarUrl()}" />
					<small><span class="${this.cid}_timeago">${this.model.timeAgo()}</span> by <a href="#">${this.model.ownerName()}</a></small>
					<p>${this.model.getHtml('message')}</p>
			`);
		}
		this.listView = new MessageListView({ node: this.getNode(), model: this.model.collection, parent_id: this.model.get('id'), messageListViewClass: CommentsView});
		this.addView(this.listView);
		this.$('> div').append(this.listView.render().el);
		if(this.model.canReply()) {
			this.replyView = new MessageReplyView({node: this.getNode(), parentModel: this.model, model: this.replyModel});
			this.addView(this.replyView);
			this.$el.append(this.replyView.render().el);
		}
		// this.$el.append(`<p>LIST OF COMMENTS VIEWS (empty initially)</p>`);
		// this.$el.append(`
		// 			<form class="reply_form">
		// 				<div data-role="fieldcontain">
		// 					<input style="flex-grow: 1;" type="text" placeholder="Reply to this" name="message" id="${this.cid}_message" value="" />
		// 					<a class="reply_button" data-role="button" data-icon="check">Reply</a>
		// 				</div>
		// 			</form>
		// 		`);
		// initialize jquery mobile widgets
		// _.defer(_.bind(function(){
		// 	this.$el.trigger('create');
		// 	// bind the children view to replies
		// 	// var childrenList = new MessageListView({ el: this.$('.replies'), model: this.model.collection, parent_id: this.model.get('id'), messageListViewClass: MessageView});
		// }, this));

		return this;
	}
}); //end var


// APP INIT
// initApp2(view, node).done(

this.getStartMessagingAppFunction = function(view, node){
	// need to pass in view and node to get this working.
	return function(actionCableApp){

		// view.on('changepage', function() {
			// console.log(view.el);
			// console.log(view.$el.html());
			// console.log("TEMPLATE DIV", view.$('.notification_template')[0]);
			// start off with empty messages
			var messages = new Messages([], {node: node}),
			app = new AppView({
				model: messages,
				node: node,
				app: actionCableApp,
				el: view.$('.notification_template')[0] }).render();

			// TODO TEST THIS CODE COMMENTED OUT FOR NOW ALSO NEEDS MORE GUARDS AGAINST NULLS
			// var fnToWrap = main.connector.get('client').push._handlers.notification[0];
			// main.connector.get('client').push._handlers.notification[0] = _.wrap(fnToWrap, function(func, data){
			// 	var additionalData = data.additionalData || {};
			// 	if(!(additionalData.foreground && additionalData.node && additionalData.node==node.get('name'))) {
			// 		return func(data);
			// 	}
			// });

			view.on('closepage', function() {
				app.trigger("stoptimer");
				// debind the function wrapping the notifications system!
				// main.connector.get('client').push._handlers.notification[0] = fnToWrap;
			});

			window.view = view;
			window.app = app;
			window.messages = messages;
		// });
	};
};

var initjQueryPlugins = function() {

/**
 * Timeago is a jQuery plugin that makes it easy to support automatically
 * updating fuzzy timestamps (e.g. "4 minutes ago" or "about 1 day ago").
 *
 * @name timeago
 * @version 1.6.1
 * @requires jQuery v1.2.3+
 * @author Ryan McGeary
 * @license MIT License - http://www.opensource.org/licenses/mit-license.php
 *
 * For usage and examples, visit:
 * http://timeago.yarp.com/
 *
 * Copyright (c) 2008-2017, Ryan McGeary (ryan -[at]- mcgeary [*dot*] org)
 */

(function (factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['jquery'], factory);
  } else if (typeof module === 'object' && typeof module.exports === 'object') {
    factory(require('jquery'));
  } else {
    // Browser globals
    factory(jQuery);
  }
}(function ($) {
  $.timeago = function(timestamp) {
    if (timestamp instanceof Date) {
      return inWords(timestamp);
    } else if (typeof timestamp === "string") {
      return inWords($.timeago.parse(timestamp));
    } else if (typeof timestamp === "number") {
      return inWords(new Date(timestamp));
    } else {
      return inWords($.timeago.datetime(timestamp));
    }
  };
  var $t = $.timeago;

  $.extend($.timeago, {
    settings: {
      refreshMillis: 60000,
      allowPast: true,
      allowFuture: false,
      localeTitle: false,
      cutoff: 0,
      autoDispose: true,
      strings: {
        prefixAgo: null,
        prefixFromNow: null,
        suffixAgo: "ago",
        suffixFromNow: "from now",
        inPast: 'any moment now',
        seconds: "less than a minute",
        minute: "about a minute",
        minutes: "%d minutes",
        hour: "about an hour",
        hours: "about %d hours",
        day: "a day",
        days: "%d days",
        month: "about a month",
        months: "%d months",
        year: "about a year",
        years: "%d years",
        wordSeparator: " ",
        numbers: []
      }
    },

    inWords: function(distanceMillis) {
      if (!this.settings.allowPast && ! this.settings.allowFuture) {
          throw 'timeago allowPast and allowFuture settings can not both be set to false.';
      }

      var $l = this.settings.strings;
      var prefix = $l.prefixAgo;
      var suffix = $l.suffixAgo;
      if (this.settings.allowFuture) {
        if (distanceMillis < 0) {
          prefix = $l.prefixFromNow;
          suffix = $l.suffixFromNow;
        }
      }

      if (!this.settings.allowPast && distanceMillis >= 0) {
        return this.settings.strings.inPast;
      }

      var seconds = Math.abs(distanceMillis) / 1000;
      var minutes = seconds / 60;
      var hours = minutes / 60;
      var days = hours / 24;
      var years = days / 365;

      function substitute(stringOrFunction, number) {
        var string = $.isFunction(stringOrFunction) ? stringOrFunction(number, distanceMillis) : stringOrFunction;
        var value = ($l.numbers && $l.numbers[number]) || number;
        return string.replace(/%d/i, value);
      }

      var words = seconds < 45 && substitute($l.seconds, Math.round(seconds)) ||
        seconds < 90 && substitute($l.minute, 1) ||
        minutes < 45 && substitute($l.minutes, Math.round(minutes)) ||
        minutes < 90 && substitute($l.hour, 1) ||
        hours < 24 && substitute($l.hours, Math.round(hours)) ||
        hours < 42 && substitute($l.day, 1) ||
        days < 30 && substitute($l.days, Math.round(days)) ||
        days < 45 && substitute($l.month, 1) ||
        days < 365 && substitute($l.months, Math.round(days / 30)) ||
        years < 1.5 && substitute($l.year, 1) ||
        substitute($l.years, Math.round(years));

      var separator = $l.wordSeparator || "";
      if ($l.wordSeparator === undefined) { separator = " "; }
      return $.trim([prefix, words, suffix].join(separator));
    },

    parse: function(iso8601) {
      var s = $.trim(iso8601);
      s = s.replace(/\.\d+/,""); // remove milliseconds
      s = s.replace(/-/,"/").replace(/-/,"/");
      s = s.replace(/T/," ").replace(/Z/," UTC");
      s = s.replace(/([\+\-]\d\d)\:?(\d\d)/," $1$2"); // -04:00 -> -0400
      s = s.replace(/([\+\-]\d\d)$/," $100"); // +09 -> +0900
      return new Date(s);
    },
    datetime: function(elem) {
      var iso8601 = $t.isTime(elem) ? $(elem).attr("datetime") : $(elem).attr("title");
      return $t.parse(iso8601);
    },
    isTime: function(elem) {
      // jQuery's `is()` doesn't play well with HTML5 in IE
      return $(elem).get(0).tagName.toLowerCase() === "time"; // $(elem).is("time");
    }
  });

  // functions that can be called via $(el).timeago('action')
  // init is default when no action is given
  // functions are called with context of a single element
  var functions = {
    init: function() {
      functions.dispose.call(this);
      var refresh_el = $.proxy(refresh, this);
      refresh_el();
      var $s = $t.settings;
      if ($s.refreshMillis > 0) {
        this._timeagoInterval = setInterval(refresh_el, $s.refreshMillis);
      }
    },
    update: function(timestamp) {
      var date = (timestamp instanceof Date) ? timestamp : $t.parse(timestamp);
      $(this).data('timeago', { datetime: date });
      if ($t.settings.localeTitle) {
        $(this).attr("title", date.toLocaleString());
      }
      refresh.apply(this);
    },
    updateFromDOM: function() {
      $(this).data('timeago', { datetime: $t.parse( $t.isTime(this) ? $(this).attr("datetime") : $(this).attr("title") ) });
      refresh.apply(this);
    },
    dispose: function () {
      if (this._timeagoInterval) {
        window.clearInterval(this._timeagoInterval);
        this._timeagoInterval = null;
      }
    }
  };

  $.fn.timeago = function(action, options) {
    var fn = action ? functions[action] : functions.init;
    if (!fn) {
      throw new Error("Unknown function name '"+ action +"' for timeago");
    }
    // each over objects here and call the requested function
    this.each(function() {
      fn.call(this, options);
    });
    return this;
  };

  function refresh() {
    var $s = $t.settings;

    //check if it's still visible
    if ($s.autoDispose && !$.contains(document.documentElement,this)) {
      //stop if it has been removed
      $(this).timeago("dispose");
      return this;
    }

    var data = prepareData(this);

    if (!isNaN(data.datetime)) {
      if ( $s.cutoff === 0 || Math.abs(distance(data.datetime)) < $s.cutoff) {
        $(this).text(inWords(data.datetime));
      } else {
        if ($(this).attr('title').length > 0) {
            $(this).text($(this).attr('title'));
        }
      }
    }
    return this;
  }

  function prepareData(element) {
    element = $(element);
    if (!element.data("timeago")) {
      element.data("timeago", { datetime: $t.datetime(element) });
      var text = $.trim(element.text());
      if ($t.settings.localeTitle) {
        element.attr("title", element.data('timeago').datetime.toLocaleString());
      } else if (text.length > 0 && !($t.isTime(element) && element.attr("title"))) {
        element.attr("title", text);
      }
    }
    return element.data("timeago");
  }

  function inWords(date) {
    return $t.inWords(distance(date));
  }

  function distance(date) {
    return (new Date().getTime() - date.getTime());
  }

  // fix for IE6 suckage
  document.createElement("abbr");
  document.createElement("time");
}));



};

initjQueryPlugins();

// expose some things this one is temp need to remove for production or somehow export this.
this.Message = Message;



}).call(this);

