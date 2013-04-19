# here is a server you can use for testing, or production if you want :)

connect = require('connect')

connect.createServer(
  connect.static(__dirname)
).listen(8080)

