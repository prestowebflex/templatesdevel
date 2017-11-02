// Async function to get ActionCable Javascript
// in production this should be pointed at the cdn url?
// returns a promise
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
Message = Backbone.Model.extend({
	defaults: {
		id: null,
		node_id: node._id, // get nodeid from page
		title: '',
		message: '',
		sent: false,
		draft: false,
		push_notifiation: false,
		parent_id: null
	},
	initialize: function(){
		// setup replies
		// this.replies = new Messages();
	},
	sync: function(method, model, options) {
		if(method=="create") {
			// give this model a FAKE ID for now
			model.set({id: _.uniqueId('message_')}, {silent: true});
		}
		console.log("MESSAGE.SYNC", method, model, options);
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
			checkStr(attrs.title) || e('title', 'A Topic for this message is required.');
			checkStr(attrs.message) || e('message', 'A body this for this message is required');
		}
		return errors;
	}
}),
Messages = Backbone.Collection.extend({
	model: Message,
	sync: function(method, model, options) {
		console.log("MESSAGES.SYNC", method, model, options);
	}
})
AppView = Backbone.View.extend({
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
		this.$el.append(this.listView.render().el);
	},
}),
// the main message list view
MessageListView = Backbone.View.extend({
	render: function() {
		return this;
	},
	initialize: function() {
		this.listenTo(this.model, 'add', this.addOne);
		this.listenTo(this.model, 'reset', this.addAll);
		this.addAll();
	},
	addOne: function(message){
		// TODO should add messages in correct location! by date created
		if(message.get('parent_id')==this.options.parent_id) {
			var view = new this.options.messageListViewClass({model: message});
			this.$el.append(view.render().el);
		}
	},
	addAll: function(){
		this.$el.html('');
		this.model.each(this.addOne, this);
	}
}),
MessageAndRepliesView = Backbone.View.extend({
	// view holds a message view and a replies view
	// replies view only gets initialised once the message has an id
	// bind the title of this to 
	initialize: function() {
		this.listenTo(this.model, 'destroy', this.remove);
		this.listenTo(this.model, 'change:title', this.updateTitle);
		this.listenTo(this.model, 'change:id', this.initializeChildren);
	},
	className: 'ui-body ui-body-a',
	render: function() {
		this.$el.html(`
				<h3>${this.model.getHtml('title')}</h3>
			`);
		// initial main message view
		var view = new MessageRootView({model: this.model});
		this.$el.append(view.render().el);
		return this;
	},
	updateTitle: function() {
		this.$('h3').text(this.model.get('title'));
	},
	initializeChildren: function() {
		// do nothing for now
	}
}),
// a top level message probrably has sub views btw
AbstractMessageView = Backbone.View.extend({
	destroy: function() {
		// TODO confirm with user? only if values entered?
		this._destroyCancelConfirmation('Really delete this?', function(){
			this.model.destroy();
		});
	},
	cancel: function() {
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
	reply: function() {
		this.model.collection.add(new Message({draft: true, parent_id: this.model.get('id')}));
	}
}),
MessageRootView = AbstractMessageView.extend({
	events: {
		'click a.cancel' : 'cancel',
		'click a.delete' : 'destroy',
		'click a.update' : 'update',
		'click a.edit' : 'edit',
		'click a.reply' : 'reply'
	},
	initialize: function() {
		this.listenTo(this.model, 'change', this.render);
		this.listenTo(this.model, 'destroy', this.remove);
		this.listenTo(this.model, 'error', this.invalid);
	},
	update: function() {
		// update the model
		this.model.save(_.extend(this.getFormValues(), {
			draft: false,
			editing: false
		}), {validate: true});
	},
	getFormValues: function() {
		return {
			title: this.$title.val(),
			message: this.$message.val(),
			push_notifiation: this.$push_notifiation.val()=="1",
		};
	},
	invalid: function(model, errors) {
		// remove existing errors
		this.$('div[data-role=fieldcontain]').removeClass('has-errors').find('p.error').remove();
		// place error element into view
		var _this = this;
		_.each(errors, function(errArray, name) {
			var fieldcontain = _this.$(`:input[name=${name}]`).parent().addClass('has-errors');
			_.each(errArray, function(error) {
				fieldcontain.append(`<p class="error">${error}</p>`)
			});
		});
	},
	edit: function() {
		this.model.set({draft: true, editing: true});
	},
	render: function() {
		if(this.isComposeMode()) {
			this.$el.html(`<form>
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
	            <div class="ui-block-a"><a class="update" data-role="button">${this.model.get('editing')?'Edit':'Send'}</a></div>
	            <div class="ui-block-b"><a class="${this.model.get('editing')?'cancel':'delete'}" data-role="button">Cancel</a></div>
	        </fieldset>
	    </form>`);

			this.$title = this.$(':input[name=title]');
			this.$message = this.$(':input[name=message]');
			this.$push_notifiation = this.$(':input[name=push_notifiation]');
		} else {
			// show a message :)
			this.$el.html(`
						<p>${this.model.getHtml('message')}</p>
						<p><a href="#" class="edit">Update</a> <a href="#" class="delete">Delete</a> <a href="#" class="reply">Reply</a></p>
					<div class="replies">
					</div>
				`);
		}
		_.defer(_.bind(function(){
			this.$('form').trigger('create');
			// bind the children view to replies
			var childrenList = new MessageListView({ el: this.$('.replies'), model: this.model.collection, parent_id: this.model.get('id'), messageListViewClass: MessageView});
		}, this));

		return this;
	}
}),
MessageView = AbstractMessageView.extend({
	// the message itself
	// this will be bound to children onlt
	render: function() {
		this.$el.html('<p>DEMO</p>');
		return this;
	},
})
; //end var


// APP INIT
initApp2(view, node).done(function(app){
	console.log('init');
	view.on('changepage', function() {
		// console.log(view.el);
		// console.log(view.$el.html());
		// console.log("TEMPLATE DIV", view.$('.notification_template')[0]);
		var messages = new Messages(),
		app = new AppView({
			model: messages,
			el: view.$('.notification_template')[0] });
		window.view = view;
		window.app = app;
		window.messages = messages;
	});
});
