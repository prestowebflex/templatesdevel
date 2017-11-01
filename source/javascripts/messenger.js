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
		node_id: node._id // get nodeid from page
	},
	initialize: function(){
		// setup replies
		this.replies = new Messages();
	},
	sync: function(method, model, options) {
		console.log("MESSAGE.SYNC", method, model, options);
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
		console.log(this.model);
		this.model.create({});
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
		var view = new MessageView({model: message});
		this.$el.append(view.render().el);
	},
	addAll: function(){
		this.$el.html('');
		this.messages.each(this.addOne, this);
	}
}),
// a top level message
MessageView = Backbone.View.extend({
	render: function() {
		this.$el.html('<p> we have a message </p>');
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
