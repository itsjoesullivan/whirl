console.log 'hi'

###
# Maps paths to their buffers. Lazy-loaded.
###
bufferMap = {}

###
# Specific velocity/pitch map to paths
###
waveMap = []

###
# FIll a waveMap with that instrument
###
makeInstrument = (instrument) ->
  loudnesses = [ 'ppp', 'pp', 'p', 'mp', 'mf', 'f', 'ff', 'fff' ]
  pitches = [ 'C2', 'F+2', 'C3', 'F+3', 'C4', 'F+4', 'C5', 'F+5' ]
  _(loudnesses).each (loudness) ->
    _(pitches).each (pitch) ->
      waveMap.push
        pitch: pitch
        loudness: loudness
        path: '/instruments/' + instrument + '/' + pitch + '/' + loudness + '.wav'

makeInstrument 'a200'



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
  if /\+|#|b/.test accent
    octave = parseInt pitch.substring 2
  else
    octave = parseInt pitch.substring(1)
  note = noteMap[ pitch.substring(0,1).toUpperCase() ]

  if accent is '#' or accent is '+'
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
  octave = Math.floor( index / 12 ) - 2
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
      responseToBuffer this.response, (err, buffer) ->
        bufferMap[path] = buffer
        cb(err, buffer)
    xhr.send()

responseToBuffer = (response, cb) ->
  context.decodeAudioData response, (buffer) ->
    cb null, buffer

window.context = new webkitAudioContext()

# Bus
bus = context.createGainNode()
bus.gain.value = 0.7
bus.connect context.destination

# Tremolo
tremolo = context.createOscillator()
tremolo.frequency.value = 5
tremolo.start(0)
tremoloGain = context.createGainNode()
tremoloGain.gain.value = 0.3
tremoloGain.connect bus.gain
tremolo.connect tremoloGain

setTremoloStrength = (strength) ->
  tremoloGain.gain.value = strength
  bus.gain.value = 1 - strength
setTremoloStrength 0.00

###
verb = context.createConvolver()
getBuffer '/impulse_responses/fender.wav', (err, buffer) ->
  verb.buffer = buffer
  bus.connect verb
  verbGain = context.createGainNode()
  verbGain.gain.value = 0.10
  verb.connect verbGain
  verbGain.connect context.destination
###



currentNotes = {}

window.playNote = (ev) ->
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

stopDelay = 0.3
stopNote = (pitch) ->
  obj = currentNotes[pitch]
  obj.gainNode.gain.exponentialRampToValueAtTime(1, context.currentTime)
  obj.gainNode.gain.exponentialRampToValueAtTime(0.00001, context.currentTime + stopDelay)
  obj.source.noteOff( context.currentTime + 0.5 )
  currentNotes[pitch] = false

window.m

messageHandler = (message) ->
  data = message.data
  if data[0] is 144
    playNote
      pitch: indexToPitch( data[1] )
      velocity: data[2]
  else if data[0] is 128
    stopNote indexToPitch( data[1] )
  else if data[0] is 176
    setTremoloStrength data[2] / 127

connectMIDI = ->
  console.log 'connecting'
  navigator.requestMIDIAccess().then (access) ->
    console.log 'access'
    console.log access
    access.onconnect = -> console.log 'onconnect'
    access.ondisconnect = -> console.log 'ondisconnect'
    m = access.inputs()[0]
    m.onmidimessage = messageHandler
  , (e) ->

###
# Load all sounds of an instrument
###
loadInstruments = (instrumentName) ->
  ct = 0
  _(waveMap).each (wave) ->
    ct++
    getBuffer wave.path, (err) ->
      unless err
        ct--
        if ct is 0
          connectMIDI()
          1
          # done

loadInstruments()
  
