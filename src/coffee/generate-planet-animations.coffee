
path = require('path')
fs = require('fs-extra')

_ = require('lodash')
GifEncoder = require('gif-encoder')
sharp = require('sharp')

PlanetAnimationRenderer = require('./planet/planet-animation-renderer')

ANIMATION_WIDTH = 128
ANIMATION_HEIGHT = 128

# FIXME: TODO: add other planets
PLANETS = new Set(['earth'])
# FIXME: TODO: add other orientations
ORIENTATIONS = new Set(['0deg'])

ROTATION = 15
SLICES = 360 / ROTATION
FPS = SLICES / 4


PLANETS = [
  {
    id: 'planet-1'
    name: 'Mercury'
    map_id: 'aries'
  },
  {
    id: 'planet-2'
    name: 'Venus'
    map_id: 'ancoeus'
  },
  {
    id: 'planet-3'
    name: 'Earth'
    map_id: 'mondronia'
  },
  {
    id: 'planet-4'
    name: 'Mars'
    map_id: 'darkadia'
  },
  {
    id: 'planet-5'
    name: 'Jupiter'
    map_id: 'cymoril'
  }
]


render_frames = (map_texture) ->
  new Promise (done, error) ->
    Promise.all(_.map([0..SLICES], (degrees) ->
      PlanetAnimationRenderer.render_frame(map_texture, degrees * ROTATION, ANIMATION_WIDTH, ANIMATION_HEIGHT))
    )
    .then(done)
    .catch(error)

resize_frames = (map_animation_mask) -> (frames) ->
  new Promise (done, error) ->
    Promise.all(_.map(frames, (frame) ->
      new Promise (frame_done, frame_error) ->
        sharp(Buffer.from(frame), {
          raw: {
            width: PlanetAnimationRenderer.WIDTH
            height: PlanetAnimationRenderer.HEIGHT
            channels: 4
          }
        })
        .resize(ANIMATION_WIDTH, ANIMATION_HEIGHT)
        .toBuffer()
        .then((buffer) ->
          sharp(buffer, {
            raw: {
              width: ANIMATION_WIDTH
              height: ANIMATION_HEIGHT
              channels: 4
            }
          })
          .background({r:0, g:255, b:255, alpha:0})
          .overlayWith(map_animation_mask, { cutout: true })
          # .blur(0.5)
          .toBuffer()
          .then((masked_buffer) ->
            # improves gif transparency at border of planet
            for index in [0...(masked_buffer.length / 4)]
              if masked_buffer[index * 4 + 3] == 0
                masked_buffer[index * 4 + 0] = 0
                masked_buffer[index * 4 + 1] = 255
                masked_buffer[index * 4 + 2] = 255
                masked_buffer[index * 4 + 3] = 255
              true

            # add some blurring to soften edges
            sharp(masked_buffer, {
              raw: {
                width: ANIMATION_WIDTH
                height: ANIMATION_HEIGHT
                channels: 4
              }
            })
            .background({r:0, g:255, b:255, alpha:0})
            # .blur(0.6)
            .toBuffer()
            .then(frame_done)
          )
        )
        .catch frame_error
    ))
    .then done
    .catch error

generate_planet_animation = (map_image_file, map_animation_mask, map_animation_file) ->
  new Promise (done, error) ->
    PlanetAnimationRenderer.create_texture_from_file(map_image_file)
    .then render_frames
    .then resize_frames(map_animation_mask)
    .then (frames) ->
      gif = new GifEncoder(ANIMATION_WIDTH, ANIMATION_HEIGHT, {
        highWaterMark: 50 * 1024 * 1024
      })

      gif.setTransparent(0x00ffff)
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


console.log "\n===============================================================================\n"
console.log " generate-planet-animations.js - https://www.starpeace.io\n"
console.log " generate simple animations procedurally for each planet instance, including\n"
console.log " each associated map and tycoon buildings\n"
console.log " see README.md for more details"
console.log "\n===============================================================================\n"


root = process.cwd()
source_dir = path.join(root, process.argv[2])
assets_dir = path.join(root, process.argv[3])
target_dir = path.join(root, process.argv[4])
target_dir = path.join(target_dir, 'animations')

fs.mkdirsSync(target_dir)

console.log "input image directory: #{source_dir}"
console.log "input assets directory: #{assets_dir}"
console.log "output directory: #{target_dir}\n"

console.log "animation width: #{ANIMATION_WIDTH}"
console.log "animation height: #{ANIMATION_HEIGHT}"
console.log "animation fps: #{FPS}"

console.log "\n-------------------------------------------------------------------------------\n"

land_dir = path.join(assets_dir, 'land')
maps_dir = path.join(assets_dir, 'maps')

map_animation_mask = path.join(source_dir, 'planet-animation-mask.png')

promises = []
for planet in PLANETS
  map_image_file = path.join(maps_dir, "#{planet.map_id}.png")
  map_animation_file = path.join(target_dir, "planet.#{planet.id}.animation.gif")
  promises.push generate_planet_animation(map_image_file, map_animation_mask, map_animation_file)

Promise.all(promises)
  .then (gifs) ->
    console.log "all done"
  .catch (error) ->
    console.log "there was an error: #{error}"
