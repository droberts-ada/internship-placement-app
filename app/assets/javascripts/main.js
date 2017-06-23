// Use <# for underscore templates so we don't conflict with ERB
_.templateSettings = {
  interpolate: /\<\#\=(.+?)\#\>/g,
  escape: /\<\#\-(.+?)\#\>/g,
  evaluate: /\<\#(.+?)\#\>/g
};

const Util = {
  classForScore: function(score) {
    if (score > 20) {
      return 'match excellent-match';
    } else if (score > 15) {
      return 'match good-match';
    } else if (score > 9) {
      return 'match mediocre-match';
    } else if (score) {
      return 'match bad-match';
    } else {
      return undefined;
    }
  },
  removeScoreClasses: function(element) {
    element = $(element);
    element.removeClass('match');
    element.removeClass('excellent-match');
    element.removeClass('good-match');
    element.removeClass('mediocre-match');
    element.removeClass('bad-match');
  }
};

// toastr is a library for non-blocking popup notifications
toastr.options = {
  "closeButton": true,
  "debug": false,
  "newestOnTop": false,
  "progressBar": false,
  "positionClass": "toast-top-right",
  "preventDuplicates": false,
  "onclick": null,
  "showDuration": "1000",
  "hideDuration": "1000",
  "timeOut": "5000",
  "extendedTimeOut": "1000",
  "showEasing": "swing",
  "hideEasing": "linear",
  "showMethod": "fadeIn",
  "hideMethod": "fadeOut"
};
