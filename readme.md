
- play a note

- hold notes using sustain pedal

- stop notes using sustain pedal

- stop playing a note

- play multiple notes


all notes:
  - map to actual waveform
  - give other notes a chance to react
  - start sound, with a handle for how to end it

  - when pedal goes down, ignore letting go
  - when pedal goes up, all that have not been let go are released



note
  - key
    - status
      - pressed
      - released
  - pedal
    - status
      - pressed
      - released
  - velocity
  - startTime
  - wav

note.key.on('release'
