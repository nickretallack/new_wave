# class Comment
# gapi.drive.realtime.custom.registerType Comment, 'Comment'
# Comment.prototype.text = gapi.drive.realtime.custom.collaborativeField 'text'
# Comment.prototype.children = gapi.drive.realtime.custom.collaborativeList 'text'


###
This function is called the first time that the Realtime model is created
for a file. This function should be used to initialize any values of the
model. In this case, we just create the single string model that will be
used to control our text box. The string has a starting value of 'Hello
Realtime World!', and is named 'text'.
@param model {gapi.drive.realtime.Model} the Realtime root model object.
###
initializeModel = (model) ->
	# string = model.createString "Hello Realtime World!"
	root = model.getRoot()
	comments = model.createList()
	root.set 'comments', comments

	# alpha_comment = model.createMap
	# 	text: model.createString "First!"

	# comments = model.createList([alpha_comment])
	# root.set 'comments', comments
	return

###
This function is called when the Realtime file has been loaded. It should
be used to initialize any user interface components and event handlers
depending on the Realtime model. In this case, create a text control binder
and bind it to our string model that we created in initializeModel.
@param doc {gapi.drive.realtime.Document} the Realtime document.
###

KEYCODES = enter:13

class Thread
	constructor: ({@model, @node}) ->
		for comment in @model.asArray()
			new Comment
				model: comment
				thread: @

		@make_new_comment()

	make_new_comment: ->
		@new_comment = new Comment
			thread: @

	render: ->
		@node = $ '<div class="replies"></div>'

	post: (comment) ->
		@model.push comment.model

		if comment is @new_comment
			@make_new_comment()

class Comment
	constructor: ({@model, @thread}) ->
		@render()
		@create_model() if not @model?
		# @child_thread = new Thread

	create_model: ->
		@model = model.createMap
			text: model.createString()

	render: ->
		@node = $ '<div class="comment"></div>'
		@text_node = $ '<textarea></textarea>'
		@node.append @text_node
		# @node.append @replies_node
		@thread.node.append @node

		# Typing immediately posts the comment
		if not @model

			# This line is ommitted from both of these handlers because we can assume it is the case:
			# if @ is @thread.new_comment

			spawn_next_comment = (event) =>
				@thread.post @
				gapi.drive.realtime.databinding.bindString @model.get('text'), @text_node[0]
				# @text_node.off 'keypress', spawn_next_comment

			@text_node.one 'keypress', spawn_next_comment


			look_for_enter = (event) =>
				if event.which is KEYCODES.enter and @text_node.val()
					@thread.new_comment.text_node.focus()
					@text_node.off 'keypress', look_for_enter

			@text_node.on 'keypress', look_for_enter

		else
			gapi.drive.realtime.databinding.bindString @model.get('text'), @text_node[0]

register_types = ->
	# gapi.drive.realtime.custom.registerType Comment, 'Comment'
	# Comment.prototype.text = gapi.drive.realtime.custom.collaborativeField 'text'
	# Comment.prototype.replies = gapi.drive.realtime.custom.collaborativeField 'replies'

model = null

onFileLoaded = (doc) ->

	# variables
	thread_node = $(document.body)
	model = doc.getModel()
	root = model.getRoot()
	thread = root.get 'comments'

	# Render
	# wrap the model with things
	new Thread
		model: thread
		node: thread_node

	# alpha_comment = model.createMap
	# 	text: model.createString "First!"

	# comments = model.createList([alpha_comment])
	# root.set 'comments', comments



	# comments = root.get('comments')
	# for comment in comments.asArray()
	# 	comment_node = $ '<div class="comment"></div>'
	# 	textarea = $ '<textarea></textarea>'
	# 	comment_node.append textarea
	# 	thread_node.append comment_node
	# 	gapi.drive.realtime.databinding.bindString comment.get('text'), textarea[0]



	# model.addEventListener gapi.drive.realtime.EventType.UNDO_REDO_STATE_CHANGED, onUndoRedoStateChanged
	return

###
Options for the Realtime loader.
###

###
Client ID from the console.
###

###
The ID of the button to click to authorize. Must be a DOM element ID.
###

###
Function to be called when a Realtime model is first created.
###

###
Autocreate files right after auth automatically.
###

###
The name of newly created Drive files.
###

###
The MIME type of newly created Drive Files. By default the application
specific MIME type will be used:
application/vnd.google-apps.drive-sdk.
###
# Using default.

###
Function to be called every time a Realtime file is loaded.
###

###
Function to be called to inityalize custom Collaborative Objects types.
###
# No action.

###
Function to be called after authorization and before loading files.
###
# No action.

###
Start the Realtime loader with the options.
###
startRealtime = ->
	realtimeLoader = new rtclient.RealtimeLoader(realtimeOptions)
	realtimeLoader.start()
	return
realtimeOptions =
	clientId: "750901531017-tr6fb08mn5kacnd1suht48uj8762dkc5.apps.googleusercontent.com"
	authButtonElementId: "authorizeButton"
	initializeModel: initializeModel
	autoCreate: true
	defaultTitle: "New Wave2"
	newFileMimeType: null
	onFileLoaded: onFileLoaded
	registerTypes: register_types
	afterAuth: null

startRealtime()