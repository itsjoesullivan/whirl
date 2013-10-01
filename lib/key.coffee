###
# An actual key
###
class Key extends Backbone.Model
  defaults:
    depressed: true
  initialize: (e) ->
    @set 'octave', e.octave
    @set 'index', e.index
    @set 'velocity', e.velocity
    Keyboard.on 'noteoff', (e) ->
      if e.octave is @get('octave') and e.index is @get('index')
        this.set 'depressed', false
