_ = require('lodash')
path = require('path')
fs = require('fs-extra')
GifEncoder = require('gif-encoder')
Jimp = require('jimp')

PlanetAnimationRenderer = require('./planet-animation-renderer')
FileUtils = require('../utils/file-utils')

ANIMATION_WIDTH = 128
ANIMATION_HEIGHT = 128

ROTATION = 15
SLICES = 360 / ROTATION
FPS = SLICES / 4


generate_planet_animation = (map_image_file, map_animation_file) ->
  map_texture = await PlanetAnimationRenderer.create_texture_from_file(map_image_file)
  console.log "Texture created from file #{map_image_file}"

  frames = await Promise.all(_.map([0..SLICES], (degrees) ->
    PlanetAnimationRenderer.render_frame(map_texture, degrees * ROTATION, ANIMATION_WIDTH, ANIMATION_HEIGHT)
  ))
  console.log "Rendered #{frames.length} frames"

  frames = await Promise.all(_.map(frames, (frame) ->
    img = new Jimp({ data: frame, width: PlanetAnimationRenderer.WIDTH, height: PlanetAnimationRenderer.HEIGHT })
    frame = await img.resize(ANIMATION_WIDTH, ANIMATION_HEIGHT)
    frame.bitmap.data
  ))
  console.log "Resized #{frames.length} frames"

  console.log "Saving animation..."
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

  gif.finish()
  console.log "Animation with #{frames.length} frames saved to #{map_animation_file}\n"
  gif


class GeneratePlanetAnimations
  @combine: (source_dir, maps_dir, target_dir) ->
    mapIds = _.map(FileUtils.read_all_files_sync(maps_dir, (file_path) -> file_path.endsWith('.json')).sort(), (p) -> _.replace(path.basename(p), '.json', ''))
    console.log "\nFound #{mapIds.length} planet maps to animate\n"

    for mapId in mapIds
      console.log "Generating animation for planet map #{mapId}"
      await generate_planet_animation(path.join(maps_dir, "#{mapId}.png"), path.join(target_dir, "map.#{mapId}.animation.gif"))

module.exports = GeneratePlanetAnimations
