class Note extends Backbone.Model
  initialize: ->
    key = @get 'key'

    @set('waveform', Wavebank.get
      instrument: 'whirl'
      octave: key.get('octave')
      index: key.get('index')
      velocity: key.get('velocity')
    )

    @key.on('change:depressed', (obj, val) -> @stop())

  play: ->
    source = context.createBufferSource()
    source.buffer = @get('waveform').buffer
    source.connect(context.destination)
    source.noteOn(0)
    @set 'source', source
    @set 'playing', true

  stop: ->
    @get('source').noteOff(0)
