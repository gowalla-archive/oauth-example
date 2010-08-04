$(document).ready(function() {
        
  $("a.check-in.enabled").live('click', function(e) {
    e.preventDefault();
    var latitude  = parseFloat($(".coordinate").attr("data-latitude"));
    var longitude = parseFloat($(".coordinate").attr("data-longitude"));
    $.post($(this).attr("href"), {"lat": latitude, "lng": longitude}, function(data) {
      $("#last-check-in img.stamp").attr('src', data["spot"]["image_url"]);
      $("#last-check-in .spot-name").text(data["spot"]["name"]);
      $("#last-check-in time").attr('datetime', Date()).text("Just now!");
      $("#last-check-in .message").text("");
      $("#last-check-in").animate({"background":"yellow"}, "fast").animate({"background":"#fff"}, "slow");
    }, 'json');
  })
  
  function successCallback(position) {
    $.get("/spots?" + "lat=" + position.coords.latitude + "&lng=" + position.coords.longitude, {}, function(data) {
      $("#nearby-spots").append(data);
    });
  }

  function errorCallback(error) {
    if (console.log) {
      console.log(error);
    }
  }
  
  if(navigator.geolocation){
    errorCallback("Yes, Geolocation is Supported");
    navigator.geolocation.getCurrentPosition(successCallback, errorCallback);
  } else {
    errorCallback("No, Geolocation is not Supported");
  }
});