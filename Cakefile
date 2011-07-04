{spawn, exec} = require 'child_process'
puts = console.log
fs = require 'fs'

run = (args) ->
    proc = spawn 'coffee', args
    proc.stderr.on 'data', (buffer) -> puts buffer.toString()
    proc.stdout.on 'data', (buffer) -> puts buffer.toString()
    proc.on 'exit', (status) -> process.exit(1) if status != 0

task 'clean', 'erase .js from lib/', ->
    exec 'rm -f lib/*.js'

task 'build', 'compile to .js', ->
    files = fs.readdirSync 'lib'
    files = ('lib/'+ file for file in files when file.match(/\.coffee$/))
    run ['-c', '-o', 'lib'].concat(files)

task 'test', 'test the project', ->
    run ['test/database.coffee']

task 'all', 'rock\'n\'roll', ->
    exec 'cake build && cake test'
