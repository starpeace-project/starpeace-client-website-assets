
path = require('path')
fs = require('fs-extra')

_ = require('lodash')
GifEncoder = require('gif-encoder')
Jimp = require('jimp')

PlanetAnimationRenderer = require('./planet-animation-renderer')
FileUtils = require('../utils/file-utils')

ANIMATION_WIDTH = 128
ANIMATION_HEIGHT = 128

ROTATION = 15
SLICES = 360 / ROTATION
FPS = SLICES / 4


render_frames = (map_texture) ->
  new Promise (done, error) ->
    Promise.all(_.map([0..SLICES], (degrees) ->
      PlanetAnimationRenderer.render_frame(map_texture, degrees * ROTATION, ANIMATION_WIDTH, ANIMATION_HEIGHT))
    )
    .then(done)
    .catch(error)

resize_frames = (map_animation_mask) -> (frames) ->
  mask = await Jimp.read(map_animation_mask)
  await Promise.all(_.map(frames, (frame) ->
    img = new Jimp({ data: frame, width: PlanetAnimationRenderer.WIDTH, height: PlanetAnimationRenderer.HEIGHT })
    frame = await img.resize(ANIMATION_WIDTH, ANIMATION_HEIGHT)
    frame.bitmap.data
  ))

generate_planet_animation = (map_image_file, map_animation_mask, map_animation_file) ->
  new Promise (done, error) ->
    PlanetAnimationRenderer.create_texture_from_file(map_image_file)
    .then render_frames
    .then resize_frames(map_animation_mask)
    .then (frames) ->
      gif = new GifEncoder(ANIMATION_WIDTH, ANIMATION_HEIGHT, {
        highWaterMark: 50 * 1024 * 1024
      })

      gif.setTransparent(0xff000000)
      gif.setRepeat(0)
      gif.setFrameRate(FPS)

      file = fs.createWriteStream(map_animation_file)
      gif.pipe(file)

      gif.writeHeader()

      for frame,index in frames
        gif.addFrame(frame)
        gif.read(1024 * 1024)

      console.log "added #{frames.length} frames"

      gif.finish()
      done(gif)


class GeneratePlanetAnimations
  @combine: (source_dir, maps_dir, target_dir) ->
    map_animation_mask = path.join(source_dir, 'planet-animation-mask.png')

    promises = []
    for file_path in FileUtils.read_all_files_sync(maps_dir, (file_path) -> file_path.endsWith('.json'))
      mapId = _.replace(path.basename(file_path), '.json', '')
      promises.push generate_planet_animation(path.join(maps_dir, "#{mapId}.bmp"), map_animation_mask, path.join(target_dir, "map.#{mapId}.animation.gif"))

    new Promise (done, error) ->
      console.log "Found #{promises.length} planet maps to animate"
      Promise.all(promises)
        .then done
        .catch error

module.exports = GeneratePlanetAnimations
