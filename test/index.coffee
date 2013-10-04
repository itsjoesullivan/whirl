describe 'bufferMap', ->
  it 'exists', ->
    (typeof bufferMap).should.equal 'object'

describe 'waveMap', ->
  it 'exists', ->
    (typeof waveMap).should.equal 'object'

describe 'velocityMap', ->
  it 'exists', ->
    (typeof velocityMap).should.equal 'object'

describe 'velocityToLoudness', ->
  it 'exists', ->
    (typeof velocityToLoudness).should.equal 'function'

describe 'noteMap', ->
  it 'exists', ->
    (typeof noteMap).should.equal 'object'

describe 'pitchToIndex', ->
  it 'exists', ->
    (typeof pitchToIndex).should.equal 'function'

describe 'eventToPath', ->
  it 'exists', ->
    (typeof eventToPath).should.equal 'function'

describe 'getBuffer', ->
  it 'exists', ->
    (typeof getBuffer).should.equal 'function'

