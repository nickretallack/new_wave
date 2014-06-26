CLIENT_ID = '750901531017-o1tkotf27ckopad2516dfcc1qeok9oq3.apps.googleusercontent.com'
SCOPES = [
	'https://www.googleapis.com/auth/drive.file'
	'https://www.googleapis.com/auth/userinfo.email'
	'https://www.googleapis.com/auth/userinfo.profile'
]


gapi.load "auth:client,drive-realtime,drive-share", ->


	auth_response = (response) ->
		if not response
			gapi.auth.authorize {'client_id': CLIENT_ID, 'scope': SCOPES, 'immediate': false}, auth_response
		else
			loaded = ->
				console.log 'loaded'

			init = ->
				console.log 'init'

			error = ->
				console.log 'error'

			gapi.drive.realtime.load 'chat1', loaded, init, error		

	gapi.auth.authorize {'client_id': CLIENT_ID, 'scope': SCOPES.join(' '), 'immediate': true}, auth_response


