
path = require('path')
fs = require('fs-extra')
_ = require('lodash')

MapImage = require('../map/map-image')


write_map_images = (output_dir) -> (map_images) ->
  new Promise (done) ->
    fs.mkdirsSync(output_dir)

    for image in map_images
      bmp_map_file = path.join(output_dir, "map.#{image.name.toLowerCase()}.texture.bmp")
      fs.copySync(image.full_path, bmp_map_file)
      console.log "map #{image.full_path} copied to #{bmp_map_file}"

    done([])


class CombineMapManifest
  @combine: (maps_dir, target_dir) ->
    new Promise (done, error) ->
      MapImage.load(maps_dir)
        .then write_map_images(target_dir)
        .then done
        .catch error

module.exports = CombineMapManifest
