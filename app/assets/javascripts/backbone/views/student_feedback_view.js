const StudentFeedbackView = Backbone.View.extend({
  initialize: function() {
    this._resetModel();
  },

  render: function() {
    // Enable chained calls
    return this;
  },

  events: {
    'change .student-feedback--name': 'onNameSelect',
  },

  onNameSelect: function() {
    const $nameSelect = this.$('.student-feedback--name');
    const studentId = $nameSelect.val();

    if(studentId === '') {
      this._resetModel();
      this.render();
    }
  },

  _resetModel: function() {
    this.model = {
      studentId: null,
      companies: [],
    };
  },
});
