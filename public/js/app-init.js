// setup the console vars
var console = window.console || {
  log:function(){},
  warn:function(){},
  error:function(){}
};

// setup the app namespace
var APP = APP || {
  version: "1.0.0",
  ns: function (namespaces) {
		var names = namespaces.split('.'), len, ns = APP, i;
		if (names[0].toUpperCase() == 'APP') {
			names.splice(0,1);
		}
		len = names.length;
		for (i = 0; i < len; i++) {
			( !ns[names[i]] && (ns[names[i]] = {}) );
			ns = ns[names[i]];
		}
	},
};

APP.ns("settings");
APP.settings = {
  homePage: "/",
  homePageId: "home-article",
  residentsLookup: "/residents/lookup/",
  residentUnit: "/resident-unit/{0}/",
  selectResidentsMessage: "<em>Please find a resident using the fields above. Thank you!</em>",
  loadingResidentMessage: "<em>Loading resident info, please wait. Thank you!</em>",
  couldNotFindResidentMessage: "<em>Could not find resident, please try again. Thank you!</em>",
  floorStart: 1,
  floorEnd: 27,
  unitStart: 1,
  unitEnd: 18,
};

APP.ns("ui");
APP.ui = {
  preLoadAndCacheImages: function ( imgPaths ) {
    var $imgPreloader = $("<div class='img-pre-loader'/>");
    $imgPreloader.css({ "display" : "none" }).appendTo("body");
  	if (typeof imgPaths == 'string') {
  	  var tempImgPath = imgPaths;
      imgPaths = [tempImgPath];
  	}
		for (var index=0; index<imgPaths.length; index++) {
		  var imgPath = imgPaths[index];
		  $imgPreloader.append('<img src="'+imgPath+'">');
		}
  },
};