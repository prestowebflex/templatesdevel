@node = new Node
		title: 'Messenger Demo'
		can_post: true
		message_push_enabled: true
		message_view_permission: [
			{name: "Group1v", value: "aadfasdfasdfasdf1"},
			{name: "Group2v", value: "aadfasdfasdfasdf2"},
			{name: "Group3v", value: "aadfasdfasdfasdf3"},
			{name: "Group4v", value: "aadfasdfasdfasdf4"},
		]
		message_reply_permission: [
			{name: "Group1r", value: "aadfasdfasdfasdf1"},
			{name: "Group2r", value: "aadfasdfasdfasdf2"},
			{name: "Group3r", value: "aadfasdfasdfasdf3"},
			{name: "Group4r", value: "aadfasdfasdfasdf4"},
		]
		message_reply_view_permission: [
			{name: "Group1vr", value: "aadfasdfasdfasdf1"},
			{name: "Group2vr", value: "aadfasdfasdfasdf2"},
			{name: "Group3vr", value: "aadfasdfasdfasdf3"},
			{name: "Group4vr", value: "aadfasdfasdfasdf4"},
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
			start = new Date(Date.now()+1000);
			end = new Date(start.getTime()+20000000);
			message = {title:"demo", message:"Other", valid_to_set: false, valid_to: end, valid_from_set: false, valid_from: start}
			_.chain(Message.PERMISSION_NAMES).keys().each (key) ->
				message[key] = _.chain(node.get(key)).pluck("value").shuffle().first(_.random(1,4)).value()
			window.messages.create message
	p.promise()
