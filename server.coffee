# here is a server you can use for testing, or production if you want :)

connect = require "connect"
static = require "serve-static"

app = connect()
app.use(static(__dirname))

app.listen(8080)
