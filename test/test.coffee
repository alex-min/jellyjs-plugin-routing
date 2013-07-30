pluginDir = __dirname + '/../'
toType = (obj) -> ({}).toString.call(obj).match(/\s([a-zA-Z]+)/)[1].toLowerCase()
assert = require('chai').assert;
async = require('async')
path = require('path')
request = require('request')

try
  jy = require('jellyjs')
catch e
  root = __dirname + '/../../../../'
  jy = require("#{root}/index.js")

portCount = 0;

populateWithHttp = (params, cb) ->
    jelly = new jy.Jelly()
    async.waterfall([
      (cb) ->
          httpServerPlugin = path.dirname(require.resolve('jellyjs-plugin-httpserver'))
          jelly.getPluginDirectoryList().readPluginFromPath(httpServerPlugin, 'httpserver', cb)
      # we execute manually the server before
      (dt, cb) ->
          portCount++;
          dt.getPluginInterface().oncall({}, {pluginParameters:{httpserver:{port:3000+portCount}}}, (err) ->
            cb()
          )
      (cb) ->
        jelly.getPluginDirectoryList().readPluginFromPath(pluginDir, 'routing', (err, dt) -> cb(err, dt))
      (dt, cb) ->
        dt.getPluginInterface().load((err) -> cb(err, dt))
      (dt, cb) ->
        dt.getPluginInterface().oncall({}, params, (err) ->
            cb(err)  
        )
    ], cb)
  #---------------

