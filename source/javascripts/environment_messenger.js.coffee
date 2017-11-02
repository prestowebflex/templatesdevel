@node = new Node()
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
