const PlacementSummaryCollection = Backbone.Collection.extend({
  model: PlacementSummary,
  url: window.location.origin + '/placements/'
});
