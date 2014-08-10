# here is a server you can use for testing, or production if you want :)

#This is for older versions of connect (AFAICT)
#connect = require('connect')
#
#connect.createServer(
#  connect.static(__dirname)
#).listen(8080)
#

#This now works with connect 3.1.0 and server-static 1.5.0
connect = require("connect");
serveStatic = require('serve-static');
app = connect().use(serveStatic(__dirname));
app.listen(8080);