class TableOfContentsPresenter::Agency
  attr_reader :attributes, :presenter

  def initialize(attributes, presenter)
    @attributes = attributes
    @presenter = presenter
  end

  def name
    attributes['name']
  end

  def slug
    attributes['slug']
  end

  def to_param
    slug
  end

  def child_agencies
    if attributes['see_also']
      @child_agencies ||= attributes['see_also'].map do |child_agency|
        presenter.agencies[child_agency['slug']]
      end
    else
      []
    end
  end

  def document_categories
    attributes["document_categories"]
  end

  def document_categories=(filtered_document_categories)
    attributes["document_categories"] = filtered_document_categories
  end

  def see_also
    attributes["see_also"]
  end

  def see_also=(filtered_see_alsos)
    attributes["see_also"] = filtered_see_alsos
  end

  def document_count_with_child_agencies
    return @document_count_with_child_agencies if @document_count_with_child_agencies

    @document_count_with_child_agencies = child_agencies.inject(document_count) do |sum, child_agency|
      sum += child_agency.document_count
      sum
    end
  end

  def document_count
    return @document_count if @document_count

    @document_count = attributes["document_categories"].inject(0) do |sum, doc_cat|
      doc_cat["documents"].each do |doc|
        sum += doc["document_numbers"].size
      end
      sum
    end
  end

  def load_documents(doc_numbers)
    doc_numbers.map do |doc_num|
      doc = documents[doc_num]

      unless doc
        Honeybadger.notify(
          error_class: "Missing document number for table of contents",
          error_message: "Document number #{doc_num} not found for #{name}"
        )
      end

      doc
    end.compact
  end

  private

  def document_numbers
    return @document_numbers if @document_numbers
    doc_numbers = []
    attributes["document_categories"].each do |doc_cat|
      doc_cat["documents"].each do |doc|
        doc_numbers << doc["document_numbers"]
      end
    end
    @document_numbers = doc_numbers.flatten
  end

  def documents
    @documents ||= document_numbers.inject({}) do |hsh, doc_num|
      hsh[doc_num] = presenter.documents.find{|doc| doc.document_number == doc_num}
      hsh
    end
  end
end
