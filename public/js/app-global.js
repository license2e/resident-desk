
APP.ns("utility");
APP.utility = {
  showErrorDialog: function ( ) {
    var msg = $.mobile.pageLoadErrorMessage,
      $loader = $(".ui-loader");
    if(arguments[0] != undefined){
      if(typeof arguments[0] == "string" && arguments[0] != ""){
        msg = arguments[0];
      } else if(typeof arguments[0] == "object"){
        msg = "";
        for(m in arguments[0]){
          msg += arguments[0][m]+"\n";
        }
      }
    }
    // show error message
    $.mobile.showPageLoadingMsg( $.mobile.pageLoadErrorMessageTheme, msg, true );
    // hide after delay
    setTimeout($.mobile.hidePageLoadingMsg, 5000 );
  },
  convertJsonToListView: function ( jsonObj, $form, cbfunc ){
    var $dialog = $("#custom-dialog"),
      $listView = null;
    
    if( $dialog.length > 0 ){
      $dialog.remove();
      $dialog = null;
    }
    
    var dialogHTML = '';
    dialogHTML += '<div id="custom-dialog" data-role="dialog" data-theme="c">';
    dialogHTML += ' <div data-role="header">';
    dialogHTML += '   <a href="#" data-rel="back" data-iconpos="notext" data-icon="arrow-l" data-corners="false">Back</a>';
    dialogHTML += '   <h2>';
    dialogHTML += '     Select:';
    dialogHTML += '   </h2>';
    dialogHTML += ' </div>';
    dialogHTML += ' <div id="custom-dialog-content" data-role="content">';
    if( jsonObj.length > 0 ){
      dialogHTML += '   <ul id="custom-dialog-listview" data-role="listview" data-theme="a">';  
      for( i in jsonObj ){
        if( i == "length")
          continue;
        dialogHTML += '     <li data-icon="check"><a href="#' + i + '" data-key="' + i + '" data-valright="' + jsonObj[i]["rightv"].join(", ") + '" data-valleft="' + jsonObj[i]["leftv"] + '"><span class="custom-text">' + jsonObj[i]["rightv"].join("<br />") + '</span>' + jsonObj[i]["leftv"] + '</a></li>';
      }
      dialogHTML += '   </ul>';
    } else {
      dialogHTML += '   <em><small>Sorry, no results, please try again...</small></em>';
    }
    dialogHTML += ' </div>';
    dialogHTML += '</div>';

    /* */
    $dialog = $(dialogHTML);
    $dialog.appendTo("body");
    /* */
    
    $.mobile.changePage("#custom-dialog");
    $.mobile.hidePageLoadingMsg();
    
    cbfunc($form, $dialog, "#custom-dialog-listview li a", "data-key", "data-valright", "data-valleft");
    
    return true;
  },
  zeroFill: function( number, width ) {
    width -= number.toString().length;
    if ( width > 0 ){ return new Array( width + (/\./.test( number ) ? 2 : 1) ).join( '0' ) + number; }
    return number + ""; // always return a string
  },
  postAjaxFormReturnJsonList: function( $form ){
    $.mobile.showPageLoadingMsg();
    var cbfunc = (arguments[1] != undefined && typeof arguments[1] == "function") ? arguments[1] : function( $form, $listView ){}, 
      ajaxOptions = {
        url: $form.attr("action"),
        type: $form.attr("method"),
        data: $form.serialize(),
        dataType: "json",
        success: function(res){
          if(res.error){
            $.mobile.hidePageLoadingMsg();
            APP.utility.showErrorDialog(res.error);
          } else {
            APP.utility.convertJsonToListView( res, $form, cbfunc );
          }
        },
        error: function(){
          $.mobile.hidePageLoadingMsg();
          APP.utility.showErrorDialog();
        }
      };
    $.ajax(ajaxOptions);
    return false;
  },
};

