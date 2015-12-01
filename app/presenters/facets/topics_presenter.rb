class Facets::TopicsPresenter
  ROUTINE_TOPICS = [
    "administrative-practice-tprocedure",
    "aircraft",
    "reporting-recordkeeping-requirements",
    "safety",
  ]

  def topics_for_exploration
    @topics ||= document_counts.
      reject{|facet| ROUTINE_TOPICS.include?(facet.slug)}.
      slice(0..9).
      map{|facet|
        TopicFacet.new(
          name: facet.name,
          slug: facet.slug,
          document_count: facet.count,
          document_count_search_conditions: facet.search_conditions,
          comment_count: comment_counts.detect{|x| x.slug == facet.slug}.try(:count) || 0,
          comment_count_search_conditions: comment_counts.detect{|x| x.slug == facet.slug}.try(:search_conditions)
        )
      }.
      map{|topic| TopicDecorator.decorate(topic)}.
      sort_by(&:name)
  end

  class TopicFacet
    vattr_initialize [
      :comment_count,
      :comment_count_search_conditions,
      :document_count,
      :document_count_search_conditions,
      :name,
      :slug,
    ]
  end

  private

  def comment_counts
    @comment_counts ||= Topic.search(
      QueryConditions::DocumentConditions.comment_period_closing_in(1.week)
    )
  end

  def document_counts
    @document_counts ||= Topic.search(
      QueryConditions::DocumentConditions.published_in_last(1.week)
    )
  end
end