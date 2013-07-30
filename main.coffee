async = require('async')

Controller = require('./src/Controller')
controllerRender = require('./src/controllerRender')

parseRoute = (route, httpserver, jelly, cb) ->
  try
    if typeof route.method == 'undefined' || route.method == null
      cb(); cb = ->
      return
    route.method ?= ['get']

    for method,i in route.method
      route.method[i] = method.toLowerCase()

    if typeof route.url == 'undefined' || route.url == null
      cb(new Error("There is no url defined on route #{JSON.stringify(route)}")); cb = ->
      return

    if typeof route['oncall'] == 'undefined' || route['oncall'] == null
      cb(new Error("There is no oncall defined on route #{JSON.stringify(route)}")); cb = ->
      return

    route.oncall.type ?= "rawview"

    async.each(route.method, (verb, cb) ->
      if ['get','post','put','delete'].indexOf(verb) == -1
        cb(new Error("Invalid HTTP Verb '#{verb}' on route #{JSON.stringify(route)}")); cb = ->
        return
      if ['rawview','controller'].indexOf(route.oncall.type) == -1
        cb(new Error("Unsupported oncall route type: #{route.oncall.type} on route #{JSON.stringify(route)}")); cb = ->
        return
      file = jelly.getChildByIdRec(route.oncall.name)
      if file == null
        cb(new Error("The id '#{route.oncall.name}' does not exist on route #{JSON.stringify(route)}"));cb = ->
        return
      tpl = file.getLastContentOfExtension('__template')
      if route.oncall.type == 'rawview'
        httpserver[verb](route.url, (res, req) ->
          if typeof tpl.content == 'string'
            req.send(tpl.content)
          else
            req.send(tpl.content())
        )
        cb(); cb = ->
      else if route.oncall.type == 'controller'
        controllerRender.bindController(route, verb, httpserver, jelly, file, (err) ->
          cb(err)
        )
    , cb)
  catch e
    cb(e); cb = ->


module.exports = {
  load: (cb) ->
    cb()
  oncall: (onj, params, cb) ->
    try
      params.pluginParameters.routing ?= {}
      params.pluginParameters.routing.routes ?= []
      
      httpserver = @getSharedObjectManager().getObject('httpserver', 'server')
      if httpserver == null
        cb(new Error("No httpserver is registred when loading the routing plugin")); cb = ->
        return
      httpserver = httpserver.getCurrentContent()
      if httpserver == null
        cb(new Error("No httpserver is registred when loading the routing plugin")); cb = ->
        return

      jelly = @getParentOfClass('Jelly')
      if jelly == null
        cb(new Error("The routing plugin must bound to a Jelly class")); cb = ->
        return
      async.each(params.pluginParameters.routing.routes, (route, cb) ->
        parseRoute(route, httpserver, jelly, cb)
      , (err) ->
        cb(err)
      )
    catch e
      cb(e)
  unload: (cb) ->
    cb()
}