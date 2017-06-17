const Student = Backbone.Model.extend({
  defaults: {
    score: 0,
    selected: false
  },

  initialize: function(attributes, options) {
    this.rankings = new RankingCollection(attributes.rankings, options);
    this.listenTo(this, 'move', this.onMove);
    this.updateTooltipText();
  },

  onMove: function(student, company) {
    if (student != this) {
      throw "In student.onMove, student was not this";
    }

    var ranking = this.rankings.get(company.id);
    // data will be undefined if we're moving into
    // the list of unplaced students
    if (ranking) {
      var score = ranking.get('interview_result') * ranking.get('student_preference');
      this.set('score', score);
    } else {
      this.set('score', 0);
    }

    this.currentCompany = company;
    this.updateTooltipText();
  },

  scoreFor: function(company) {
    var ranking = this.rankings.get(company.id);
    if (ranking) {
      return ranking.score();
    } else {
      return undefined;
    }
  },

  interviewedWith: function(company) {
    return !!this.rankings.get(company.id);
  },

  updateTooltipText: function() {
    var text = `${this.get('name')}\n`;

    text += '<interview-result>/<student-preference>/<score>';
    this.rankings.each(function(ranking) {
      text += '\n\n';
      text += ranking.tooltipText();
    });

    if (this.currentCompany) {
      var ranking = this.rankings.get(this.currentCompany.id);
      if (ranking) {
        text += `\n\nComments from ${this.currentCompany.get('name')}:\n`;
        text += ranking.get('interview_result_reason');
      }
    }

    this.set('tooltipText', text);
  }
});