(function($,window,document,undefined){ 
  
  APP.ui.preLoadAndCacheImages([
    "/css/images/logo.png",
    "/css/jquery.mobile-1.1.1/images/ui-icons-36-0DAE54.png",
    "/css/jquery.mobile-1.1.1/images/ui-icons-36-262626.png",
    "/css/jquery.mobile-1.1.1/images/ui-icons-36-CC1E24.png",
    "/css/jquery.mobile-1.1.1/images/ui-icons-36-white.png",
    "/css/jquery.mobile-1.1.1/images/ui-icons-54-0DAE54.png",
    "/css/jquery.mobile-1.1.1/images/ui-icons-54-262626.png",
    "/css/jquery.mobile-1.1.1/images/ui-icons-54-CC1E24.png",
    "/css/jquery.mobile-1.1.1/images/ui-icons-54-white.png",
    "/css/jquery.mobile-1.1.1/images/ajax-loader.gif",
  ]);
  
  /* * /
  $.support.placeholder = (function(){
      var i = document.createElement('input');
      return 'placeholder' in i;
  })();
  // detect placeholder support
  if( !$.support.placeholder ) {
    
  }
  /* */
  
  var qtyh_allow = true,
    qty_allow = true,
    cloning_allowed = true,
    max_residents = 4,
    check_results_bound = false;
  
  $.mobile.ajaxEnabled = false;
  
  /*  * /
  $(window).on("resize.test", function() {
    $('#size-of-screen').html(window.outerHeight + " x " + window.outerWidth);
  });
  $(document).on("load.test", "body", function() {
    $('#size-of-screen').html(window.outerHeight + " x " + window.outerWidth);
  });
  
  $(document).on("pagecreate.filter", "[data-role='dialog'],[data-role='page']", function (e) {
    $.mobile.listview.prototype.options.filterInputType = "tel";
  });
  /* */
  
  // the global ready event
  $(function(){
    $("#unit_no").trigger("focus");
    $("#inventory-list form input").trigger("focus");
    $("#search").trigger("focus");
  });
  
  /* */
  $(document).on("click.login.form", "#login-submit", function (e) {
    e.preventDefault();
    var $this = $(this);
    var $form = $("#login-form");
    $.mobile.showPageLoadingMsg();
    var ajaxOptions = {
      url: $form.attr("action"),
      type: $form.attr("method"),
      data: $form.serialize(),
      dataType: "json",
      success: function (res) {
        if( res.error ){
          APP.utility.showErrorDialog( res.error );
        } else {
          //$.mobile.changePage( APP.settings.homePage );
          //$("body").attr( "id", APP.settings.homePageId );
          window.location.href = APP.settings.homePage;
        }
      },
      error: function(){
        APP.utility.showErrorDialog();
      }
    };
    $.ajax(ajaxOptions);
    return false;
  });
  
  $(document).on({
   "click.user.menu":  function (e) { $("#user-menu").toggle(); }/*,
   "mouseout.user.menu":  function (e) { $("#user-menu").fadeOut("slow"); }  */
  }, "#nav-user a");
  
  var checkin_results_select = function( $form, $dialog, listViewLinks, attr_key, attr_val_r, attr_val_l ){
    $(document).on("click.checkin.results", "#checkin "+listViewLinks, function (e) {
      e.preventDefault();
      var $this = $(this),
        $residentCheckin = $("#checkin-resident"),
        $checkinSubmit = $("#checkin-submit"),
        unit = $this.attr(attr_key),
        name = $this.attr(attr_val_r),
        $resident = $("#resident");

      $residentCheckin.data("cached-value", "<span class=\"unit\">"+unit+"</span> " + name);
      $residentCheckin.html($residentCheckin.data("cached-value"));
      $resident.val(unit);

      $("#checkin-resident-select-container").remove();  
      $("#checkin-icon").addClass("ui-icon-custom");
      $("#checkin-resident .unit").addClass("ui-text-custom");
      $checkinSubmit.button('enable');
      //$("#checkin-form #unit_no").val("").textinput('enable');
      $dialog.dialog("close");
      $(document).off("click.checkin.results");
      //$dialog.remove();
      return false;
    });
  };
  
  var lookup_lock = function (e) {
    e.preventDefault();
    var $this = $(this),
      lookupValue = $this.attr("value"),
      lookupBy = $this.attr("id"),
      $residentCheckin = $("#checkin-resident"),
      cached = $residentCheckin.data("cached"),
      $checkinSubmit = $("#checkin-submit");
    
    /* */
    if(lookupBy == "unit_no"){
      $("#checkin-form #resident_name").textinput('disable');
    } else if(lookupBy == "resident_name"){
      $("#checkin-form #unit_no").textinput('disable');
    }
    /* */
    
    if(lookupValue == cached && $residentCheckin.data("cached-value")) {
      $residentCheckin.html($residentCheckin.data("cached-value"));
      $checkinSubmit.button('enable');
      $("#checkin-icon").addClass("ui-icon-custom");
      $("#checkin-resident .unit").addClass("ui-text-custom");
    } else {
      $residentCheckin.html(APP.settings.selectResidentsMessage);
      $checkinSubmit.button('disable');
      $("#checkin-icon").removeClass("ui-icon-custom");
      $("#checkin-resident .unit").removeClass("ui-text-custom");
    }
    
    return false;
  };
  
  var lookup_resident = function (e){
    e.preventDefault();
    var $this = $(this),
      lookupValue = $this.attr("value"),
      lookupBy = $this.attr("id"),
      $residentCheckin = $("#checkin-resident"),
      cached = $residentCheckin.data("cached"),
      $checkinSubmit = $("#checkin-submit"),
      $resident = $("#resident");
    
    if(lookupValue != cached){  
      cached = null;
      $residentCheckin.data("cached", cached);
      $residentCheckin.data("cached-value", null);
    }
    
    if( !cached && lookupValue != "" ){
      $.mobile.showPageLoadingMsg();
      $residentCheckin.html(APP.settings.loadingResidentMessage);
      $residentCheckin.data("cached", lookupValue);
      $checkinSubmit.button('disable');
      var ajaxOptions = {
        url: APP.settings.residentsLookup,
        type: "POST",
        data: {"lookup": lookupValue, "by": lookupBy},
        dataType: "json",
        success: function(res){
          
          if(lookupBy == "unit_no"){
            $("#checkin-form #resident_name").textinput('enable');
          } else if(lookupBy == "name"){
            $("#checkin-form #unit_no").textinput('enable');
          }
          
          if(res.error){
            $residentCheckin.html( APP.settings.couldNotFindResidentMessage );
          } else {
            if(res.length > 1){              
              APP.utility.convertJsonToListView( res, null, checkin_results_select );
            } else {
              var unit = null;
              for( i in res ){ if( !i.match("length") ){ unit = i; break; } }
              if( unit != null ){
                $resident.val(unit);
                $residentCheckin.data("cached-value", "<span class=\"unit\">"+unit+"</span> " + res[unit]["rightv"].join(", "));
                $residentCheckin.html($residentCheckin.data("cached-value"));
                $("#checkin-icon").addClass("ui-icon-custom");
                $("#checkin-resident .unit").addClass("ui-text-custom");
                $checkinSubmit.button('enable');
              } else {
                $residentCheckin.html( APP.settings.couldNotFindResidentMessage );
              }
            }
          }
          
          $.mobile.hidePageLoadingMsg();
        },
        error: function(){
          APP.utility.showErrorDialog();
        }
      };
      $.ajax(ajaxOptions);
      return false;
    } else if ( cached ){
      if(lookupBy == "unit_no"){
        $("#checkin-form #resident_name").val("").textinput('enable');
      } else if(lookupBy == "resident_name"){
        $("#checkin-form #unit_no").val("").textinput('enable');
      }
      $residentCheckin.html($residentCheckin.data("cached-value"));
      $("#checkin-icon").addClass("ui-icon-custom");
      $("#checkin-resident .unit").addClass("ui-text-custom");
      $checkinSubmit.button('enable');
    } else {
      if(lookupBy == "unit_no"){
        $("#checkin-form #resident_name").val("").textinput('enable');
      } else if(lookupBy == "resident_name"){
        $("#checkin-form #unit_no").val("").textinput('enable');
      }
      $("#checkin-icon").removeClass("ui-icon-custom");
      $("#checkin-resident .unit").removeClass("ui-text-custom");
      $checkinSubmit.button('disable');
    }
    return false;
  };
  
  $(document).on({
    "blur.checkin.form": lookup_resident,
    "keyup.ckeckin.form": lookup_lock,
    }, "#checkin-form #unit_no, #checkin-form #resident_name");
  
  $(document).on("click.checkin.form", "#checkin-submit", function (e){
    e.preventDefault();
    var $this = $(this),
      $form = $("#checkin-form"),
      $residentCheckin = $("#checkin-resident");
    
    $.mobile.showPageLoadingMsg();
    var ajaxOptions = {
      url: $form.attr("action"),
      type: $form.attr("method"),
      data: $form.serialize(),
      dataType: "json",
      success: function(res){
        if(res.error){
          APP.utility.showErrorDialog(res.error);
        } else {
          $form[0].reset();
          qty_reset(1);
          $residentCheckin.html(APP.settings.selectResidentsMessage);
          $this.button("disable");
          $("#checkin-icon").removeClass("ui-icon-custom");
          $("#checkin-resident .unit").removeClass("ui-text-custom");
          $.mobile.hidePageLoadingMsg();
          $.mobile.silentScroll(100);
          $("#unit_no").trigger("focus");
        }
      },
      error: function(){
        APP.utility.showErrorDialog();
      }
    };
    $.ajax(ajaxOptions);
    return false;
  });

  $(document).on({
    "click.inventory.history-jump": function (e) {
      $.mobile.silentScroll($("#inventory-history").position().top);
      $("#inventory-history").trigger('expand');
      $("#inventory-history form input").trigger("focus");
    }
  }, "#inventory-history-jump");
  
  $(document).on({
    "expand.inventory.history": function (e) {
      $.mobile.silentScroll($("#inventory-history").position().top);
    },
    "collapse.inventory.history": function (e) {
      $.mobile.silentScroll($("#inventory-list").position().top);
      $("#inventory-list form input").trigger("focus");
    }
  }, "#inventory-history");
  
  $(document).on("change.pickup.form", "#inventory-pickup-form input[type='radio']", function (e) {
    var $this = $(this),
      $form = $("#inventory-pickup-form");

    $.mobile.showPageLoadingMsg();
    $form.submit();
    /* * /
    var ajaxOptions = {
      url: $form.attr("action"),
      type: $form.attr("method"),
      data: $form.serialize(),
      dataType: "json",
      success: function(res){
        if(res.error){
          APP.utility.showErrorDialog(res.error);
        } else {
          $.mobile.changePage("/checkin/");
          $.mobile.hidePageLoadingMsg();
        }
      },
      error: function(){
        APP.utility.showErrorDialog();
      }
    };
    $.ajax(ajaxOptions);
    /* */
  });
  /* */
  
  $(document).on({
    "change.checkin.qty" : function(event, ui) { 
      if(qtyh_allow == true){
        qty_allow = false;
        $("#qty").attr("value", this.value).slider('refresh');
        qty_allow = true;
      }
    },
    "keydown.checkin.qty" : function(event, ui) { 
      if(qtyh_allow == true){
        qty_allow = false;
        if( event.keyCode > 48 && event.keyCode < 58 ){
          var val = event.keyCode - 48;
          update_radio_qty(val);
          $("#qty").attr("value", val).slider('refresh');
        }
        qty_allow = true;
      }
    },
  }, "#checkin-qty #qty_helpers input[type='radio']");
  
  var qty_change = function(event, ui) {
    if(qty_allow == true){
      qtyh_allow = false;    
      update_radio_qty(this.value);
      qtyh_allow = true;
    }
  };
  
  var update_radio_qty = function (val) {
    var sels = "#checkin-qty #qty_helpers input[type='radio']",
      $inputList = $(sels),
      $input = $(sels+":eq("+(val-1)+")"),
      $inputSel = $(sels+":checked");
    if(val > 0 && val < 11){
      $input.attr("checked","checked");
    } else {
      $inputSel.attr("checked", false);
    }
    $inputList.checkboxradio("refresh");
  }
  
  var qty_reset = function (num){
    var $qty = $("#qty");
    qty_allow = false;
    qtyh_allow = false;
    update_radio_qty(num);
    $qty.attr("value", num).slider('refresh');
    qty_allow = true;
    qtyh_allow = true;
  }
  
  $(document).on({
    "change.checkin.qty": qty_change,
    "keyup.checkin.qty": qty_change 
    }, "#checkin-qty #qty");
  
  $(document).on("pagecreate.dialog", "[data-role='dialog']", function (e) {
    $("div[data-role='header'] a[data-icon='delete']").remove();
  });
  
  $(document).on("pagecreate.required", "[data-role='dialog'],[data-role='page']", function (e) {
    $("input[data-required='true']").addClass("required");
  });
  
  $(document).on("pageinit.search", "[data-role='dialog'],[data-role='page']", function (e) {
    $("div[data-role='content'] .ui-listview-filter .ui-input-search").addClass("ui-icon-searchfield-alt");
  });
  
  var searchFormToJsonToListViewCallBack = function( $form, $dialog, listViewLinks, attr_key, attr_val_r, attr_val_l ){
    $(document).on("click.search.results", listViewLinks, function (e) {
      e.preventDefault();
      var $this = $(this);
      $.mobile.changePage( APP.settings.residentUnit.replace( "{0}", $this.attr("href").replace("#","") ) + "?s=1" );
      return false;
    });
  }
  
  $(document).on("submit.search", "#search-form", function (e) {
    e.preventDefault();
    var $form = $(this),
      $search = $form.find("#search"),
      searchVal = $search.attr("value"),
      searchValInt = parseInt(searchVal),
      unit = ((searchValInt.toString().length == 10 || /^\d{3}-\d{3}-\d{4}$/.test(searchVal) ) ? 0 : searchValInt ),
      unitFull = null,
      unitNo = null,
      floorNo = null,
      displayUnitDirectDialog = false;

    if(unit > 0){
      unitFull = APP.utility.zeroFill(unit, 4);
      floorNo = parseFloat(unitFull.substr(0,2));
      unitNo = parseFloat(unitFull.substr(2,2));
      if( unitNo >= APP.settings.unitStart && unitNo <= APP.settings.unitEnd && floorNo >= APP.settings.floorStart && floorNo <= APP.settings.floorEnd ){
        displayUnitDirectDialog = true; 
      }
    }

    if( displayUnitDirectDialog ){
      $.mobile.changePage( APP.settings.residentUnit.replace( "{0}", searchVal ) + "?s=1" );
    } else {
      // fire off and display regular search
      $.mobile.showPageLoadingMsg();
      var ajaxOptions = {
        url: $form.attr("action"),
        type: $form.attr("method"),
        data: $form.serialize(),
        dataType: "json",
        success: function(res){
          if(res.error){
            $.mobile.hidePageLoadingMsg();
            APP.utility.showErrorDialog(res.error);
          } else {
            var displaySearch = true;
            if( res.length == 1 ){
              var unit = null;
              for( i in res ){ if( !i.match("length") ){ unit = i; break; } }
              if( unit != null ){
                displaySearch = false;
                $.mobile.changePage( APP.settings.residentUnit.replace( "{0}", unit ) + "?s=1" );
              }
            }
            if( displaySearch == true ){
              APP.utility.convertJsonToListView( res, $form, searchFormToJsonToListViewCallBack );
            }
          }
        },
        error: function(){
          $.mobile.hidePageLoadingMsg();
          APP.utility.showErrorDialog();
        }
      };
      $.ajax(ajaxOptions);
    }
    return false;
  });
  
  var resident_clone = function(e){
    var $this = $(this),
      $residentClone = $(".resident-container"),
      $residentNext = $("#next-resident"),
      residentNextInt = $residentNext.attr("value"),
      residentNextIntNew = parseInt(residentNextInt) + 1;
      
      if( $residentClone.length > 0 ){
        // clone #resident-clone
        var $clone = $($residentClone[0]).clone(),
          newId = $clone.attr("id")+"-"+residentNextInt,
          $inputs = $clone.find("input"),
          $ids = $clone.find("input[id]"),
          $count = $clone.find(".resident-count"),
          $clear = $clone.find(".resident-delete");
        $clear.remove();
        $clone.attr("id", newId);
        $ids.each(function(i){
          var $this = $(this),
            id = $this.attr("id"),
            newId = id+"-"+residentNextInt;
          $this.attr("id",newId);
        });
        $inputs.each(function(i){
          var $this = $(this),
            name = $this.attr("name"),
            newName = name.replace(/resident\[\d\]/,"resident["+residentNextInt+"]");
          $this.attr("value","");
          $this.removeClass("ui-focus");
          $this.attr("name", newName);
        });
        $count.html(residentNextInt);

        if( residentNextIntNew <= max_residents ){
          $this.parent().find(".resident-count").html(residentNextIntNew);
          $residentNext.attr("value", residentNextIntNew);
        } else {
          $this.parent().remove();
          $residentNext.remove();
        }
        $clone.appendTo("#resident-clone-container");
      } else {
        APP.utility.showErrorDialog();
      }
      
  };
  
  $(document).on("click.resident.clone", "#resident-edit #resident-add", resident_clone);
  
  $(document).on("click.resident.delete", "#resident-edit .resident-delete", function (e) {
    e.preventDefault();
    var $this = $(this),
      href = $this.attr("href"),
      $parent = $this.parent().parent().parent();
      //, $residentNext = $("#next-resident")
      //, $residentAdd = $("#resident-add")
      //, $residentAddCount = $residentAdd.parent().find(".resident-count");
    
    $('<div>').simpledialog2({
      mode: 'button',
      headerText: false,
      headerClose: false,
      themeDialog: 'c',
      buttonPrompt: "Are you sure?",
      top: "50%",
      left: "50%",
      dialogId: "resident-delete-dialog",
      zindex: 9999,
      width: "220px",
      buttons : {
        'Yes': {
          click: function () { 
            $.mobile.showPageLoadingMsg();
            var ajaxOptions = {
              url: href,
              type: "POST",
              dataType: "json",
              success: function(res){
                if(res.error){
                  APP.utility.showErrorDialog(res.error);
                } else {
                  // remove the data from the page
                  $parent.remove();
                  $residentContainers = $(".resident-container");
                  residentContainersCount = $residentContainers.length;
                  //console.log(residentContainersCount);
                  // update the resident count correctly
                  //if( residentContainersCount == 0 ){
                    window.location.href = res.href;
                    //$.mobile.changePage( href.replace(/\/delete.*/,'/edit/') , { reloadPage: true } );
                  //} else {
                    //$residentNext.attr("value", (residentContainersCount-1));
                    //$residentAddCount.html(residentContainersCount);
                    //$.mobile.hidePageLoadingMsg();
                  //}
                }
              },
              error: function(){
                APP.utility.showErrorDialog();
              }
            };
            $.ajax(ajaxOptions);
          },
          icon: "false",
          theme: "d",
          classes: "ui-icon-nocorners ui-icon-noborder"
        },
        'No': {
          click: function () {
            $.mobile.hidePageLoadingMsg();
          },
          icon: "false",
          theme: "c",
          classes: "ui-icon-nocorners ui-icon-noborder"
        }
      }
    });
    return false;
  });
  
  $(document).on("click.resident.delete-all", "#clear-unit-info", function (e) {
    e.preventDefault();
    var $this = $(this),
      href = $this.attr("href");
    
    $('<div>').simpledialog2({
      mode: 'button',
      headerText: false,
      headerClose: false,
      themeDialog: 'c',
      buttonPrompt: "Are you sure?",
      top: "50%",
      left: "50%",
      dialogId: "resident-delete-all-dialog",
      zindex: 9999,
      width: "240px",
      buttons : {
        'Delete': {
          click: function () { 
            $.mobile.showPageLoadingMsg();
            var ajaxOptions = {
              url: href,
              type: "POST",
              dataType: "json",
              success: function(res){
                if(res.error){
                  APP.utility.showErrorDialog(res.error);
                } else {
                  //$.mobile.changePage( href.replace(/\/delete.*/,'/edit/'), { reloadPage: true } );
                  //$.mobile.hidePageLoadingMsg();
                  window.location.href = res.href;
                }
              },
              error: function(){
                APP.utility.showErrorDialog();
              }
            };
            $.ajax(ajaxOptions);
          },
          icon: "false",
          theme: "d"
        },
        'Cancel': {
          click: function () {
            $.mobile.hidePageLoadingMsg();
          },
          icon: "false",
          theme: "c"
        }
      }
    });
    return false;
  });
  
  $(document).on("click.user.delete", "#delete-user-info", function (e) {
    e.preventDefault();
    var $this = $(this),
      href = $this.attr("href");
    
    $('<div>').simpledialog2({
      mode: 'button',
      headerText: false,
      headerClose: false,
      themeDialog: 'c',
      buttonPrompt: "Are you sure?",
      top: "50%",
      left: "50%",
      dialogId: "user-delete-dialog",
      zindex: 9999,
      width: "240px",
      buttons : {
        'Delete': {
          click: function () { 
            $.mobile.showPageLoadingMsg();
            var ajaxOptions = {
              url: href,
              type: "POST",
              dataType: "json",
              success: function(res){
                if(res.error){
                  APP.utility.showErrorDialog(res.error);
                } else {
                  $.mobile.changePage( '/' );
                  $.mobile.hidePageLoadingMsg();
                }
              },
              error: function(){
                APP.utility.showErrorDialog();
              }
            };
            $.ajax(ajaxOptions);
          },
          icon: "false",
          theme: "d"
        },
        'Cancel': {
          click: function () {
            $.mobile.hidePageLoadingMsg();
          },
          icon: "false",
          theme: "c"
        }
      }
    });
    return false;
  });
  
  $(document).on("click.clipboard", "#residents-emails-article .clipboard-ajax", function (e) {
    e.preventDefault();
    var $this = $(this),
      $clipboard = $("#clipboard"),
      $clipboardContainer = $("#clipboard-container");
      
    $.mobile.showPageLoadingMsg();
    var ajaxOptions = {
      url: $this.attr("href"),
      dataType: "json",
      success: function(res){
        if(res.error){
          APP.utility.showErrorDialog(res.error);
        } else {
          $.mobile.hidePageLoadingMsg();
          $clipboard.val(res.e.join('; '));
          $clipboardContainer.fadeIn();
          $clipboard.focus();
          $clipboard.select();
        }
      },
      error: function(){
        APP.utility.showErrorDialog();
      }
    };
    $.ajax(ajaxOptions);
    return false;
  });
  
  $(document).on("click.clipboard.close", "#clipboard-container #clipboard-close", function (e) {
    e.preventDefault();
    var $clipboard = $("#clipboard"),
      $clipboardContainer = $("#clipboard-container");
    
    $clipboardContainer.fadeOut();
    $clipboard.val("");
    
    return false;
  });
  
  $(document).on("click.notes.add", "#resident-note-add", function (e) {
    var $this = $(this),
      $form = $("#resident-note-form"),
      $textarea = $('#resident-note-textarea'),
      msg = $textarea.val(),
      $noteContainer = $('#note-container');

    $.mobile.showPageLoadingMsg();
    
    var ajaxOptions = {
      url: $form.attr("action"),
      type: $form.attr("method"),
      data: $form.serialize(),
      dataType: "json",
      success: function(res){
        if(res.error){
          APP.utility.showErrorDialog(res.error);
        } else {
          $form[0].reset();
          var ulHTML = '';
          ulHTML += '<ul class="note-item" data-inset="true" data-role="listview" data-theme="e">';
          ulHTML += '<li class="note-text">';
          ulHTML += '<a class="note-text-wrap" href="#show-details-'+res.d+'">'+msg+'</a>';
          ulHTML += '<a class="note-delete ui-icon-noborder ui-icon-nocorners ui-icon-fill" data-role="splitbutton" data-icon="delete ui-icon-custom" data-theme="a" href="/resident-unit/'+res.u+'/delete-note/'+res.d+'/">Delete</a>';
          ulHTML += '</li>';
          ulHTML += '<li class="note-text-details">';
          ulHTML += '<hr>';
          ulHTML += '<div class="note-concierge">';
          ulHTML += '<em>Concierge:</em> ';
          ulHTML += res.p.f+' '+res.p.l+'.';
          ulHTML += '</div>';
          ulHTML += '<div class="note-created">';
          ulHTML += '<em>Created:</em> ';
          ulHTML += res.c;
          ulHTML += '</div>';
          ulHTML += '<br class="clear">';
          ulHTML += '</li>';
          ulHTML += '</ul>'; 
          
          var $ul = $(ulHTML);
          $noteContainer.prepend($ul);
          $ul.listview();
          $.mobile.hidePageLoadingMsg();
        }
      },
      error: function(){
        APP.utility.showErrorDialog();
      }
    };
    $.ajax(ajaxOptions);
  });
  
  $(document).on("click.notes.details", "#note-container .note-text-wrap", function (e) {
    //e.preventDefault();
    
    var $this = $(this),
      $parent = $this.parents(".note-text"),
      $next = $parent.parent(".note-item").children(".note-text-details");
    
    if( $next.data("shown") == true ){
      $next.animate({marginTop: "-42px"});
      $next.data("shown", false);
    } else {
      $next.animate({marginTop: 0});
      $next.data("shown", true);
    }
    
    //return false;
  });
  
  $(document).on("click.notes.delete", "#note-container a.note-delete", function (e) {
    e.preventDefault();
    var $this = $(this);
    
    $.mobile.showPageLoadingMsg();
    
    var ajaxOptions = {
      url: $this.attr("href"),
      type: "POST",
      dataType: "json",
      success: function(res){
        if(res.error){
          APP.utility.showErrorDialog(res.error);
        } else {
          $this.parent().parent().remove();
          $.mobile.hidePageLoadingMsg();
        }
      },
      error: function(){
        APP.utility.showErrorDialog();
      }
    };
    $.ajax(ajaxOptions);
    return false;
  });
  
})(jQuery,this,this.document);