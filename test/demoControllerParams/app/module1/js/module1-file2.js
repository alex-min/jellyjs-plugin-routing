module.exports = {
  oncall: function (params, cb) {
    cb(null, {TEST:params.req.query.id})
  } 
}