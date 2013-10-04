
###
# Maps paths to their buffers. Lazy-loaded.
###
bufferMap = {}

###
# Specific velocity/pitch map to paths
####
waveMap = [
  {
    pitch: 'C4'
    loudness: 'p'
    path: '/instruments/whirl/c4-p.wav'
  }
  {
    pitch: 'C4'
    loudness: 'f'
    path: '/instruments/whirl/c4-p.wav'
  }
]

###
# Map loudness to velocity
#
# Source: http://en.wikipedia.org/wiki/Dynamics_(music)
###
velocityMap = [
  {
    loudness: 'ppp',
    velocity: 16
  }
  {
    loudness: 'pp',
    velocity: 33
  }
  {
    loudness: 'p',
    velocity: 49
  }
  {
    loudness: 'mp',
    velocity: 64
  }
  {
    loudness: 'mf',
    velocity: 80
  }
  {
    loudness: 'f',
    velocity: 96
  }
  {
    loudness: 'ff',
    velocity: 112
  }
  {
    loudness: 'fff',
    velocity: 127
  }
]

###
# Convert a velocity to a loudness
###
velocityToLoudness = (velocity) ->
  _(velocityMap).chain()
    .find (pt) ->
      pt.velocity >= velocity
    .pluck 'loudness'
    .value()

###
# Map a note to its index in the octave
###
noteMap = [
  'A'
  'B'
  'C'
  'D'
  'E'
  'F'
  'G'
]


###
# Convert a pitch to a index
# ex.: A5 -> (1 + 5*12)
###
pitchToIndex = (pitch) ->
  octave = parseInt pitch.substring(1)
  note = noteMap[ pitch.substring(0,1).toUpperCase() ]
  note + octave * 12


###
# Map a velocity/pitch event to the path of the waveform
###
eventToPath = (ev, waveMap) ->
  targetLoudness = velocityToLoudness ev.velocity
  targetPitch = ev.pitch
  notes = _(waveMap).chain()
    .filter (pt) ->
      pt.loudness is targetLoudness
    .sortBy (pt) ->
      Math.abs ( pitchToIndex(pt.pitch) - pitchToIndex(targetPitch) )
    .value()
  unless notes.length
    throw "No matching note."
  notes[0].path
      

###
# Lazy-load a waveform, returning its buffer.
###
getBuffer = (path, cb) ->
  if bufferMap[path]
    cb null, bufferMap[path]
  else
    request = new XMLHttpRequest()
    request.open 'URL', path, true
    request.responseType = 'arrayBuffer'
    request.onload = ->
      context.decodeAudioData request.response, (buffer) ->
        cb null, buffer # Success
      , cb # Error
###
keyboard.on 'note', (ev) ->
  path = eventToPath ev
  getBuffer path, (err, buffer) ->
    if err
      throw err
    else
      source = context.createBufferSource()
      source.buffer = buffer
      source.connect context.destination
      source.noteOn(0)
###
