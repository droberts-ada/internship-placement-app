const Ranking = Backbone.Model.extend({
  initialize: function(attributes, options) {
    this.company = options.companies.get(attributes.company_id);
    this.set('company_name', this.company.get('name'));
  },

  score: function() {
    return this.get('score');
  },

  tooltipText: function() {
    text = '';
    text += this.company.get('name') + ': ';
    text += this.get('interview_result') + ' / ';
    text += this.get('student_preference') + ' / ';
    text += this.score();
    // TODO DPR: get some sort of a modal or something
    // text += '\n' + this.get('interview_result_reason');
    return text;
  }
});
