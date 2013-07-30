jy = require('jellyjs')

SharedObject = jy.Tools.implementing jy.Logger, jy.TreeElement, class _Controller
class Controller
  _constructor_: () ->
    @_parentConstructor_()
    @_file = null
  constructor:() -> @_constructor_()

  getFile: -> @_file
  setFile: (file) -> @_file = file

  


module.exports = Controller