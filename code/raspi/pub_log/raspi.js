var io = require('/usr/lib/node_modules/socket.io').listen(8080);
// Be sure to change path to whereever socket.io is installed on the system


var t;  // I usually don't like using global variables but hope it's ok for DEMO's purpose
 
function rnd() {
    var num=Math.floor(Math.random()*1000);
    return num;
}
io.sockets.on('connection', function (socket) {
    t=setInterval( function() {
        var n=rnd();
        socket.broadcast.emit('stream', {n:n.toString()});
    }, 1000);
    socket.on('action', function (data) {
        console.log('received action');
        if(data.todo=='stop') {
            socket.broadcast.emit('stream', {n:'Stopped'});
            console.log('stopping timer now.');
            clearInterval(t);
        } else if(data.todo='run') {
            // the setInterval code definitely can
            // be combined/optimized with the one above
            // again for DEMO's sake I just leave it as is
            t=setInterval( function() {
                var n=rnd();
                socket.broadcast.emit('stream', {n:n.toString()});
            }, 1000);
        }
    });
});
