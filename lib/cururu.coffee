###
    Staple and Copy Proof of Concept
    Designed for CearaJS Lighting Talk in 11-June-2011.
    Copyright (c) 2011 Leonardo Eloy
    http://github.com/leonardoeloy
###

puts = console.log
crypto = require 'crypto'

# Based on http://coffeescriptcookbook.com/chapters/objects/cloning
exports.Database = class Database
    constructor: (dbName, db) ->
        # (Should, but won't be) Private methods
        # Non-fancy MongoDB-esque database query "enabler"
        @evaluate = (key, value, doc) ->
            leftQuotes = "\'"
            leftValue = doc[key]
            leftQuotes = "" if typeof(leftValue) is 'number'

            operator = "==="

            rightQuotes = "\'"
            rightValue = value
            rightQuotes = "" if typeof(rightValue) is 'number'

            if typeof(value) == 'object'
                for aKey, aValue of value
                     operator = aKey
                     rightValue = aValue
                     rightQuotes = "" if typeof(rightValue) is 'number'

            # eval is not evil here :)
            `eval(leftQuotes+leftValue+leftQuotes+ " " + operator + " " + rightQuotes+rightValue+rightQuotes)`

        @processStaples = (doc) ->
            return doc if !doc._staple?

            for property in doc._staple
                docs = []
                for ref in doc[property]
                    revision = @findSingle _id: ref._id, true if ref._type is doc._type
                    if not revision?
                        revision = @clone ref
                        revision._inconsistent = yes

                    docs.push revision

                doc[property] = docs



        # Based on http://coffeescriptcookbook.com/chapters/objects/cloning
        @clone = (obj) ->
            return obj if not obj? or typeof(obj) isnt 'object'

            newInstance = new obj.constructor()
            for key of obj
                newInstance[key] = @clone obj[key]

            newInstance

        @db = []
        @dbName = dbName
        @id = 1

        @append doc for doc in db if db

        @

    find: (obj, returnSingle=false) ->
        result = []
        removed = []
        for doc in @db.reverse(@db)
            found = no
            removed[doc._id] = yes if doc._removed
            continue if removed[doc._id]?
            for key, value of obj
                break if (found = @evaluate key, value, doc)

            result.push doc if found

        @db.reverse(@db)

        # we won't pass results by reference
        # and we'll filter old revisions
        # and join stapled documents
        newResult = []
        rev = []
        for obj in result
            continue if obj._revision < rev[obj._id]
            rev[obj._id] = obj._revision
            newInstance = @clone obj
            @processStaples newInstance
            newResult.push newInstance

        return newResult[0] if returnSingle and newResult.length >= 1
        return null if newResult.length is 0
        newResult.reverse(newResult)

    findSingle: (obj) ->
        @find obj, true

    append: (doc) ->
        if not doc._id?
            doc._id = @id++
            doc._type = @dbName
            doc._timestamp = new Date().getTime()
            doc._revision = 0

        hash = crypto.createHash 'md5'
        hash.update "#{key}: #{value} " for key, value of doc
        doc._hash = hash.digest 'hex'

        doc._revision++

        @db.push(doc)

        @clone doc

    remove: (doc) ->
        throw new Error "Document should have the _id property" if not doc._id?
        doc = @clone doc
        doc._removed = true
        @append(doc)

    compact: ->
        copy = []
        removed = []
        rev = []
        for doc in @db.reverse(@db)
            if doc._removed?
                removed[doc._id]= yes
            else if not removed[doc._id]?
                continue if doc._revision < rev[doc._id]
                rev[doc._id] = doc._revision
                copy.push doc
        # Reverse it again, so we get the original order
        @db = copy.reverse(copy)

    db: ->
        @db

    staple: (from, to, property) ->
        throw new Error "Cannot staple to an undefined property" if not property? or typeof(property) isnt 'string' or property is ''
        to[property] ?= []
        to[property].push _type: from._type, _id: from._id
        to._staple ?= []
        to._staple.push property if property not in to._staple

        @append to

    copy: (from, to, property) ->
        throw new Error "Cannot copy to an undefined property" if not property? or typeof(property) isnt 'string' or property is ''
        to[property] ?= []
        from._copy = new Date().getTime()
        to[property].push from

        @append to



