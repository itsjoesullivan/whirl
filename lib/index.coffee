
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
    loudness: 'ppp'
    path: '/instruments/whirl-garageband/c4-ppp.wav'
  }
  {
    pitch: 'C4'
    loudness: 'pp'
    path: '/instruments/whirl-garageband/c4-pp.wav'
  }
  {
    pitch: 'C4'
    loudness: 'p'
    path: '/instruments/whirl-garageband/c4-p.wav'
  }
  {
    pitch: 'C4'
    loudness: 'mp'
    path: '/instruments/whirl-garageband/c4-mp.wav'
  }
  {
    pitch: 'C4'
    loudness: 'mf'
    path: '/instruments/whirl-garageband/c4-mf.wav'
    path: 'http://localhost:8080/instruments/whirl-garageband/c4-mf.wav'
  }
  {
    pitch: 'C4'
    loudness: 'f'
    path: '/instruments/whirl-garageband/c4-f.wav'
  }
  {
    pitch: 'C4'
    loudness: 'ff'
    path: '/instruments/whirl-garageband/c4-ff.wav'
  }
  {
    pitch: 'C4'
    loudness: 'fff'
    path: '/instruments/whirl-garageband/c4-fff.wav'
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
  pt = _(velocityMap).find (pt) ->
    pt.velocity >= velocity
  pt.loudness

###
# Map a note to its index in the octave
###
noteMap =
  'C': 0
  'D': 2
  'E': 4
  'F': 5
  'G': 7
  'A': 9
  'B': 11


###
# Convert a pitch to a index
# ex.: A5 -> (1 + 5*12)
###
pitchToIndex = (pitch) ->

  accent = pitch.substring 1, 2
  if /#|b/.test accent
    octave = parseInt pitch.substring 2
  else
    octave = parseInt pitch.substring(1)
  note = noteMap[ pitch.substring(0,1).toUpperCase() ]

  if accent is '#'
    note++
  else if accent is 'b'
    note--

  note + octave * 12

indexMap = [
  "C"
  "C#"
  "D"
  "D#"
  "E"
  "F"
  "F#"
  "G"
  "G#"
  "A"
  "A#"
  "B"
]

###
# Convert index to pitch
###
indexToPitch = (index) ->
  octave = Math.floor( index / 12 )
  indexMap[index % 12] + octave
  

###
# Map a velocity/pitch event to the path of the waveform
###
eventToPath = (ev, waveMap) ->
  eventToNote(ev, waveMap).path

###
# Retrieve the waveMap value appropriate to the event
###
eventToNote = (ev, waveMap) ->
  targetLoudness = velocityToLoudness ev.velocity
  targetPitch = ev.pitch
  notes = _(waveMap).chain()
    .filter (pt) ->
      pt.loudness is targetLoudness
    .sortBy (pt) ->
      Math.abs noteDistance(pt.pitch, targetPitch)
    .value()
  unless notes.length
    throw "No matching note."
  notes[0]
  
###
# Note distance
###
noteDistance = (subjectPitch, objectPitch) ->
  pitchToIndex(subjectPitch) - pitchToIndex(objectPitch)

###
# Lazy-load a waveform, returning its buffer.
###
getBuffer = (path, cb) ->
  if bufferMap[path]
    cb null, bufferMap[path]
  else
    xhr = new XMLHttpRequest()
    xhr.open('GET', path, true)
    xhr.responseType = 'arraybuffer'
    xhr.onload = (e) ->
      context.decodeAudioData this.response, (buffer) ->
        bufferMap[path] = buffer
        cb null, buffer
    xhr.send()

window.context = new webkitAudioContext()

bus = context.createGainNode()
bus.gain.value = 1

tremolo = context.createJavaScriptNode(256, 1, 1)
tremolo.onaudioprocess = (e) ->
  amp = 0.5 * (1 + Math.sin context.currentTime * 28)
  inputBuffer = e.inputBuffer.getChannelData(0)
  outputBuffer = e.outputBuffer.getChannelData(0)
  _(inputBuffer).each (a, i) ->
    vol = (amp*0.5 + .5)  * a
    outputBuffer[i] = vol
#bus.connect tremolo
#tremolo.connect context.destination
bus.connect context.destination




currentNotes = {}

playNote = (ev) ->
  path = eventToPath ev, waveMap
  note = eventToNote ev, waveMap
  if currentNotes[ev.pitch]
    stopNote ev.pitch

  getBuffer path, (err, buffer) ->
    if err
      throw err
    else
      source = context.createBufferSource()
      source.buffer = buffer
      gain = context.createGainNode()
      gain.connect bus
      source.connect gain
      source.playbackRate.value = Math.pow 1.0594630943592953,noteDistance(ev.pitch, note.pitch)
      source.noteOn(0)
      currentNotes[ev.pitch] =
        source: source
        gainNode: gain

stopNote = (pitch) ->
  obj = currentNotes[pitch]
  obj.gainNode.gain.exponentialRampToValueAtTime(1, context.currentTime)
  obj.gainNode.gain.exponentialRampToValueAtTime(0.00001, context.currentTime + 0.1)
  obj.source.noteOff( context.currentTime + 0.5 )
  currentNotes[pitch] = false

window.m

messageHandler = (message) ->
  data = message.data
  if data[0] is 144
    playNote
      pitch: indexToPitch( data[1] )
      velocity: data[2]
  else
    stopNote indexToPitch( data[1] )

navigator.requestMIDIAccess().then (access) ->
  m = access.inputs()[0]
  m.onmidimessage = messageHandler
, ->
  console.log arguments
