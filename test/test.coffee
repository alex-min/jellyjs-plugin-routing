pluginDir = __dirname + '/../'
toType = (obj) -> ({}).toString.call(obj).match(/\s([a-zA-Z]+)/)[1].toLowerCase()
assert = require('chai').assert;
async = require('async')
path = require('path')


try
  jy = require('jellyjs')
catch e
  root = __dirname + '/../../../../'
  jy = require("#{root}/index.js")


populateWithHttp = (params, cb) ->
    jelly = new jy.Jelly()
    async.waterfall([
      (cb) ->
          httpServerPlugin = path.dirname(require.resolve('jellyjs-plugin-httpserver'))
          jelly.getPluginDirectoryList().readPluginFromPath(httpServerPlugin, 'httpserver', cb)
      # we execute manually the server before
      (dt, cb) ->
          dt.getPluginInterface().oncall({}, {pluginParameters:{httpserver:{port:9876}}}, (err) ->
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
  
  it('Should transform everything into templates', (cb) ->
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
        (cb) -> jelly.applyPluginsSpecified(true, (err) -> cb(err))
        (cb) ->
          try
            file = jelly.getChildByIdRec('module1-file1.tpl')
            content = file.getCurrentContent()
            assert.equal(content.extension, '__template')
            assert.equal(toType(content.content), 'function')
            assert.equal(content.content(), 'TPL TEST')
            cb()
          catch e
            cb(e)
      ], (err) ->
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

)
