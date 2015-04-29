		$(document).ready(function() {
			$('#fullpage').fullpage({
				anchors: ['firstPage', 'secondPage', 'thirdPage', 'fourthPage', 'fifthPage'],
				sectionsColor: ['#21292E', '#67C3CA', '#8FB98B', '#8FB98B', '#EAE1C0'],
				slidesNavigation: true,
			});



	$("#play").click(function(e) {
			console.log("shan");
	var text = "shan";
	var json_text = JSON.stringify(text);
	var real_json_text = JSON.stringify({ x: text });                  // '{"x":5}'
					$.ajax({
						type: 'POST',
						contentType: 'application/json',
						data: real_json_text,
                        url: '/index/page2',						
                        success: function(data) {
                            console.log('success');
                        }
                    });
	});
		});

