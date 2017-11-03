

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

var initApp = function(view, node) {
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
}, 
showConfirm = function(message, confirmCallback, title, buttonLabels) {
            if (((_ref = window.navigator) != null ? (_ref1 = _ref.notification) != null ? _ref1.confirm : void 0 : void 0) != null) {
                window.navigator.notification.confirm(message, confirmCallback, title, buttonLabels);
            } else {
                confirmCallback.call(this, (confirm(message) ? 1 : 2));
            }
        },
// a user model to demo with
User = Backbone.Model.extend({
	// demo user
	defaults: {
		avatar_url: "https://www.iconexperience.com/_img/o_collection_png/green_dark_grey/512x512/plain/user.png",
		name: "Joe Bloggs"
	}
}),
Message = Backbone.Model.extend({
	defaults: {
		id: null,
		node_id: node._id, // get nodeid from page??? this shold be passed into the views somehow.
		title: '',
		message: '',
		sent: false,
		draft: false,
		push_notifiation: false,
		parent_id: null,
		owner: new User()
	},
	initialize: function(){
		// setup replies
		// this.replies = new Messages();
		this.set({
			updated_at: new Date(),
			created_at: new Date()
		});
	},
	sync: function(method, model, options) {
		if(method=="create") {
			// give this model a FAKE ID for now
			model.set({id: _.uniqueId('message_')});
		}
		model.set({updated_at: new Date()});
		console.log("MESSAGE.SYNC", method, model, options);
	},
	timeAgo: function() {
		return jQuery.timeago(this.get('updated_at'));
	},
	ownerName: function() {
		return this.get('owner').get('name');
	},
	ownerAvatarUrl: function() {
		return this.get('owner').get('avatar_url');
	},
	getHtml: function(key) {
		return _.escape(this.get(key));
	},
	validate: function(attrs, options) {
		var errors = false,
			e = function(name, value) {
				if(!_.isObject(errors)) { errors = {}; };
				if(!_.isArray(errors[name])) { errors[name] = []; };
				errors[name].push(value);
			},
			// return TRUE if string is OK
			checkStr = function(str){
				return _.isString(str) && str.trim().length > 0;
			};
		if(!attrs.draft) {
			// if is a ROOT message we require a title
			if(!attrs.parent_id) {
				checkStr(attrs.title) || e('title', 'A Topic for this message is required.');
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
			});
		model._parent = this;
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
		return this.depth() < 2;
	},
	canDelete: function() {
		return true;
	},
	canEdit: function() {
		return true; //!!this.get('parent_id');
	}
},{
	MESSAGE_LEVELS: {
		0: "Message",
		1: "Comment",
		2: "Reply"
	}
}),
Messages = Backbone.Collection.extend({
	model: Message,
	sync: function(method, model, options) {
		console.log("MESSAGES.SYNC", method, model, options);
	}
})
AbstractView = Backbone.View.extend({
	addView: function(view) {
		if(!this._subviews) {
			this._subviews = [];
		}
		this._subviews.push(view);
	},
	clearViews: function() {
		this._subviews = [];
	},
	_sendEventToViews: function(evtName) {
		_.each(this._subviews, function(view) {
			view.trigger(evtName);
		});
	},
	propogateEventToSubViews: function(evtName) {
		this.on(evtName, _.bind(this._sendEventToViews, this, evtName), this);
	}

});
AppView = AbstractView.extend({
	events: {
		'click .ui-btn-right': 'addBlankMessage'
	},
	addBlankMessage: function() {
		this.model.add(new Message({draft: true}));
	},
	initialize: function() {
		// do nothing for now.
		// this is just called once to setup the view for the application only
		this.listView = new MessageListView({ model: this.model, parent_id: null, messageListViewClass: MessageAndRepliesView});
		this.addView(this.listView);
		this.$el.append(this.listView.render().el);
		// setup timer
		// bind a timer to appView
		this.on("stoptimer",this.clearTock,this);
		this._timer = window.setInterval(_.bind(this.tock,this), 60000);
		this.propogateEventToSubViews('tock');
	},
	tock: function() {
		this.listView.trigger("tock");
	},
	clearTock: function() {
		window.clearInterval(this._timer);
		this._timer = null;
	}
}),
// the main message list view
MessageListView = AbstractView.extend({
	render: function() {
		return this;
	},
	initialize: function() {
		this.listenTo(this.model, 'add', this.addOne);
		this.listenTo(this.model, 'reset', this.addAll);
		this.propogateEventToSubViews('tock');
		this.addAll();
	},
	addOne: function(message){
		// TODO should add messages in correct location! by date created
		if(message.get('parent_id')==this.options.parent_id) {
			var view = new this.options.messageListViewClass({model: message});
			this.$el.append(view.render().el);
			this.addView(view);
		}
	},
	addAll: function(){
		this.clearViews();
		this.$el.html('');
		this.model.each(this.addOne, this);
	}
}),
MessageAndRepliesView = AbstractView.extend({
	// view holds a message view and a replies view
	// replies view only gets initialised once the message has an id
	// bind the title of this to 
	initialize: function() {
		this.listenTo(this.model, 'destroy', this.remove);
		this.listenTo(this.model, 'change:title', this.updateTitle);
		this.listenTo(this.model, 'change:id', this.initializeChildren);
		this.listenTo(this.model, 'change:updated_at', this.updateTimeAgo);
		this.propogateEventToSubViews('tock');
		this.on('tock', this.updateTimeAgo, this);
	},
	className: 'ui-body ui-body-a',
	render: function() {
		this.$el.html(`
				<div>
					<img style="float: left; height: 2em; width: 2em; margin: none; margin-right: 0.5em;" src="${this.model.ownerAvatarUrl()}" />
					<h3>${this.model.getHtml('title')}</h3>
					<small><span class="${this.cid}_timeago">${this.model.timeAgo()}</span> by <a href="#">${this.model.ownerName()}</a></small>
				</div>

			`);
		// initial main message view
		var view = new MessageRootView({model: this.model});
		this.$el.append(view.render().el);
		this.addView(view);
		this.initializeChildren();

		return this;
	},
	updateTimeAgo: function() {
		this.$(`.${this.cid}_timeago`).text(this.model.timeAgo());
	},
	updateTitle: function() {
		this.$('h3').text(this.model.get('title'));
	},
	initializeChildren: function(model, id, options) {
		if(id) {
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
		this.listenTo(this.model, 'destroy', this.remove);
		this.listenTo(this.model, 'change:id', this.updateParentIdOnReply);
		this.propogateEventToSubViews('tock');
	},
	updateParentIdOnReply: function() {
		this.replyModel.set('parent_id', this.model.get('id'));
	},
	cancel: function(e) {
		e.preventDefault();
		this._destroyCancelConfirmation('Discard Changes?', function(){
			this.model.set({draft: false, editing: false});
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
		this.$('div[data-role=fieldcontain]').removeClass('has-errors').find('p.error').remove();
		// place error element into view
		var _this = this;
		_.each(errors, function(errArray, name) {
			var fieldcontain = _this.$(`:input[name=${name}]`).parent('[data-role=fieldcontain]').addClass('has-errors');
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
				'click a.cancel' : 'cancel'
			});
		}
		if(this.model.canDelete()) {
			_.extend(events, {
				'click a.delete' : 'destroy',
			});
		}
		return events;
	},
	initialize: function() {
		this.abstractInitialize();
	},
	getFormValues: function() {
		return {
			title: this.val('title'),
			message: this.val('message'),
			push_notifiation: this.val('push_notifiation')=="1",
		};
	},
	edit: function() {
		this.model.set({draft: true, editing: true});
	},
	render: function() {
		if(this.isComposeMode()) {
			this.$el.html(`<form class='message_form'>
	        <div data-role="fieldcontain">
	            <label for="${this.cid}_title">Title:</label>
	            <input id="${this.cid}_title" name="title" value="${this.model.getHtml('title')}" placeholder="Topic">
	        </div>
	        <div data-role="fieldcontain">
	            <label for="${this.cid}_message">Message:</label>
	            <textarea id="${this.cid}_message" name="message" placeholder="Message">${this.model.getHtml('message')}</textarea>
	        </div>
	        <div data-role="fieldcontain">
	        	<label for="${this.cid}_push">Send push notification:</label>
				<select name="push_notifiation" id="${this.cid}_push" data-role="slider">
					<option value="0" ${!this.model.get('push_notifiation')?" selected":""}>No</option>
					<option value="1" ${this.model.get('push_notifiation')?" selected":""}>Yes</option>
				</select> 	        	
	        </div>
	        <fieldset class="ui-grid-a">
	            <div class="ui-block-a"><a class="update" data-role="button" data-icon="check">${this.model.get('editing')?'Edit':'Send'}</a></div>
	            <div class="ui-block-b"><a class="${this.model.get('editing')?'cancel':'delete'}" data-icon="delete" data-role="button">Cancel</a></div>
	        </fieldset>
	    </form>`);

		} else {
			// show a message :)
			this.$el.html(`
						<p>${this.model.getHtml('message')}</p>
						`);
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
			// bind the children view to replies
			// var childrenList = new MessageListView({ el: this.$('.replies'), model: this.model.collection, parent_id: this.model.get('id'), messageListViewClass: MessageView});
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
		this.listView = new MessageListView({ model: this.model.collection, parent_id: this.model.get('id'), messageListViewClass: CommentsView});
		this.addView(this.listView);
		this.$('> div').append(this.listView.render().el);
		if(this.model.canReply()) {
			this.replyView = new MessageReplyView({parentModel: this.model, model: this.replyModel});
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
initApp2(view, node).done(function(app){

	view.on('changepage', function() {
		// console.log(view.el);
		// console.log(view.$el.html());
		// console.log("TEMPLATE DIV", view.$('.notification_template')[0]);
		var messages = new Messages(),
		app = new AppView({
			model: messages,
			el: view.$('.notification_template')[0] });

		view.on('closepage', function() {
			app.trigger("stoptimer");
		});




		window.view = view;
		window.app = app;
		window.messages = messages;
	});
});
