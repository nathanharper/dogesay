(function() {

document.getElementById('dogemit').onclick = function() {
  var dogepic = document.getElementById('dogepic').value
     ,dogesay = document.getElementById('dogesay').value;
  window.location = window.location.origin + '/' + encodeURIComponent(dogesay) + '?image=' + dogepic
}

})();
