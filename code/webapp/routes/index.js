var express = require('express');
var router = express.Router();
var fs = require('fs');

/* GET home page. */
router.get('/', function(req, res) {
  res.render('page1', { title: 'BrainWav' });

/*
	use to decode the url
	console.log(req.query.roomid);
*/

});



router.get('/page2', function(req, res) {
	

    fs.readFile("/home/cuil/Dropbox/Upenn/spring2015/ese519/ese519-project-spring2015/code/Python/songSel.txt", 'utf8', function(err, load_data) {
    if(err) {
        console.log(err);
    } else {
        console.log(load_data);
    }

    res.render('page2', { title: 'The play page', roomid: load_data});
}); 




});


module.exports = router;
