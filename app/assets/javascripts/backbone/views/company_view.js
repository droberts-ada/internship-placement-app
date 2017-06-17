const CompanyView = Backbone.View.extend({
  tagName: 'li',
  className: 'company-outer',
  initialize: function(options) {
    // TODO: compile once and share
    this.template = _.template($('#company-template').html());
    this.studentTemplate = _.template($('#student-template').html());
    this.emptySlotTemplate = _.template($('#empty-slot-template').html());

    this.bus = options.bus;
    this.listenTo(this.bus, 'select', this.showMatchQuality)
    this.listenTo(this.bus, 'unselect', this.hideMatchQuality)

    this.cards = [];
    this.model.students.forEach(function(student) {
      this.addCard(student);
    }, this);

    // Listen for standard model events
    this.listenTo(this.model.students, 'add', this.addCard);
    this.listenTo(this.model.students, 'remove', this.removeCard);
    this.listenTo(this.model, 'change', this.render);

    this.render();
  },

  showMatchQuality: function(role, target) {
    if (role == 'student') {
      var student = target;
      const score = student.scoreFor(this.model);

      // Clear any existing score display
      this.hideMatchQuality();

      // score will be undefined (falsey) if the student
      // didn't interview at this company
      if (score) {
        this.$el.addClass(Util.classForScore(score));
      }
    }
  },

  hideMatchQuality: function(role) {
    if (role == 'student') {
      Util.removeScoreClasses(this.el);
    }
  },

  addCard: function(student) {
    // Create a new card for the student
    const card = new StudentView({
      model: student,
      template: this.studentTemplate,
      bus: this.bus
    });

    // Add it to our list of cards
    this.cards.push(card);
  },

  removeCard: function(student) {
    this.cards = this.cards.filter(function(card) {
      return card.model != student;
    });
  },

  render: function() {
    // console.log("In company.render for " + this.model.get("name"));
    const contents = this.template(this.model.attributes)
    this.$el.html(contents);
    this.studentListElement = this.$('.student-list');
    this.studentListElement.empty();

    // Add assigned students to the list
    this.cards.forEach(function(card) {
      // Make sure the student is all the way rendered
      // XXX DPR: wouldn't expect to need this, but it seems that the classes added by
      // jquery-draggable don't stay attached to the element's $el.
      // Probably a similar problem to the delegate events thing.
      // For now just re-render, since that's cheap anyway, maybe look into
      // adding functionality to delegateEvents in the future.
      card.render();
      this.studentListElement.append(card.el);
    }, this);

    // Render empty slots
    const emptySlots = this.model.get('slots') - this.model.students.length;
    for (let i = 0; i < emptySlots; i++) {
      this.studentListElement.append(this.emptySlotTemplate());
    }

    this.$el.droppable({
      drop: this.onDrop.bind(this),
      accept: function (element) {
        const student = this.bus.get('student');
        return student && !this.model.students.contains(student) && this.model.canAdd(student);
      }.bind(this)
    });

    if (this.model.get('selected')) {
      this.$el.addClass('selected');
    } else {
      this.$el.removeClass('selected');
    }

    return this;
  },

  events: {
    'click': 'onClick',
    'dragover': 'onDragover',
    'drop': 'onDrop'
  },

  addStudent: function() {
    let student = this.bus.get('student');
    if (student) {
      // Click on the company the student is already in
      // -> unselect, even if this company is full
      if (this.model.students.contains(student)) {
        this.bus.unselectStudent();
        return;
      }

      // Go no further if the student can't be added
      // to this company for any reason
      if (!this.model.canAdd(student)) {
        return;
      }

      console.log("Moving student " + student.get('name') + " into company " + this.model.get('name'));
      // The move has to come before the add - that way the
      // student has a chance to update its score before
      // the 'add' event bubbles up to the PlacementView
      this.model.students.add(student);
    } else {
      console.log("No student selected");
    }
  },

  onClick: function(event) {
    console.log("In CompanyView.onClick")
    if (this.bus.dragging) {
      // Drag event on a selected student generates
      // a click here, so make sure we're not in
      // the middle of a drag before doing anything.
      return;

    } else if (this.bus.hasStudent()) {
      this.addStudent();

    } else if (this.model.get('selected')){
      this.bus.unselectCompany();

    } else {
      this.bus.selectCompany(this.model);
    }
  },

  onDragover: function(event) {
    event.preventDefault();
  },

  onDrop: function(event) {
    console.log("In CompanyView.onDrop()");

    this.addStudent();
  }
})
