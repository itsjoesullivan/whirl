class Keyboard
  initialize: ->
    this.on 'note', (e) ->
      note = new Note
        key: new Key e
