StapleDB: a Javascript Document-oriented Database
=================================================

TODO: Rewrite readme.

This module is an experimental implementation of a document-oriented database written in CoffeeScript. 


Introduction
------------

This is just a proof of concept project that mimetizes a NoSQL database. It stores documents in an array that simulates an append-only B+ Tree.

This project was designed for a lightining talk I'm supposed to give in CearaJS. The main problem that me and a group of friends were facing was how to make references among documents - and how to efficiently design a model to a document-oriented database.

From this point I started analyzing two real world approaches to solve this reference issue: 
a) staple a document to another one - 'hot reference', always updated;
b) copy an original document and then staple it - 'cold reference', refers to an old revision.

Objectives
----------

What this project will do:

1. Research how documents are used in the real world to come up with the correct abstraction when implementing a document store;
2. Implement the concepts of Staple and Copy (see below);
3. Take advantage of Node.js' event-oriented paradigm;
4. Make sure CoffeeScript is cool :)

What this project won't do:

1. Implement efficient algorithms in all features;
2. For this first release, take advantage of node.js' event-oriented paradigm.

Staple
------


Suppose you have a physical records of clients (a). Everytime you make a sale, you staple the copy of the receipt to the client's record (b). 

	+----------+       +-----------+
	| Client A |       | Receipt 1 |
	|          |       |           |
	+----------+       +-----------+  (a) Separated documents

	+----------+    
	| Client A |    
	|  +-----------+
	+--| Receipt 1 |                  (b) Stapled document
	   |           |
       +-----------+

If you want to know how much one customer has bought, you fetch the client file and go through all receipts, summing the spent amount. 
The difference between stapling original documents from their copies is that updates in these documents are always modifying the original revision.

### Problems

1. When dealing with documents from other document stores, how to efficiently query the latter in order to obtain the latest revision?
2. The query mechanism should be able to process staples before returning the result set. Where would this be more efficient? Inline, during the query, or after the results have been obtained?
3. How should the B+ Tree walkthrough work? Should we include more metadata about the stapled documents (e.g. pointer to B+ Tree leaf node)? 
4. What about a hash function that contains B+ Trees in its buckets? Would this be more efficient than just a B+ Tree? (e.g. lower compaction complexity by 'dividing to conquer' and having shorter trees)


Copy
----

The copy concept is very similiar to staple. The only difference is that updates in the copy won't reflect in changes in the original revision. 
Thus, the copy is a part of the document that it's being stapled to. 

Taking the above mentioned example:

	+----------+       +-----------+
	| Client A |       | Receipt 1 |
	|          |       |           |
	+----------+       +-----------+    (a) Separated documents

	+----------+                    
	| Client A |         +-----------+
	|  +-----------+     | Receipt 1 |
	+--| Receipt 1 |     |           |
	   |           |     +-----------+  (b) Stapled copy
       +-----------+


Installation
------------

Clone the repository and then

    sudo npm install -g cjs-db


Tests
-----

    cake test

Usage
-----

CoffeeScript:

    # Load module
    db = require 'cjs-db'

    docs = new db.Database 'person'
    docs.append name: 'Johnny', surname: 'Awesome'
    docs.append name: 'Miles', surname: 'Davis'

    # Query the database, returning an array of results
    person = docs.find name: 'Johnny'
    # Returns only one result, if available
    miles = docs.findSingle name: 'Miles'
    # Returns Johnny in an array
    person = docs.find { name: { '!=': 'Miles' } }
    # Returns all docs with id > 0
    id1 = docs.find { _id: { '>': 0 } }

    # append() returns the document stored
    coltrane = docs.append name: 'John', surname: 'Coltrane'
    # You can remove documents
    docs.remove coltrane

    # You can look into the "database"
    console.log require('sys').inspect docs.db

    # You can compact it
    docs.compact()

    # Now take a look into the database again
    console.log require('sys').inspect docs.db

    # Staple
    johnny = docs.find name: 'Johnny', true
    # Staples Miles as one of Johnny's favorite musicians
    docs.staple miles, johnny, 'favoriteMusicians'
    # Fetch Johnny's last revision
    johnny = docs.find name: 'Johnny', true
    # See who's Johnny #1 favorite musician
    console.log johnny.favoriteMusicians[0].name

    # Copy
    morse = docs.append name: 'Neal', surname: 'Morse'
    docs.copy miles, morse, 'influences'
    morse = docs.findSingle name: 'Neal'
    # Should get 'Miles'
    console.log morse.influences[0].name
    # Remove the copyied document
    docs.remove miles
    morse = docs.findSingle name: "Neal"
    # Should get 'Miles' again
    console.log morse.influences[0].name

Javascript:

    // Load module
    var db = require('cjs-db');

    var docs = new db.Database('person');
    docs.append({
        name: 'Johnny',
        surname: 'Awesome'
    });

    docs.append({
        name: 'Miles',
        surname: 'Davis'
    });

    // Query the database, returning an array of results
    var person = docs.find({name: 'Johnny'});
    // Returns only one result, if available
    var miles = docs.findSingle({name: 'Miles'});
    // Returns Johnny in an array
    var person = docs.find({name: { '!=': 'Miles'}});
    // Returns all docs with id > 0
    var id1 = docs.find({_id: { '>': 0}});

    // You can remove documents
    var coltrane = docs.append({name: 'John', surname: 'Coltrane'});
    docs.remove(coltrane);

    // You can look into the "database"
    console.log(require('sys').inspect(docs.db));

    // You can compact it
    docs.compact();

    // Now you can look into the "database" again
    console.log(require('sys').inspect(docs.db));

    // Staple
    var johnny = docs.find({name: 'Johnny'}, true);
    // Staples Miles as one of Johnny's favorite musicians
    docs.staple(miles, johnny, 'favoriteMusicians');
    // Fetch Johnny's last revision
    var johnny = docs.find({name: 'Johnny'}, true);
    // See who's Johnny #1 favorite musician
    console.log(johnny.favoriteMusicians[0].name);

    // Copy
    var morse = docs.append({
        name: 'Neal', 
        surname: 'Morse'
    });
    docs.copy(miles, morse, 'influences');
    morse = docs.findSingle({name: "Neal"});
    // Should get 'Miles'
    console.log(morse.influences[0].name);
    // Remove the copyied document
    docs.remove miles
    morse = docs.findSingle({ name: "Neal" });
    // Should get 'Miles' again
    console.log(morse.influences[0].name);

   
License
-------

This software is licensed under the MIT License.

Copyright (c) 2011 Leonardo Eloy

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.