describe('#Plugin::routing', ->
  it('Should load the plugin', (cb) ->
    jelly = new jy.Jelly()
    jelly.getPluginDirectoryList().readPluginFromPath(pluginDir, 'routing', (err, dt) ->
      cb(err)
    )
  )  
  #-----------------
  it('Should return an error when no httpserver is loaded', (cb) ->
    jelly = new jy.Jelly()
    async.waterfall([
      (cb) ->
        jelly.getPluginDirectoryList().readPluginFromPath(pluginDir, 'routing', (err, dt) -> cb(err, dt))

      (dt, cb) -> dt.getPluginInterface().load((err) -> cb(err, dt))

      (dt, cb) ->
        dt.getPluginInterface().oncall({}, {pluginParameters:{}}, (err) ->
            try
              assert.equal(toType(err), 'error')
              cb()
            catch e
              cb(e)          
        )
    ], cb)
  )
  #-----------------
  it('Should raise an error if route.url is undefined', (cb) ->
    populateWithHttp({pluginParameters:{routing:{
      routes:[
        {
          method:["get"]
          oncall:{}
        }
      ]
    }}}, (err) ->
      try
        assert.equal(toType(err), 'error')
        cb()
      catch e
        cb(e)
    )
  )
  #---------------
  it('Should raise an error if there is an invalid method as an HTTP Verb', (cb) ->
    populateWithHttp({pluginParameters:{routing:{
      routes:[
        {
          method:['invalid']
          url:'/'
          oncall:{}
        }
      ]
    }}}, (err) ->
      try
        assert.equal(toType(err), 'error')
        cb()
      catch e
        cb(e)
    )
  )
  #---------------
  it('Should raise an error if there is an invalid method as oncall', (cb) ->
    populateWithHttp({pluginParameters:{routing:{
      routes:[
        {
          method:['get', 'post']
          url:'/'
          oncall:{type:"invalid"}
        }
      ]
    }}}, (err) ->
      try
        assert.equal(toType(err), 'error')
        cb()
      catch e
        cb(e)
    )
  )
  #---------------  
  it('Should route rawviews', (cb) ->
      jelly = new jy.Jelly()
      jelly.setRootDirectory("#{__dirname}/demo")
      async.series([
        (cb) -> jelly.readJellyConfigurationFile( (err) -> cb(err,null)),
        (cb) -> jelly.readAllGeneralConfigurationFiles( (err) -> cb(err,null))
        (cb) ->
          jelly.getPluginDirectoryList().readPluginFromPath(pluginDir, 'routing', (err, dt) ->
            cb(err)
          )
        (cb) ->
          httpServerPlugin = path.dirname(require.resolve('jellyjs-plugin-httpserver'))
          jelly.getPluginDirectoryList().readPluginFromPath(httpServerPlugin, 'httpserver', cb)
        (cb) ->
          httpServerPlugin = path.dirname(require.resolve('jellyjs-plugin-template'))
          jelly.getPluginDirectoryList().readPluginFromPath(httpServerPlugin, 'template', cb)
        (cb) ->
          # changing the port
          config = jelly.getChildByIdRec("conf/assets.json")
          cf = config.getLastExecutableContent()
          cf.pluginParameters.httpserver.port = 8101
          cb()
        (cb) -> jelly.applyPluginsSpecified(true, (err) -> cb(err))
        (cb) ->
          request("http://127.0.0.1:8101", (err, response, body) ->
            if err?
              cb(err); cb = ->
              return
            try
              assert.equal(response.body, "TPL TEST")
              cb()
            catch e
              cb(e)
          )
      ], (err) ->
        cb(err)
      )
  )
  #---------------
  it('Should route rawviews', (cb) ->
    jelly = new jy.Jelly()
    jelly.boot({
      directory:"#{__dirname}/demo"
      packagePlugins:['httpserver','template']
      folderPlugins:[{name:'routing', directory:pluginDir}]
      onBeforeApplyPlugins: (cb) ->
        config = jelly.getChildByIdRec("conf/assets.json")
        cf = config.getLastExecutableContent()
        cf.pluginParameters.httpserver.port = 8102
        cb()
      localRequire: (elm, cb) ->
        try
          cb(null, require.resolve(elm))  
        catch e
          cb(e)   
    }, (err) ->
      cb(err)
    )
  )
  #---------------
  it('Should route controllers', (cb) ->
    jelly = new jy.Jelly()
    jelly.boot({
      directory:"#{__dirname}/demoController"
      packagePlugins:['httpserver','template', 'compilejs']
      folderPlugins:[{name:'routing', directory:pluginDir}]
      onBeforeApplyPlugins: (cb) ->
        config = jelly.getChildByIdRec("conf/assets.json")
        cf = config.getLastExecutableContent()
        cf.pluginParameters.httpserver.port = 8103
        cb()
      localRequire: (elm, cb) ->
        try
          cb(null, require.resolve(elm))  
        catch e
          cb(e)   
    }, (err) ->
      if err
        cb(err); cb = ->
        return
      request("http://127.0.0.1:8103", (err, response, body) ->
            if err?
              cb(err); cb = ->
              return
            try
              assert.equal(body, "TPL TEST 1TPL TEST22")
              cb()
            catch e
              cb(e)
      )
    )
  )
  #---------------
  it('Should pass parameters to the controller', (cb) ->
    jelly = new jy.Jelly()
    jelly.boot({
      directory:"#{__dirname}/demoControllerParams"
      packagePlugins:['httpserver','template', 'compilejs']
      folderPlugins:[{name:'routing', directory:pluginDir}]
      onBeforeApplyPlugins: (cb) ->
        config = jelly.getChildByIdRec("conf/assets.json")
        cf = config.getLastExecutableContent()
        cf.pluginParameters.httpserver.port = 8104
        cb()
      localRequire: (elm, cb) ->
        try
          cb(null, require.resolve(elm))  
        catch e
          cb(e)   
    }, (err) ->
      if err
        cb(err); cb = ->
        return
      file = jelly.getChildByIdRec('module1-file1.js')
      request("http://127.0.0.1:8104/?id=helloWorld", (err, response, body) ->
            if err?
              cb(err); cb = ->
              return
            try
              assert.equal(body, "TPL TEST helloWorldTPL TEST2helloWorld")
              cb()
            catch e
              cb(e)
      )
    )
  )
)
