require 'terminal-table'

module Hodor
  class Table

    def initialize(object, verbose = false, matching = nil)
      @verbose = verbose
      if object.respond_to?(:session)
        @verbose ||= object.session.verbose
      end
      @matching = matching
      # Display properties first
      properties = object.display_properties
      title = object.respond_to?(:title) ? object.title : "#{object.class.name} Properties"
      if title.is_a? Array
        @title = title[0]
        @sub_title = title[1]
      else
        @title = title
      end
      if properties
        rows = properties[:rows]
        if rows.length < 5
          @prop_table = Terminal::Table.new(properties)
          @prop_table.align_column 0, :right
        else

          if @verbose
            terse_rows = rows.select { |row| row[1].length <= 50 }
          else
            terse_rows = rows.select { |row| !row[1].nil? && row[1].length > 0 && row[1].length <= 50 }
          end
          verbose_rows = rows.select { |row| row[1].length > 50 }.map { |row| normalize(row) }
          sorted_rows = terse_rows.sort_by { |row| -row[1].length }

          numrows = (sorted_rows.length / 3).to_i
          arranged = []
          slen = terse_rows.length
          (0..numrows-1).each { |rownum|
            mcol = []
            mcol += normalize(sorted_rows[(rownum%numrows)]) if slen > (rownum%numrows)
            mcol += normalize(sorted_rows[(rownum%numrows)+numrows]) if slen > (rownum%numrows)+numrows
            mcol += normalize(sorted_rows[(rownum%numrows)+2*numrows]) if slen > (rownum%numrows)+2*numrows
            arranged << mcol
          }
          short_compound = []

          if @verbose
            @long_table = Terminal::Table.new( { rows:verbose_rows} )
            @long_table.align_column 0, :right
            @long_table.style = {border_y: ' ', border_x: " ", border_i: ' ' }
          end

          @prop_table = Terminal::Table.new( {rows: arranged} )
          @prop_table.align_column 0, :right
          @prop_table.align_column 2, :right
          @prop_table.align_column 4, :right
          @prop_table.style = {border_y: ' ', border_x: " ", border_i: ' ' }
        end
      end

      # Next display the table of children
      rowcol = object.display_children
      if rowcol && rowcol[:rows] && rowcol[:rows].length > 0
        @child_table = Terminal::Table.new(rowcol)
        @child_table.align_column 0, :center
      else
        @child_table = Terminal::Table.new(rows: [[@prop_table ? "<< No Children >>" : "<< Empty Set >>"]])
        @child_table.align_column 0, :center
      end
    end

    def normalize(row)
      [row[0].to_s.split('_').map { |word| word.capitalize }.join(' ') + ":", row[1].to_s.length > 0 ? row[1] : '<nil>']
    end

    def shift table, count=3
      shifted = ""
      table.each_line { |line|
        shifted << " "*count + line
      }
      shifted
    end

    def properties
      output = @prop_table ? @prop_table.to_s : ''
      output = shift(output,1)
      stripped_output = ""
      first_line = true
      output.each_line { |line|
        stripped_output << line unless first_line
        first_line = false
      }
      stripped_output.rstrip
    end

    def long_properties
      output = @long_table ? @long_table.to_s : ''
      shift(output, 4)
    end

    def children
      output = @child_table ? @child_table.to_s : ''
      shift(output, 4)
    end

    def to_s
      prop_width = (properties.split("\n").first||"").length
      children_width = (children.split("\n").first||"").length
      title_width = @title.length
      if prop_width > 0
        ruler = [((prop_width - title_width) / 2).to_i - 5, 0].max
        output = "     #{'-'*ruler}  #{@title}  #{'-'*ruler}\n"
      elsif children_width > 0
        ruler = [((children_width - title_width) / 2).to_i - 5, 0].max
        output = "     #{' '*ruler} #{@title} #{' '*ruler}\n"
        output[(prop_width - @sub_title.length+2..-1)] = @sub_title + "\n" if @sub_title
      end
      output += properties + "\n" if @prop_table
      output += long_properties + "\n" if @long_table
      if @matching
        child_lines = children.split("\n")
        total_lines = child_lines.length
        child_lines.each_with_index { |line, index|
          matched = index < 3 || index == total_lines-1
          @matching.each { |item|
            matched ||= line.include?(item)
          } unless matched
          output += "#{line}\n" if matched
        }
      else
        output += children
      end
      output
    end
  end
end
