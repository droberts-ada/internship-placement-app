const PlacementWorkbenchView = Backbone.View.extend({
  initialize: function(options) {
    this.bindUserEvents();

    this.whiteboardElement = this.$('#workbench-whiteboard textarea');
    this.whiteboardElement.on('input', _.debounce(this.onSave.bind(this), 500));

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

    this.listenTo(this.model.companies, 'update', this.render);
    this.listenTo(this.model.companies, 'add', this.addCompany);

    this.undoManager.startTracking();

    this.updateUI();
  },

  bindUserEvents: function() {
    $(document).on('keydown', this.onKeypress.bind(this));
    this.exportButton = $('#toolbar-export-button');
    this.exportButton.on('click', this.onExport.bind(this));
    this.undoButton = $('#toolbar-undo-button');
    this.undoButton.on('click', this.onUndo.bind(this));
    this.redoButton = $('#toolbar-redo-button');
    this.redoButton.on('click', this.onRedo.bind(this));
    this.forkButton = $('#toolbar-fork-button');
    this.forkButton.on('click', this.onFork.bind(this));
  },

  onCompanyChange: function() {
    this.updateUI();
    this.onSave();
  },

  updateUI: function() {
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
        row = $('<div class="row fullWidth"></div>');
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
    } else if (code == 27) {
      // esc -> unselect
      this.studentBus.unselectCompany();
      this.studentBus.unselectStudent();
    }
  },

  onSave: _.debounce(function() {
    console.debug("Saving placement");
    result = this.model.save(null, {
      whiteboard: this.whiteboardElement.val(),
      fromSave: true,
      success: (model, response) => {
        var name = model.get('name');
        name = name ? name : model.id;
        toastr.success("Successfully saved placement " + name);
      },
      error: (model, response) => {
        console.debug("In model save error callback, response:");
        console.debug(response.responseJSON);
        var name = model.get('name');
        name = name ? name : model.id;
        var text = "Could not save placement " + name + ": " + response.responseJSON.message;

        _.mapObject(response.responseJSON.errors, (value, key) => {
          text += `\n  ${value}: ${key}`
        });

        // console.log(response);
        toastr.error(text);
      }
    });
  }, 300), // Batch all save attempts within a 300ms window

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
  },

  onFork: function(event) {
    event.preventDefault();

    // Compile the template exactly once
    if (!this.forkSuccessTemplate) {
      this.forkSuccessTemplate = _.template($('#fork-success-template').html());
    }

    url = this.forkButton.attr('action');
    $.post({
      data: {},
      dataType: 'json',
      url: url

    }).done((response, textStatus, jqXHR) => {
      var text = this.forkSuccessTemplate(response.placement);
      toastr.success(text);

    }).fail((response, textStatus, jqXHR) => {
      var text = "Failed to save placement";
      toastr.error(text);
    });

  },

  onExport: function(event) {
    event.preventDefault();

    // Compile the templat exactly once
    if (!this.exportSuccessTemplate) {
      this.exportSuccessTemplate = _.template($('#export-success-template').html());
    }

    url = this.exportButton.attr('action');
    $.post({
      data: {},
      dataType: 'json',
      url: url

    }).done((response, textStatus, jqXHR) => {
      var text = this.exportSuccessTemplate(response);
      toastr.success(text);

    }).fail((response, textStatus, jqXHR) => {
      const errors = response.responseJSON.errors;

      let text = "Failed to export placement";
      if (errors && errors.length > 0) {
        text = errors[0];
      }

      toastr.error(text);
    });
  }
});
