const StudentView = Backbone.View.extend({
  tagName: 'li',

  initialize: function(options) {
    this.template = options.template;
    this.bus = options.bus;

    // Re-render whenever the model changes
    this.listenTo(this.model, 'change', this.render);

    // Pay attention to company selections
    this.listenTo(this.bus, 'select-company', this.visualizeScore);
    this.listenTo(this.bus, 'unselect-company', this.visualizeScore);

    this.$el.addClass("student");

    // Cards should always be ready to place on the page
    this.render();
  },

  visualizeScore: function() {
    // Translate score into color classes
    var score;
    if (this.bus.hasCompany()) {
      // If a company is selected, display the score for that company
      var company = this.bus.company();
      score = this.model.scoreFor(company);

    } else {
      // If no company is selected, display the score for the
      // current placement.
      score = this.model.get('score');
    }

    Util.removeScoreClasses(this.$el);
    this.$el.addClass(Util.classForScore(score));

    this.$('.student-score').html(score ? "(" + score + ")" : "");
  },

  render: function() {
    var contents = this.template(this.model.attributes);
    this.$el.html(contents);

    if (this.model.get('selected')) {
      this.$el.addClass('selected');
    } else {
      this.$el.removeClass('selected');
    }

    this.visualizeScore();

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
    event.stopPropagation();
    console.log("Student clicked");

    // Ignore the click that results from a drag
    if (this.dragging) {
      return;

    }

    // If a company was selected, unselect it before
    // selecting the student
    if (this.bus.hasCompany()) {
      this.bus.unselectCompany();
    }

    if (this.model.get('selected')) {
      this.bus.unselectStudent();
      return;

    } else if (this.bus.hasStudent()) {
      this.bus.unselectStudent();

    }
    this.bus.selectStudent(this.model);
  },

  onDragStart: function(event) {
    console.log("In drag start");

    // If a company was selected, unselect it before
    // selecting the student
    if (this.bus.hasCompany()) {
      this.bus.unselectCompany();
    }

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
