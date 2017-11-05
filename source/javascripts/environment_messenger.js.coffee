@node = new Node
		title: 'Messenger Demo'
		can_post: true
		message_push_enabled: true
		message_view_permission: [
			{name: "Group1", value: "aadfasdfasdfasdf1"},
			{name: "Group2", value: "aadfasdfasdfasdf2"},
			{name: "Group3", value: "aadfasdfasdfasdf3"},
			{name: "Group4", value: "aadfasdfasdfasdf4"},
		]
		message_reply_permission: [
			{name: "Group1", value: "aadfasdfasdfasdf1"},
			{name: "Group2", value: "aadfasdfasdfasdf2"},
			{name: "Group3", value: "aadfasdfasdfasdf3"},
			{name: "Group4", value: "aadfasdfasdfasdf4"},
		]
		message_reply_view_permission: [
			{name: "Group1", value: "aadfasdfasdfasdf1"},
			{name: "Group2", value: "aadfasdfasdfasdf2"},
			{name: "Group3", value: "aadfasdfasdfasdf3"},
			{name: "Group4", value: "aadfasdfasdfasdf4"},
		]
@view = new Backbone.View()


@node.collection = {
	get: -> {
		get: ->
			"http://development.yourapp-rails4.dev:3000/assets/cable.js"
	}
	url: ->
		"http://development.yourapp-rails4.dev:3000/api/v2"	
	getuuid: ->
		"other"
}

@initApp2 = (view, node) =>
	p = jQuery.Deferred()
	$ =>
		@view.setElement($ "body")
		_.defer =>
			p.resolve({})
			@view.trigger "changepage"
			window.messages.create({title:"demo", message:"Other"});
	p.promise()
