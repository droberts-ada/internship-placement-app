const CompanyCollection = Backbone.Collection.extend({
  model: Company,
  comparator: 'name'
});
