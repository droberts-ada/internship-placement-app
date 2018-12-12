const StudentFeedbackView = Backbone.View.extend({
  initialize: function() {
    this._resetModel();
  },

  render: function() {
    const companies = this.model.companies;
    const companyViews = _.map(companies, (company, index) => {
      return new StudentFeedbackCompanyView({
        model: _.extend({}, company, {rank: index + 1}),
        onRankChange: this.onRankChange.bind(this),
      });
    });

    const $companies = this.$('.student-feedback--companies');
    $companies.empty();

    companyViews.forEach((companyView) => {
      $companies.append(companyView.render().$el);
    });
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
