
class ConsoleProgressUpdater
  constructor: (@total_progress) ->
    @current_progress = 0

  next: () ->
    @current_progress += 1

    process.stdout.write '.'
    process.stdout.write ''.padStart(74 - @current_progress % 74, ' ') if @current_progress == @total_progress
    process.stdout.write "#{Math.round(100 * @current_progress / @total_progress).toString().padStart(4, ' ')}%\n" if @current_progress % 74 == 0 || @current_progress == @total_progress
    process.stdout.write '\n' if @current_progress == @total_progress

module.exports = ConsoleProgressUpdater
