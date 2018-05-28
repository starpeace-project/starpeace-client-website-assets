
path = require('path')
fs = require('fs')


class Utils
  @format_color: (color) ->
    "#{color.toString().padStart(10)} (##{Number(color).toString(16).padStart(6, '0')}"

module.exports = Utils
