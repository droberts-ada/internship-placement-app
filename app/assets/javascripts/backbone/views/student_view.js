const StudentView = Backbone.View.extend({
  tagName: 'li',

  initialize: function(options) {
    this.template = options.template;
    this.bus = options.bus;

    // Re-render whenever the model changes
    this.listenTo(this.model, 'change', this.render);

    this.$el.addClass("student");

    // Cards should always be ready to place on the page
    this.render();
  },

  render: function() {
    var contents = this.template(this.model.attributes);
    this.$el.html(contents);

    if (this.model.get('selected')) {
      this.$el.addClass('selected');
    } else {
      this.$el.removeClass('selected');
    }

    this.$el.addClass(Util.classForScore(this.model.get('score')));

    this.$el.draggable({
      start: this.onDragStart.bind(this),
      stop: this.onDragStop.bind(this),
      helper: 'clone',
      snap: '.match .empty.student, #unplaced-students .empty.student',
      snapMode: 'inner',
      snapTolerance: 10,
      revert: 'invalid'
    });

    // Re-bind events
    this.delegateEvents();

    // Enable chained calls
    return this;
  },

  events: {
    'click': 'onClick'
  },

  onClick: function(event) {
    console.log("Student clicked");
    if (this.dragging) {
      // ignore the click that results from a drag
      return;
    }


    if (this.model.get('selected')) {
      this.bus.unselectStudent();
      return;

    } else if (this.bus.hasStudent()) {
      this.bus.unselectStudent();

    }
    this.bus.selectStudent(this.model);
    event.stopPropagation();
  },

  onDragStart: function(event) {
    console.log("In drag start");
    // TODO: when selected, the element is redrawn, removing it from under the mouse!
    this.bus.selectStudent(this.model);
    this.bus.dragging = true;
  },

  onDragStop: function(event) {
    console.log("In drag stop");
    this.bus.dragging = false;
    // Stop event triggers *after* the drop event
    // if (this.bus.hasStudent()) {
    //   this.bus.unselectStudent();
    // }
  }
})
