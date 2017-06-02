const PlacementWorkbenchView = Backbone.View.extend({
  initialize: function(options) {
    this.bindUserEvents();

    this.studentBus = new StudentBus();
    this.busDetails = new StudentBusView({
      model: this.studentBus,
      el: this.$('#bus-details')
    });
    this.undoManager = new Backbone.UndoManager();

    this.undoManager.register(this.model.unplacedStudents.students);
    this.unplacedStudentsView = new CompanyView({
      model: this.model.unplacedStudents,
      el: this.$('#unplaced-students'),
      bus: this.studentBus
    });

    this.companyViews = [];
    this.companyListElement = this.$('#companies');

    this.model.companies.each(function(company) {
      this.undoManager.register(company.students);
      this.addCompany(company);
    }, this);

    // Do initial work around the list of companies.
    this.onCompanyChange()

    this.listenTo(this.model.companies, 'update', this.render);
    this.listenTo(this.model.companies, 'add', this.addCompany);

    this.undoManager.startTracking();

    this.toggleButtons();
  },

  bindUserEvents: function() {
    $(document).on('keydown', this.onKeypress.bind(this));
    this.saveButton = $('#toolbar-save-button');
    this.saveButton.on('click', this.onSave.bind(this));
    this.undoButton = $('#toolbar-undo-button');
    this.undoButton.on('click', this.onUndo.bind(this));
    this.redoButton = $('#toolbar-redo-button');
    this.redoButton.on('click', this.onRedo.bind(this));
  },

  onCompanyChange: function() {
    // update scores
    let score = 0;
    this.model.companies.forEach(function(company) {
      score += company.getScore();
    }, this);
    this.studentBus.set('score', score);

    this.toggleButtons();
  },

  addCompany: function(company) {
    const companyView = new CompanyView({
      model: company,
      bus: this.studentBus
    });
    this.companyViews.push(companyView);
    this.listenTo(company, 'change', this.onCompanyChange);
  },

  toggleButtons: function() {
    // Undo button
    if (this.canUndo()) {
      this.undoButton.removeClass('disabled');
    } else {
      this.undoButton.addClass('disabled');
    }

    // Redo button
    if (this.canRedo()) {
      this.redoButton.removeClass('disabled');
    } else {
      this.redoButton.addClass('disabled');
    }
  },

  render: function() {
    this.companyListElement.empty();
    var row;

    this.companyViews.forEach(function(companyView, i) {
      if (i % 4 == 0) {
        if (row) {
          this.companyListElement.append(row);
        }
        row = $('<div class="row"></div>');
      }
      companyView.$el.addClass('large-3 columns');
      row.append(companyView.el);
    }, this);

    if (row.html() != "") {
      this.companyListElement.append(row);
    }

    return this;
  },

  onKeypress: function(event) {
    var code = event.keyCode || event.which;
    var command = event.ctrlKey || event.metaKey;
    if (command && code == 83) {
      // cmd+s -> save
      this.onSave();
      event.preventDefault();

    } else if (command && event.shiftKey && code == 90) {
      // cmd+shift+u -> redo
      this.onRedo()
      event.preventDefault();

    } else if (command && code == 90) {
      // cmd+u -> undo
      this.onUndo();
      event.preventDefault();
    }
  },

  onSave: function() {
    console.debug("Saving placement");
    result = this.model.save(null, { fromSave: true });
    console.log(result);
  },

  onUndo: function() {
    console.debug("Undoing action");

    // Undo twice: once for selecting the student, and once for the move
    // TODO DPR: figure out why the undomanager is picking
    // up the student select, since I only registered the collections
    this.undoManager.undo(true);
    this.undoManager.undo(true);
  },

  onRedo: function() {
    console.debug("Redoing action");

    // As above, need to fire twice
    this.undoManager.redo(true);
    this.undoManager.redo(true);
  },

  canUndo: function() {
    return this.undoManager.isAvailable('undo');
  },

  canRedo: function() {
    return this.undoManager.isAvailable('redo');
  }
});
