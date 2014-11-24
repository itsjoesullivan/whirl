// Generated by CoffeeScript 1.6.3
(function() {
  var bufferMap, bus, connectMIDI, currentNotes, eventToNote, eventToPath, getBuffer, indexMap, indexToPitch, loadInstruments, makeInstrument, messageHandler, noteDistance, noteMap, pitchToIndex, responseToBuffer, setTremoloStrength, stopDelay, stopNote, tremolo, tremoloGain, velocityMap, velocityToLoudness, waveMap;

  console.log('hi');

  /*
  # Maps paths to their buffers. Lazy-loaded.
  */


  bufferMap = {};

  /*
  # Specific velocity/pitch map to paths
  */


  waveMap = [];

  /*
  # FIll a waveMap with that instrument
  */


  makeInstrument = function(instrument) {
    var loudnesses, pitches;
    loudnesses = ['ppp', 'pp', 'p', 'mp', 'mf', 'f', 'ff', 'fff'];
    pitches = ['C2', 'F+2', 'C3', 'F+3', 'C4', 'F+4', 'C5', 'F+5'];
    return _(loudnesses).each(function(loudness) {
      return _(pitches).each(function(pitch) {
        return waveMap.push({
          pitch: pitch,
          loudness: loudness,
          path: '/instruments/' + instrument + '/' + pitch + '/' + loudness + '.wav'
        });
      });
    });
  };

  makeInstrument('a200');

  /*
  # Map loudness to velocity
  #
  # Source: http://en.wikipedia.org/wiki/Dynamics_(music)
  */


  velocityMap = [
    {
      loudness: 'ppp',
      velocity: 16
    }, {
      loudness: 'pp',
      velocity: 33
    }, {
      loudness: 'p',
      velocity: 49
    }, {
      loudness: 'mp',
      velocity: 64
    }, {
      loudness: 'mf',
      velocity: 80
    }, {
      loudness: 'f',
      velocity: 96
    }, {
      loudness: 'ff',
      velocity: 112
    }, {
      loudness: 'fff',
      velocity: 127
    }
  ];

  /*
  # Convert a velocity to a loudness
  */


  velocityToLoudness = function(velocity) {
    var pt;
    pt = _(velocityMap).find(function(pt) {
      return pt.velocity >= velocity;
    });
    return pt.loudness;
  };

  /*
  # Map a note to its index in the octave
  */


  noteMap = {
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11
  };

  /*
  # Convert a pitch to a index
  # ex.: A5 -> (1 + 5*12)
  */


  pitchToIndex = function(pitch) {
    var accent, note, octave;
    accent = pitch.substring(1, 2);
    if (/\+|#|b/.test(accent)) {
      octave = parseInt(pitch.substring(2));
    } else {
      octave = parseInt(pitch.substring(1));
    }
    note = noteMap[pitch.substring(0, 1).toUpperCase()];
    if (accent === '#' || accent === '+') {
      note++;
    } else if (accent === 'b') {
      note--;
    }
    return note + octave * 12;
  };

  indexMap = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

  /*
  # Convert index to pitch
  */


  indexToPitch = function(index) {
    var octave;
    octave = Math.floor(index / 12) - 2;
    return indexMap[index % 12] + octave;
  };

  /*
  # Map a velocity/pitch event to the path of the waveform
  */


  eventToPath = function(ev, waveMap) {
    return eventToNote(ev, waveMap).path;
  };

  /*
  # Retrieve the waveMap value appropriate to the event
  */


  eventToNote = function(ev, waveMap) {
    var notes, targetLoudness, targetPitch;
    targetLoudness = velocityToLoudness(ev.velocity);
    targetPitch = ev.pitch;
    notes = _(waveMap).chain().filter(function(pt) {
      return pt.loudness === targetLoudness;
    }).sortBy(function(pt) {
      return Math.abs(noteDistance(pt.pitch, targetPitch));
    }).value();
    if (!notes.length) {
      throw "No matching note.";
    }
    return notes[0];
  };

  /*
  # Note distance
  */


  noteDistance = function(subjectPitch, objectPitch) {
    return pitchToIndex(subjectPitch) - pitchToIndex(objectPitch);
  };

  /*
  # Lazy-load a waveform, returning its buffer.
  */


  getBuffer = function(path, cb) {
    var xhr;
    if (bufferMap[path]) {
      return cb(null, bufferMap[path]);
    } else {
      xhr = new XMLHttpRequest();
      xhr.open('GET', path, true);
      xhr.responseType = 'arraybuffer';
      xhr.onload = function(e) {
        return responseToBuffer(this.response, function(err, buffer) {
          bufferMap[path] = buffer;
          return cb(err, buffer);
        });
      };
      return xhr.send();
    }
  };

  responseToBuffer = function(response, cb) {
    return context.decodeAudioData(response, function(buffer) {
      return cb(null, buffer);
    });
  };

  window.context = new webkitAudioContext();

  bus = context.createGain();

  bus.gain.value = 0.7;

  bus.connect(context.destination);

  tremolo = context.createOscillator();

  tremolo.frequency.value = 5;

  tremolo.start(0);

  tremoloGain = context.createGain();

  tremoloGain.gain.value = 0.3;

  tremoloGain.connect(bus.gain);

  tremolo.connect(tremoloGain);

  setTremoloStrength = function(strength) {
    tremoloGain.gain.value = strength;
    return bus.gain.value = 1 - strength;
  };

  setTremoloStrength(0.00);

  /*
  verb = context.createConvolver()
  getBuffer '/impulse_responses/fender.wav', (err, buffer) ->
    verb.buffer = buffer
    bus.connect verb
    verbGain = context.createGainNode()
    verbGain.gain.value = 0.10
    verb.connect verbGain
    verbGain.connect context.destination
  */


  currentNotes = {};

  window.playNote = function(ev) {
    var note, path;
    path = eventToPath(ev, waveMap);
    note = eventToNote(ev, waveMap);
    if (currentNotes[ev.pitch]) {
      stopNote(ev.pitch);
    }
    return getBuffer(path, function(err, buffer) {
      var gain, source;
      if (err) {
        throw err;
      } else {
        source = context.createBufferSource();
        source.buffer = buffer;
        gain = context.createGain();
        gain.connect(bus);
        source.connect(gain);
        source.playbackRate.value = Math.pow(1.0594630943592953, noteDistance(ev.pitch, note.pitch));
        source.start(0);
        return currentNotes[ev.pitch] = {
          source: source,
          gainNode: gain
        };
      }
    });
  };

  stopDelay = 0.3;

  stopNote = function(pitch) {
    var obj;
    obj = currentNotes[pitch];
    obj.gainNode.gain.exponentialRampToValueAtTime(1, context.currentTime);
    obj.gainNode.gain.exponentialRampToValueAtTime(0.00001, context.currentTime + stopDelay);
    obj.source.stop(context.currentTime + 0.5);
    return currentNotes[pitch] = false;
  };

  window.m;

  messageHandler = function(message) {
    var data;
    data = message.data;
    if (data[0] === 144) {
      return playNote({
        pitch: indexToPitch(data[1]),
        velocity: data[2]
      });
    } else if (data[0] === 128) {
      return stopNote(indexToPitch(data[1]));
    } else if (data[0] === 176) {
      return setTremoloStrength(data[2] / 127);
    }
  };

  connectMIDI = function() {
    console.log('connecting');
    return navigator.requestMIDIAccess().then(function(access) {
      var m;
      access.onconnect = function() {
        return console.log('onconnect');
      };
      access.ondisconnect = function() {
        return console.log('ondisconnect');
      };
      m = access.inputs.values().next().value;
      return m.onmidimessage = messageHandler;
    }, function(e) {});
  };

  /*
  # Load all sounds of an instrument
  */


  loadInstruments = function(instrumentName) {
    var ct;
    ct = 0;
    return _(waveMap).each(function(wave) {
      ct++;
      return getBuffer(wave.path, function(err) {
        if (!err) {
          ct--;
          if (ct === 0) {
            connectMIDI();
            return 1;
          }
        }
      });
    });
  };

  loadInstruments();

}).call(this);