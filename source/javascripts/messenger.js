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
Message = Backbone.Model.extend({
	defaults: {
		id: null,
		node_id: node._id, // get nodeid from page
		title: '',
		message: '',
		sent: false,
		draft: true
	},
	initialize: function(){
		// setup replies
		this.replies = new Messages();
	},
	sync: function(method, model, options) {
		console.log("MESSAGE.SYNC", method, model, options);
	},
	validate: function(attrs, options) {
		var errors = false,
			e = function(name, value) {
				if(!_.isObject(errors)) { errors = {}; };
				if(!_.isArray(errors[name])) { errors[name] = []; };
				errors[name].push(value);
			};
		if(!attrs.draft) {
			attrs.title || e('title', 'A Topic for this message is required.');
			attrs.message || e('message', 'A body this for this message is required');
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
		this.model.create();
	},
	initialize: function() {
		// do nothing for now.
		// this is just called once to setup the view for the application only
		var view = new MessageListView({ model: this.model });
		this.$el.append(view.render().el);
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
	},
	addOne: function(message){
		// TODO should add messages in correct location! by date created
		if(!message.get('parent_id')) {
			var view = new MessageView({model: message});
			this.$el.append(view.render().el);
		}
	},
	addAll: function(){
		this.$el.html('');
		this.messages.each(this.addOne, this);
	}
}),
// a top level message probrably has sub views btw
MessageView = Backbone.View.extend({
	events: {
		'click a.cancel' : 'destroy',
		'click a.update' : 'update',
		'click a.edit' : 'edit'
	},
	initialize: function() {
		this.listenTo(this.model, 'change', this.render);
		this.listenTo(this.model, 'destroy', this.remove);
		this.listenTo(this.model, 'error', this.invalid);
	},
	destroy: function() {
		this.model.destroy();
	},
	update: function() {
		// update the model
		this.model.set({
			title: this.$title.val(),
			message: this.$message.val(),
			push_notifiation: this.$push_notifiation.val()=="1",
			draft: false
		}, {validate: true});
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
		this.model.set({draft: true});
	},
	isComposeMode: function() {
		return this.model.get('draft');
	},
	render: function() {
		if(this.isComposeMode()) {
			this.$el.html(`<form>
	        <div data-role="fieldcontain">
	            <label for="${this.cid}_title">Title:</label>
	            <input id="${this.cid}_title" name="title" value="${this.model.get('title')}" placeholder="Topic">
	        </div>
	        <div data-role="fieldcontain">
	            <label for="${this.cid}_message">Message:</label>
	            <textarea id="${this.cid}_message" name="message" placeholder="Message">${this.model.get('message')}</textarea>
	        </div>
	        <div data-role="fieldcontain">
	        	<label for="${this.cid}_push">Send push notification:</label>
				<select name="push_notifiation" id="${this.cid}_push" data-role="slider">
					<option value="0" ${!this.model.get('push_notifiation')?" selected":""}>No</option>
					<option value="1" ${this.model.get('push_notifiation')?" selected":""}>Yes</option>
				</select> 	        	
	        </div>
	        <fieldset class="ui-grid-a">
	            <div class="ui-block-a"><a class="update" data-role="button">Send</a></div>
	            <div class="ui-block-b"><a class="cancel" data-role="button">Cancel</a></div>
	        </fieldset>
	    </form>`);

			this.$title = this.$(':input[name=title]');
			this.$message = this.$(':input[name=message]');
			this.$push_notifiation = this.$(':input[name=push_notifiation]');
		} else {
			// show a message :)
			this.$el.html(`
					<div class="ui-body ui-body-a">
						<h3>${this.model.get('title')}</h3>
						<p>${this.model.get('message')}</p>
						<p><a href="#" class="edit">Update</a> <a href="#" class="cancel">Delete</a></p>
					</div>

				`);
		}
		var _this = this;
		_.defer(function(){
			_this.$el.trigger('create');	
		});
		return this;
	}
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
