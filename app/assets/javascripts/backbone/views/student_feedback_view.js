const StudentFeedbackView = Backbone.View.extend({
  initialize: function() {
    this._resetModel();

    this.buckets = new Array(6);
    this.buckets.fill('very interested', 0, 3);
    this.buckets.fill('interested', 3, 5);
    this.buckets.fill('somewhat interested', 5, 6);
  },

  render: function() {
    const companies = this.model.companies;
    const companyViews = _.map(companies, (company, index) => {
      return new StudentFeedbackCompanyView({
        model: _.extend({}, company, {rank: this.buckets[index]}),
        onRankChange: this.onRankChange.bind(this),
      });
    });

    const $companies = this.$('.student-feedback--companies');
    $companies.empty();

    companyViews.forEach((companyView) => {
      $companies.append(companyView.render().$el);
    });

    // If we have enough information to submit rankings, display the button
    if(this.model.studentId !== null && companies.length > 0) {
      this.$('.student-feedback--submit').show();
    } else {
      this.$('.student-feedback--submit').hide();
    }

    // Enable chained calls
    return this;
  },

  events: {
    'change .student-feedback--name': 'onNameSelect',
    'click .student-feedback--submit': 'onSubmitRankings',
  },

  onNameSelect: function() {
    const $nameSelect = this.$('.student-feedback--name');
    const studentId = $nameSelect.val();

    if(studentId === '') {
      this._resetModel();
      this.render();
    } else {
      this._loadCompanies(studentId);
    }
  },

  onRankChange: function(company, change) {
    const companies = this.model.companies;
    const oldIndex = company.rank - 1;

    // Figure out the new index
    const maxIndex = companies.length - 1;
    const newIndex = Math.max(0, Math.min(oldIndex + change, maxIndex));

    if(oldIndex === newIndex) return;

    // Swap
    const tmp = companies[oldIndex];
    companies[oldIndex] = companies[newIndex];
    companies[newIndex] = tmp;

    this.render();
  },

  onSubmitRankings: function() {
    // Get the rankings for each company
    const rankings = _.map(this.model.companies.reverse(), (company, index) => {
      return { company_id: company.id, rank: index + 1 };
    });

    const endpoint = this._studentEndpoint(this.model.studentId) + '/rankings';
    $.post({
      url: endpoint,
      data: JSON.stringify({rankings: rankings}),
      success: (response) => {
        this.$el.html('<h1>Thank you for submitting your feedback.</h1>');
      },
      error: (response) => {
        this.$('.student-feedback--submit')
          .parent()
          .append($('<p>Error: '+response.responseJSON.error+'</p>').css('color', 'red'));
      },
      contentType: 'application/json',
      dataType: 'json',
    });
  },

  _loadCompanies: function(studentId) {
    // Call to API to get companies list
    const endpoint = this._studentEndpoint(studentId) + '/companies';
    $.getJSON(endpoint, (companies) => {
      this.model = {
        studentId: studentId,
        companies: companies,
      };

      this.render();
    });
  },

  _studentEndpoint: function(id) {
    return window.location.origin + '/students/' + id;
  },

  _resetModel: function() {
    this.model = {
      studentId: null,
      companies: [],
    };
  },
});

const StudentFeedbackCompanyView = Backbone.View.extend({
  tagName: 'li',

  initialize: function(options) {
    this.template = _.template($('#student-feedback--company-template').html());

    this.onRankChange = options.onRankChange;
  },

  render: function() {
    this.$el.html(this.template(this.model));
    return this;
  },

  events: {
    'click .student-feedback--rank-btn-up': 'onClickUp',
    'click .student-feedback--rank-btn-down': 'onClickDown',
  },

  onClickUp: function() { this._changeRank(-1); },

  onClickDown: function() { this._changeRank(+1); },

  _changeRank: function(change) {
    this.onRankChange(this.model, change);
  },
});
