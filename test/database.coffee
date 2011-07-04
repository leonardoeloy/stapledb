vows = require 'vows'
assert = require 'assert'
sys = require 'sys'
puts = console.log
db = require '../lib/cururu'

###
   Since this is just a proof of concept library, these tests go in the database array directly
   to verify if things are ok.

   Instead, we should use only the provided functions to verify the behaviour of the Database object.
###

insp = (obj) ->
    console.log sys.inspect obj

vows
    .describe('Document-Oriented Database')
    .addBatch

        'when creating an instance':
            'with no documents':
                topic: new db.Database 'example'

                'the database should be empty': (topic) ->
                    assert.equal topic.db.length, 0

            'with documents':
                topic: new db.Database('example', [{property: "value"}])

                'the database should not be empty': (topic) ->
                    assert.notEqual topic.db.length, 0
                    assert.equal topic.db[0]._id, 1

        'when appending a document':
            topic: new db.Database 'example'

            'it should have an _id property with value 1': (topic) ->
                doc =
                    property: 'value'

                topic.append doc
                assert.equal topic.db[0]._id, 1

            'it should have an _id property with value 2': (topic) ->
                doc =
                    anotherProperty: 'anotherValue'

                topic.append doc
                assert.equal topic.db[1]._id, 2

            'it should fill the _type property': (topic) ->
                assert.equal topic.db[0]._type, 'example'

            'it should fill the _revision property': (topic) ->
                assert.notEqual topic.db[0]._revision, null

            'it should fill the _timestamp property': (topic) ->
                assert.notEqual topic.db[0]._timestamp, null

            'it should fill the _hash property': (topic) ->
                # FIXME expand this test
                assert.notEqual topic.db[0]._hash, null

            'it should return the stored document': ->
                topic = new db.Database 'example'
                doc = topic.append name: 'John'
                assert.equal doc.name, 'John'

        'when removing a document':
            topic: new db.Database 'example'

            'it should append a new revision and set _removed to true': (topic) ->
                doc =
                    property: 'value'
                topic.append doc
                topic.remove _id: 1
                assert.ok topic.db[1]._removed

            'it should keep the previous revision': (topic) ->
                assert.equal topic.db[0]._id, 1
                assert.equal topic.db[0]._removed, undefined

            'it should force _id property': (topic) ->
                assert.throws -> topic.remove no: "id"

        'when compacting the database':
            topic: new db.Database 'example'

            'it should remove old revisions': (topic) ->
                doc =
                    property: 'value'

                topic.append doc
                topic.remove _id: 1
                topic.compact()
                assert.equal topic.db.length, 0

            'it should keep the oldest revisions in the bottom of the stack': ->
                topic = new db.Database 'example'
                [1..4].map (i) -> topic.append { i: i }

                topic.remove _id: 2
                topic.compact()
                assert.equal topic.db[0]._id, 1
                assert.equal topic.db[1]._id, 3
                assert.equal topic.db[2]._id, 4

            'it should remove a prior revision of a document': ->
                topic = new db.Database 'example'
                topic.append test: 'test'
                doc = topic.find test: 'test', true
                doc.anoterTest = 'anotherTest'
                topic.append doc

                assert.equal topic.db[0]._id, 1
                assert.equal topic.db[1]._id, 1

                topic.compact()

                assert.equal topic.db.length, 1

        'when querying the database':
            topic: ->
                doc1 =
                    name: "Clark"
                    surname: "Kent"
                    gear:
                        type: "underpants"
                        color: "red"

                doc2 =
                    name: "Bruce"
                    surname: "Wayne"
                    gear:
                        type: "suit"
                        color: "black"

                new db.Database('person', [doc1, doc2])

            'it should find exact matches': (topic) ->
                doc = topic.find name: "Clark"
                assert.equal doc[0]._id, 1

            'it should have a way return the document instance instead of an array': (topic) ->
                clark = topic.findSingle name: "Clark"
                assert.equal typeof(clark), 'object'
                assert.equal clark.name, 'Clark'

            'it should return null when querying for a single result': (topic) ->
                doc = topic.findSingle name: "John"
                assert.equal doc, null

            'it should ignore removed documents before compaction': ->
                topic = new db.Database 'example'
                clark = topic.append name: 'Clark'
                topic.remove clark
                clark = topic.findSingle name: 'Clark'
                assert.equal clark, null

            'it should be able to find matches using binary operators':
                'comparing strings values': (topic) ->
                    doc = topic.find { name: { "!=": "Clark" } }
                    assert.equal doc[0].name, "Bruce"

                'comparing numeric values': (topic) ->
                    docs = topic.find { _id: { ">=": 1 } }
                    assert.equal docs.length, 2

        'when stapling a document':
            'in the same database':
                topic: ->
                    doc1 =
                        name: "Clark"
                        surname: "Kent"
                        gear:
                            type: "underpants"
                            color: "red"

                    doc2 =
                        name: "Bruce"
                        surname: "Wayne"
                        gear:
                            type: "suit"
                            color: "black"

                    doc3 =
                        name: "Robin"
                        gear:
                            type: "gloves"
                            color: "red"

                    new db.Database('person', [doc1, doc2, doc3])

                'it should expect a filled property': (topic) ->
                    bruce = topic.find name: 'Bruce', true
                    robin = topic.find name: 'Robin', true
                    assert.throws -> topic.staple robin, bruce, null
                    assert.throws -> topic.staple robin, bruce, ''
                    assert.throws -> topic.staple robin, bruce, 1

                'it should be easy to access it': (topic) ->
                    # Staple for the first time
                    bruce = topic.find name: 'Bruce', true
                    robin = topic.find name: 'Robin', true
                    topic.staple robin, bruce, 'closeFriends'

                    bruce = topic.find name: 'Bruce', true
                    assert.equal bruce.closeFriends[0]._id, robin._id
                    assert.equal bruce.closeFriends[0].gear.type, 'gloves'

                    # Change the referenced document
                    robin = topic.find name: 'Robin', true
                    robin.gear.type = "mask"
                    robin.gear.color = "black"
                    topic.append robin

                    # Fetch it again and evaluate if we're dealing with the latest revision
                    bruce = topic.find name: 'Bruce', true

                    assert.equal bruce.closeFriends[0]._id, robin._id
                    assert.equal bruce.closeFriends[0].gear.type, 'mask'

                'it should be able to work with multiple documents': (topic) ->
                    doc =
                        name: "Joker"
                        gear:
                            type: "mouth"
                            color: "red"

                    topic.append doc
                    joker = topic.findSingle name: "Joker"
                    bruce = topic.findSingle name: "Bruce"
                    topic.staple joker, bruce, 'closeFriends'

                    bruce = topic.findSingle name: "Bruce"
                    assert.equal bruce.closeFriends[0].name, 'Robin'
                    assert.equal bruce.closeFriends[1].name, 'Joker'

                'it should flag removed referenced with _inconsistent': (topic) ->
                    joker = topic.findSingle name: "Joker"
                    topic.remove joker
                    bruce = topic.findSingle name: "Bruce"
                    assert.equal bruce.closeFriends.length, 2
                    assert.equal bruce.closeFriends[1]._inconsistent, yes

        'when copying a document':
            'it should expect a filled property': ->
                topic = new db.Database 'example'
                bruce = topic.find name: 'Bruce', true
                robin = topic.find name: 'Robin', true
                assert.throws -> topic.copy robin, bruce, null
                assert.throws -> topic.copy robin, bruce, ''
                assert.throws -> topic.copy robin, bruce, 1

            'it should duplicate the document\'s structure': ->
                topic = new db.Database 'musician'
                miles = topic.append name: "Miles Davis", style: "jazz"
                coltrane = topic.append name: "John Coltrane", style: "jazz"
                morse = topic.append name: "Neal Morse", style: "progressive rock"

                topic.copy miles, morse, 'influences'
                morse = topic.findSingle _id: morse._id
                assert.equal morse.influences[0].name, miles.name

            'it should duplicate the document\'s structure and keep it after removed': ->
                topic = new db.Database 'musician'
                miles = topic.append name: "Miles Davis", style: "jazz"
                coltrane = topic.append name: "John Coltrane", style: "jazz"
                morse = topic.append name: "Neal Morse", style: "progressive rock"

                topic.copy miles, morse, 'influences'
                topic.remove miles
                morse = topic.findSingle _id: morse._id

    .run()
