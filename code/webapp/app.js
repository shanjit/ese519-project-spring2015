/*

Express application built by shanjitsingh@gmail.com for ESE519 final project

The application is built on nodejs using express. MVC architecture is followed. The requests for a page from the client is routed using ./routes to the corresponding ./view. The ./routes should handle any communication with db/other 3rd party apps to display corresponding content to the client. The ./public folder has all the public image/js/css for the site\

The default templating engine 'Jade' is used. 
*/

var express = require('express');
var path = require('path');
var favicon = require('static-favicon');
var logger = require('morgan');
var session = require('cookie-session');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');

// make a variable app and use it later in ./bin/www
var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');
app.use(favicon());
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(cookieParser('htuayreve'));
app.use(require('stylus').middleware(path.join(__dirname, 'public')));
app.use(express.static(path.join(__dirname, 'public')));
app.use(session({secret: '<mysecret>', 
                 saveUninitialized: true,
                 resave: true}));

// ##### EDIT HERE ####
// Variables for forwarding to the correct view
var index = require('./routes/index');

// ##### EDIT HERE ####
// What to route where 
app.use('/', index);



/// catch 404 and forward to error handler
app.use(function(req, res, next) {
    var err = new Error('Not Found');
    err.status = 404;
    next(err);
});

/// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
    app.use(function(err, req, res, next) {
        res.status(err.status || 500);
        res.render('error', {
            message: err.message,
            error: err
        });
    });
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res, next) {
    res.status(err.status || 500);
    res.render('error', {
        message: err.message,
        error: {}
    });
});



module.exports = app;
