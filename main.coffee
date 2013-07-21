
parseRoute = (route, httpserver) ->
  return if typeof route.method == 'undefined' || route.method == null
  route.method ?= ['get']

  for method,i in route.method
    route.method[i] = method.toLowerCase()

  if typeof route.url == 'undefined' || route.url == null
    throw new Error("There is no url defined on route #{JSON.stringify(route)}");

  if typeof route['oncall'] == 'undefined' || route['oncall'] == null
    throw new Error("There is no oncall defined on route #{JSON.stringify(route)}");
  
  route.oncall.type ?= "rawview"

  for method in route.method
    if ['get','post','put','delete'].indexOf(method) == -1
      throw new Error("Invalid HTTP Verb on route #{JSON.stringify(route)}")
    if ['rawview'].indexOf(route.oncall.type) == -1
      throw new Error("Unsupported oncall route type: #{route.oncall.type}")
      httpserver[method](route.url, (res, req) ->
        res.send("TODO: IMPLEMENT RAWVIEWS")
      )

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

      for route in params.pluginParameters.routing.routes
        parseRoute(route, httpserver)
      cb(); cb = ->
    catch e
      cb(e)
  unload: (cb) ->
    cb()
}