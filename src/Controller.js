// Generated by CoffeeScript 1.6.2
var Controller, SharedObject, jy, _Controller;

jy = require('jellyjs');

SharedObject = jy.Tools.implementing(jy.Logger, jy.TreeElement, _Controller = (function() {
  function _Controller() {}

  return _Controller;

})(), Controller = (function() {
  Controller.prototype._constructor_ = function() {
    this._parentConstructor_();
    return this._file = null;
  };

  function Controller() {
    this._constructor_();
  }

  Controller.prototype.getFile = function() {
    return this._file;
  };

  Controller.prototype.setFile = function(file) {
    return this._file = file;
  };

  return Controller;

})());

module.exports = Controller;
