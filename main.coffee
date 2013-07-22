
parseRoute = (route, httpserver, jelly) ->
  return if typeof route.method == 'undefined' || route.method == null
  route.method ?= ['get']

  for method,i in route.method
    route.method[i] = method.toLowerCase()

  if typeof route.url == 'undefined' || route.url == null
    throw new Error("There is no url defined on route #{JSON.stringify(route)}");

  if typeof route['oncall'] == 'undefined' || route['oncall'] == null
    throw new Error("There is no oncall defined on route #{JSON.stringify(route)}");
  
  route.oncall.type ?= "rawview"

  for verb in route.method
    if ['get','post','put','delete'].indexOf(verb) == -1
      throw new Error("Invalid HTTP Verb on route #{JSON.stringify(route)}")
    if ['rawview'].indexOf(route.oncall.type) == -1
      throw new Error("Unsupported oncall route type: #{route.oncall.type}")

    file = jelly.getChildByIdRec(route.oncall.name)
    if file == null
      throw new Error("The id '#{route.oncall.name}' does not exist on route #{JSON.stringify(route)}");
    tpl = file.getLastContentOfExtension('__template')
    httpserver[verb](route.url, (res, req) ->
      req.send(tpl.content())
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

      jelly = @getParentOfClass('Jelly')
      if jelly == null
        cb(new Error("The routing plugin must bound to a Jelly class")); cb = ->
        return
      for route in params.pluginParameters.routing.routes
        parseRoute(route, httpserver, jelly)
      cb(); cb = ->
    catch e
      cb(e)
  unload: (cb) ->
    cb()
}