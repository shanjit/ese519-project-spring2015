var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res) {
  res.render('page1', { title: 'projectx' });

/*
	use to decode the url
	console.log(req.query.roomid);
*/

});

router.get('/page2', function(req, res) {
  res.render('page2', { title: 'Bootstrap Template' });

/*
	use to decode the url
	console.log(req.query.roomid);
*/

});


module.exports = router;
