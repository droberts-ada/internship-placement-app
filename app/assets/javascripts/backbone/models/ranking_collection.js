const RankingCollection = Backbone.Collection.extend({
  model: Ranking,
  modelId: function(attributes) {
    return attributes.company_id;
  },
  comparator: 'company_name'
});
