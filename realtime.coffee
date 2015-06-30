###
Copyright 2013 Google Inc. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
###
"use strict"

###
@fileoverview Common utility functionality for Google Drive Realtime API,
including authorization and file loading. This functionality should serve
mostly as a well-documented example, though is usable in its own right.
###

###
@namespace Realtime client utilities namespace.
###
window.rtclient = {}

###
OAuth 2.0 scope for installing Drive Apps.
@const
###
rtclient.INSTALL_SCOPE = "https://www.googleapis.com/auth/drive.install"

###
OAuth 2.0 scope for opening and creating files.
@const
###
rtclient.FILE_SCOPE = "https://www.googleapis.com/auth/drive.file"

###
OAuth 2.0 scope for accessing the user's ID.
@const
###
rtclient.OPENID_SCOPE = "openid"

###
MIME type for newly created Realtime files.
@const
###
rtclient.REALTIME_MIMETYPE = "application/vnd.google-apps.drive-sdk"

###
Parses the hash parameters to this page and returns them as an object.
@function
###

rtclient.getParamsHelper = (string) ->
  params = {}
  hashFragment = string
  if hashFragment
    
    # split up the query string and store in an object
    paramStrs = hashFragment.slice(1).split("&")
    i = 0

    while i < paramStrs.length
      paramStr = paramStrs[i].split("=")
      params[paramStr[0]] = unescape(paramStr[1])
      i++
  console.log params
  params

rtclient.getParams = ->
  rtclient.getParamsHelper window.location.hash

rtclient.getQueryParams = ->
  rtclient.getParamsHelper window.location.search  

###
Instance of the query parameters.
###
rtclient.params = rtclient.getParams()
rtclient.query = rtclient.getQueryParams()

###
Fetches an option from options or a default value, logging an error if
neither is available.
@param options {Object} containing options.
@param key {string} option key.
@param defaultValue {Object} default option value (optional).
###
rtclient.getOption = (options, key, defaultValue) ->
  value = (if options[key] is `undefined` then defaultValue else options[key])
  console.error key + " should be present in the options."  if value is `undefined`
  console.log value
  value


###
Creates a new Authorizer from the options.
@constructor
@param options {Object} for authorizer. Two keys are required as mandatory, these are:

1. "clientId", the Client ID from the console
###
rtclient.Authorizer = (options) ->
  @clientId = rtclient.getOption(options, "clientId")
  
  # Get the user ID if it's available in the state query parameter.
  @userId = rtclient.params["userId"]
  @authButton = document.getElementById(rtclient.getOption(options, "authButtonElementId"))
  return


###
Start the authorization process.
@param onAuthComplete {Function} to call once authorization has completed.
###
rtclient.Authorizer::start = (onAuthComplete) ->
  _this = this
  gapi.load "auth:client,drive-realtime,drive-share", ->
    _this.authorize onAuthComplete
    return

  return


###
Reauthorize the client with no callback (used for authorization failure).
@param onAuthComplete {Function} to call once authorization has completed.
###
rtclient.Authorizer::authorize = (onAuthComplete) ->
  clientId = @clientId
  userId = @userId
  _this = this
  handleAuthResult = (authResult) ->
    if authResult and not authResult.error
      _this.authButton.disabled = true
      _this.fetchUserId onAuthComplete
    else
      _this.authButton.disabled = false
      _this.authButton.onclick = authorizeWithPopup
    return

  authorizeWithPopup = ->
    gapi.auth.authorize
      client_id: clientId
      scope: [
        rtclient.INSTALL_SCOPE
        rtclient.FILE_SCOPE
        rtclient.OPENID_SCOPE
      ]
      user_id: userId
      immediate: false
    , handleAuthResult
    console.log clientId
    return

  
  # Try with no popups first.
  gapi.auth.authorize
    client_id: clientId
    scope: [
      rtclient.INSTALL_SCOPE
      rtclient.FILE_SCOPE
      rtclient.OPENID_SCOPE
    ]
    user_id: userId
    immediate: true
  , handleAuthResult
  return


###
Fetch the user ID using the UserInfo API and save it locally.
@param callback {Function} the callback to call after user ID has been
fetched.
###
rtclient.Authorizer::fetchUserId = (callback) ->
  _this = this
  gapi.client.load "oauth2", "v2", ->
    gapi.client.oauth2.userinfo.get().execute (resp) ->
      _this.userId = resp.id  if resp.id
      callback()  if callback
      return

    return

  return


###
Creates a new Realtime file.
@param title {string} title of the newly created file.
@param mimeType {string} the MIME type of the new file.
@param callback {Function} the callback to call after creation.
###
rtclient.createRealtimeFile = (title, mimeType, callback) ->
  gapi.client.load "drive", "v2", ->
    gapi.client.drive.files.insert(resource:
      mimeType: mimeType
      title: title
    ).execute callback
    return

  return


###
Fetches the metadata for a Realtime file.
@param fileId {string} the file to load metadata for.
@param callback {Function} the callback to be called on completion, with signature:

function onGetFileMetadata(file) {}

