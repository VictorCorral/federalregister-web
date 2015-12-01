class HtmlCompilator::Tables::BodyRow
  attr_reader :table, :node
  delegate :h, :to => :table

  def initialize(options)
    @table = options.fetch(:table)
    @node = options.fetch(:node)
  end

  def to_html
    h.content_tag(:tr) {
      cells.each do |cell|
        h.concat cell.to_html
      end
    }
  end

  def cells
    return @cells if @cells

    @cells = []
    start_column_index = 0
    node.xpath('ENT').each_with_index do |node, i|
      cell = HtmlCompilator::Tables::BodyCell.new(
        :row => self,
        :node => node,
        :index => i,
        :start_column_index => start_column_index
      )
      @cells << cell
      start_column_index += cell.colspan
    end
    @cells = append_missing_cells(@cells)
    @cells = @cells.select{|x| x.start_column }
  end

  def all_cells
    @cells
  end

  def expanded_stub_width
    @expanded_stub_width ||= node.attr('EXPSTB').try(:to_i) ||
      prior_row.try(:expanded_stub_width) ||
      0
  end

  CODE_VALUES = {'n' => nil, 's' => :single, 'd' => :double, 'b' => :bold}

  def border_bottom_for_index(i)
    codes = (node.attr('RUL') || '').split(/,/)

    if codes.last =~ /&sqdrt;/
      val = codes.last.sub!(/&sqdrt;/,'')
      codes.fill(val, codes.size, table.num_columns-1)
    end
    CODE_VALUES[codes[i]]
  end

  def prior_row
    if index > 0
      table.body_rows[index-1]
    end
  end

  def index
    @index ||= table.body_rows.index(self)
  end

  def last?
    index+1 == table.body_rows.size
  end

  def append_missing_cells(cells)
    (cells.sum(&:colspan) ... table.num_columns).each do |i|
      cells << HtmlCompilator::Tables::BodyCell.new(
        :row => self,
        :node => HtmlCompilator::Tables::StubNode.new,
        :index => i,
        :start_column_index => cells.last.end_column_index + 1
      )
    end
    cells
  end
end