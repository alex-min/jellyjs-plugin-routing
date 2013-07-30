async = require('async')

resolveDependencies =  (jelly, tplfile, curDeps, cb) ->
    cb = cb || ->
    curDeps.deps ?= []
    deps = tplfile.getLastOfProperty('dependencies') || []
    if deps.length == 0
      cb(null, curDeps); cb = ->
      return
    async.each(deps, (dep, cb) ->
      file = jelly.getChildByIdRec(dep)
      if file == null
        cb(); cb = ->
        return
      controllerJs = jelly.getChildByIdRec(dep.replace('.tpl','.js'))
      controllerCoffee = jelly.getChildByIdRec(dep.replace('.tpl','.coffee'))
      controller = controllerCoffee || controllerJs
      executableContent = controller.getLastContentOfExtension('__exec')
      if executableContent == null
        cb(); cb = ->
        return

      # avoid executing multiple times the same dependency
      for curDep in curDeps.deps
        if curDep.name == controller.getId()
          cb(); cb = ->
          return

      if typeof executableContent.content != 'object' && typeof executableContent.content.oncall != 'function'
        cb(new Error("Controller '#{controller.getId()}' must provide an oncall function")); cb = ->
        return
      curDeps.deps.push({name:controller.getId(), oncall:executableContent.content.oncall})
      # the current file is always listed as a dependency
      if file.getId() == tplfile.getId()
        cb(); cb = ->
        return
      else
        resolveDependencies(jelly, file, curDeps, cb)
    , (err) ->
      if err
        cb(err); cb = ->
        return
      cb(null, curDeps); cb = ->
    )

executeDepencies = (deps, req, res, cb) ->
  finalData = {}
  async.each(deps.deps, (dep, cb) ->
    try
      dep.oncall({req:req, res:res}, (err, data) ->
        if err
          cb(err); cb = ->
          return
        data ?= {}
        finalData[dep.name.replace('.js','.tpl').replace('.coffee','.tpl')] = data
        cb(null, finalData); cb = ->
      )
      return
    catch e
      cb(new Error("#{dep.name} Controller: #{e.message}")); cb = ->
      return
  , (err) ->
    if err
      cb(err); cb = ->
      return
    cb(null, finalData)
  )

module.exports = {
  resolveDependencies:resolveDependencies
  executeDepencies:executeDepencies

  bindController: (route, verb, httpserver, jelly, namefile, cb) ->
    tplfile = jelly.getChildByIdRec(route.oncall.template)
    if tplfile == null
      cb(new Error("The 'template' id '#{route.oncall.name}' does not exist on route #{JSON.stringify(route)}")); cb = ->
      return
    content = tplfile.getLastContentOfExtension('__template')
    if content == null || typeof content.content != 'function'
      cb(new Error("Unable to route template '#{tplfile.getId}': The file has not been compiled before routing")); cb = ->
      return
    resolveDependencies(jelly, tplfile, {}, (err, deps) ->
      if err?
        cb(err); cb = ->
        return
      try
        httpserver[verb](route.url, (req, res) ->
          executeDepencies(deps, req, res, (err, finalData) ->
            res.send(content.content(finalData))
          )
        )
        cb(); cb = ->
      catch e
        cb(e); cb = ->
    )
    return
}