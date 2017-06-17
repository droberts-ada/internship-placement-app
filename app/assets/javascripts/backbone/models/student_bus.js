const StudentBus = Backbone.Model.extend({
  defaults: {
    // Underscore templates can't infer absent values,
    // so we must explicitly set student to null
    student: null,
    company: null,
    score: 0
  },

  select: function(role, target) {
    current = this.get(role);
    if (current) {
      if (current == target) {
        console.log("Reselected " + role + " " + target.get('name'));
        return;
      } else {
        this.unselect(role, target);
      }
    }

    this.set(role, target);
    target.set('selected', true);
    this.trigger('select', role, target);
  },

  selectStudent: function(student) {
    this.select('student', student);
    this.listenTo(student, 'move', this.unselectStudent);
  },

  selectCompany: function(company) {
    this.select('company', company)
  },

  unselect: function(role) {
    var target = this.get(role);
    if (target) {
      target.set('selected', false);
      this.set(role, null);
      this.trigger('unselect', role);
    } else {
      console.error("student_bus.unselect() called with role " + role + ", but no such role was selected!");
    }
    return target;
  },

  unselectStudent: function() {
    var student = this.unselect('student');
    if (student) {
      this.stopListening(student, 'move');
    }
  },

  unselectCompany: function() {
    this.unselect('company');
  },

  hasStudent: function() {
    // !! for truthyness
    return !!this.get('student');
  },

  hasCompany: function() {
    return !!this.get('company');
  }
});