where the file parameter is a Google Drive API file resource instance.
###
rtclient.getFileMetadata = (fileId, callback) ->
  gapi.client.load "drive", "v2", ->
    gapi.client.drive.files.get(fileId: fileId).execute callback
    return

  return


###
Parses the state parameter passed from the Drive user interface after Open
With operations.
@param stateParam {Object} the state query parameter as an object or null if
parsing failed.
###
rtclient.parseState = (stateParam) ->
  try
    stateObj = JSON.parse(stateParam)
    return stateObj
  catch e
    return null
  return


###
Handles authorizing, parsing query parameters, loading and creating Realtime
documents.
@constructor
@param options {Object} options for loader. Four keys are required as mandatory, these are:

1. "clientId", the Client ID from the console
2. "initializeModel", the callback to call when the model is first created.
3. "onFileLoaded", the callback to call when the file is loaded.

and one key is optional:

1. "defaultTitle", the title of newly created Realtime files.
###
rtclient.RealtimeLoader = (options) ->
  
  # Initialize configuration variables.
  @onFileLoaded = rtclient.getOption(options, "onFileLoaded")
  @newFileMimeType = rtclient.getOption(options, "newFileMimeType", rtclient.REALTIME_MIMETYPE)
  @initializeModel = rtclient.getOption(options, "initializeModel")
  @registerTypes = rtclient.getOption(options, "registerTypes", ->
  )
  @afterAuth = rtclient.getOption(options, "afterAuth", ->
  )
  @autoCreate = rtclient.getOption(options, "autoCreate", false) # This tells us if need to we automatically create a file after auth.
  @defaultTitle = rtclient.getOption(options, "defaultTitle", "New Realtime File")
  @authorizer = new rtclient.Authorizer(options)
  return


###
Redirects the browser back to the current page with an appropriate file ID.
@param fileIds {Array.} the IDs of the files to open.
@param userId {string} the ID of the user.
###
rtclient.RealtimeLoader::redirectTo = (fileIds, userId) ->
  params = []
  params.push "fileIds=" + fileIds.join(",")  if fileIds
  params.push "userId=" + userId  if userId
  
  # Naive URL construction.
  newUrl = (if params.length is 0 then "./" else ("./#" + params.join("&")))
  
  # Using HTML URL re-write if available.
  if window.history and window.history.replaceState
    window.history.replaceState "Google Drive Realtime API Playground", "Google Drive Realtime API Playground", newUrl
  else
    window.location.href = newUrl
  
  # We are still here that means the page didn't reload.
  rtclient.params = rtclient.getParams()
  for index of fileIds
    gapi.drive.realtime.load fileIds[index], @onFileLoaded, @initializeModel, @handleErrors
  return


###
Starts the loader by authorizing.
###
rtclient.RealtimeLoader::start = ->
  
  # Bind to local context to make them suitable for callbacks.
  _this = this
  @authorizer.start ->
    _this.registerTypes()  if _this.registerTypes
    _this.afterAuth()  if _this.afterAuth
    _this.load()
    return

  return


###
Handles errors thrown by the Realtime API.
###
rtclient.RealtimeLoader::handleErrors = (e) ->
  if e.type is gapi.drive.realtime.ErrorType.TOKEN_REFRESH_REQUIRED
    authorizer.authorize()
  else if e.type is gapi.drive.realtime.ErrorType.CLIENT_ERROR
    alert "An Error happened: " + e.message
    window.location.href = "/"
  else if e.type is gapi.drive.realtime.ErrorType.NOT_FOUND
    alert "The file was not found. It does not exist or you do not have read access to the file."
    window.location.href = "/"
  return


###
Loads or creates a Realtime file depending on the fileId and state query
parameters.
###
rtclient.RealtimeLoader::load = ->
  fileIds = rtclient.params["fileIds"]?.split(",")
  userId = @authorizer.userId
  state = rtclient.params["state"]
  
  # Creating the error callback.
  authorizer = @authorizer

  debugger
  
  # We have file IDs in the query parameters, so we will use them to load a file.
  if fileIds
    for index of fileIds
      gapi.drive.realtime.load fileIds[index], @onFileLoaded, @initializeModel, @handleErrors
    return
  
  # We have a state parameter being redirected from the Drive UI. We will parse
  # it and redirect to the fileId contained.
  else if state
    stateObj = rtclient.parseState(state)
    
    # If opening a file from Drive.
    if stateObj.action is "open"
      fileIds = stateObj.ids
      userId = stateObj.userId
      @redirectTo fileIds, userId
      return
  @createNewFileAndRedirect()  if @autoCreate
  return


###
Creates a new file and redirects to the URL to load it.
###
rtclient.RealtimeLoader::createNewFileAndRedirect = ->
  
  # No fileId or state have been passed. We create a new Realtime file and
  # redirect to it.
  _this = this
  rtclient.createRealtimeFile @defaultTitle, @newFileMimeType, (file) ->
    if file.id
      _this.redirectTo [file.id], _this.authorizer.userId
    
    # File failed to be created, log why and do not attempt to redirect.
    else
      console.error "Error creating file."
      console.error file
    return

  return