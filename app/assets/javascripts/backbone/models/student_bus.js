const StudentBus = Backbone.Model.extend({
  defaults: {
    // Underscore templates can't infer absent values,
    // so we must explicitly set student to null
    student: null,
    score: 0
  },

  selectStudent: function(student) {
    currentStudent = this.get('student');
    if (currentStudent) {
      if (currentStudent == student) {
        console.log("Reselected student " + student.get('name'));
        return;
      } else {
        this.unselectStudent();
      }
    }

    this.set('student', student);
    student.set('selected', true);
    this.listenTo(student, 'move', this.unselectStudent);
    this.trigger('select', student);
  },

  unselectStudent: function() {
    var student = this.get('student');
    if (student) {
      this.stopListening(student, 'move');
      student.set('selected', false);
      this.set('student', null);
      this.trigger('unselect');
    } else {
      console.error("student_bus.unselectStudent() called, but no student was selected!");
    }
  },

  hasStudent: function() {
    // !! for truthyness
    return !!this.get('student');
  },

  student: function() {
    return this.get('student');
  }
});
