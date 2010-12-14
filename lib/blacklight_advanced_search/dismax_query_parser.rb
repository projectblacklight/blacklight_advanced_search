module BlacklightAdvancedSearch::DismaxQueryParser
  require 'tree'
  def process_query(params,config)
    text = []
    # NB: mm=1 is required on nested dismax queries, becuase that's how
    # we handle "OR" in the user entry, we just list seperate tokens in
    # a single dismax, and count on mm=1 so they'll be treated mostly like
    # a boolean 'OR'. 
    keyword_queries.each do |field,values| 
      if values.strip[0,3] == "NOT" and values.split.length < 3
        temp_text = 'NOT _query_:"{!dismax mm=1 '
      else
        temp_text = '_query_:"{!dismax mm=1 '
      end
      
      
      temp_text << BlacklightAdvancedSearch.solr_local_params_for_search_field(field)
      
      temp_text << "}#{build_tree(values)}\""
      text << temp_text      
    end
    temp_arr = []
    text.each do |trm|
      if trm.strip[0,3] == "NOT"
        temp_arr << "#{trm}"
      elsif trm == text.last
        temp_arr << "#{trm}"
      else
        temp_arr << "#{trm} #{keyword_op}"
      end
    end

    
    
    return  temp_arr.length > 0 ? temp_arr.join(" ") : nil
  end

  protected
  
  def build_tree(value)
    text = ""
    myTreeRoot = Tree::TreeNode.new("ROOT")
    current_parent = myTreeRoot << Tree::TreeNode.new("Child0")
    # If the query string does not include OR or NOT then we can remove all parenthasis and ANDs, then add a + to the beginning of each word
    if !value.include?("OR") and !value.include?("NOT")
      text << value.gsub(/\(|\)/,"").gsub("AND","").split.collect{|w| (w.strip[0,1] == "+" or  w.strip[0,1] == "-") ? w : "+#{w}"}.join(" ")
    elsif value.include?("(") or value.include?(")")
      temp_text = ""
      i = 1
      value.split(//).each do |d|
        if d == "("
          if temp_text != ""
            current_parent << Tree::TreeNode.new("Child#{i}",temp_text) unless temp_text == ""
            temp_text = ""
          end
          temp_text << d
          current_parent = current_parent << Tree::TreeNode.new("Paren#{i}")
        elsif d == ")"
          temp_text << d
          if temp_text != ""
            current_parent << Tree::TreeNode.new("Child#{i}",temp_text)
            temp_text = ""
          end
          current_parent = current_parent.parent
        else
          temp_text << d
        end
        i += 1
      end
      current_parent << Tree::TreeNode.new("Child#{i}",temp_text) unless temp_text == ""
      text << mod_tree(myTreeRoot).strip
    else
      text << mod_terms(value).strip
    end
    text
  end
  
  def mod_terms(terms)
    text = ""
    arr = terms.split
    i = 0
    if (arr.include?("AND") and arr.include?("OR")) or (arr.include?("AND") and arr.include?("NOT"))
      arr.each do |term|
        if term.strip == "AND" or term.strip == "OR"
          temp = "(" << arr[i-1] << " " << arr[i] << " " << arr[i+1] << ")"
          arr.delete_at(i-1)
          arr.delete_at(i-1)
          arr.delete_at(i-1)
          arr.insert(i-1,temp)
        end
        i += 1
      end
      text << build_tree(arr.join(" "))
    elsif arr.include?("NOT")
      tmp = []
      arr.each do |term|
        txt = ""
        unless term.strip[0,1] == "+" or term.strip[0,1] == "-"
          txt << "+" unless (arr[arr.index(term)-1] == "NOT" or term == "NOT")
        end
        txt << term
        tmp << txt
      end
      text << tmp.join(" ")
      if tmp.first == "NOT" and tmp.length < 3
        text.gsub!("NOT"," ")
      end
      
    else
      text << terms
    end
    text
  end
  
  # Turns transformed tree into a string making sure we traverse the tree as expected
  def each_tree(tree)
    text = ""
    if tree.is_a?(Array)
      tree.each do |t|
        if t.hasChildren?
          text << each_tree(t.children)
        else
          text << t.content.to_s
        end
      end
    elsif tree.hasChildren?
      text << each_tree(tree.children)
    end
    text
  end
  

  def mod_tree(tree)
    if tree.is_a?(Array)
      tree.each do |t|
      if t.hasChildren?
        mod_tree(t.children)
      else
        if t.content
         # has AND (implicit or implied) and does not have OR and NOT
          if (t.content.include?("AND") or t.content.strip == "") and (!t.content.include?("OR") and !t.content.include?("NOT"))
            if t.content.strip == "AND" or t.content.strip == ""
              t.previousSibling.firstChild.content = "+" << t.previousSibling.firstChild.content.strip unless (t.previousSibling.nil? or t.previousSibling.firstChild.content.strip[0,1] == "+" or t.previousSibling.firstChild.content.strip[0,1] == "-" )
              t.nextSibling.firstChild.content = "+" << t.nextSibling.firstChild.content.strip unless (t.nextSibling.nil?  or t.nextSibling.firstChild.content.strip[0,1] == "+" or t.nextSibling.firstChild.content.strip[0,1] == "-" )
              t.content = " "
            elsif t.content.strip[0,3] == "AND"
              t.previousSibling.firstChild.content = "+" << t.previousSibling.firstChild.content unless (t.previousSibling.nil? or t.previousSibling.firstChild.content.strip[0,1] == "+" or t.previousSibling.firstChild.content.strip[0,1] == "-")
              t.content = " " << t.content.gsub("AND","").split.collect{|w| (w.strip[0,1] == "+" or w.strip[0,1] == "-") ? w : "+#{w}"}.join
            elsif t.content.strip[-3,3] == "AND"
              t.nextSibling.firstChild.content = "+" << t.nextSibling.firstChild.content unless (t.nextSibling.nil? or t.nextSibling.firstChild.content.strip[0,1] == "+" or t.nextSibling.firstChild.content.strip[0,1] == "-")
              t.previousSibling.firstChild.content = "+" << t.previousSibling.firstChild.content unless (t.previousSibling.nil? or t.content.strip[0,2] == "OR" or t.previousSibling.firstChild.content.strip[0,1] == "+" or t.previousSibling.firstChild.content.strip[0,1] == "-")
              t.content = " " << t.content.gsub("AND","").split.collect{|w| (w.strip[0,1] == "+" or w.strip[0,1] == "-") ? "#{w} " : "+#{w} "}.join
            elsif t.content[/^\+\(|\(.*\)/]
              temp = t.content.gsub("+(","").gsub("(","").gsub(")","")
              if temp.include?("AND") and !temp.include?("OR")
                # Need to account for +()
                if t.content[/^\+\(/]
                  t.content = "+(" << t.content.gsub(t.content,temp.gsub("AND","").split.collect{|w| (w.strip[0,1] == "+" or w.strip[0,1] == "-") ? w : "+#{w}"}.join(" ")) << ")"
                else
                  t.content = "(" << t.content.gsub(t.content,temp.gsub("AND","").split.collect{|w| (w.strip[0,1] == "+" or w.strip[0,1] == "-") ? w : "+#{w}"}.join(" ")) << ")"
                end
              end
            end
          # has AND and NOT
          elsif t.content.include?("AND") and t.content.include?("NOT")
            temp_terms = t.content.split
            temp = []
            temp_terms.each do |w|
              if temp_terms[temp_terms.index(w)-1] == "NOT" and w != "AND"
                temp << w
              elsif w != "AND" and w != "NOT"
                if w[0,1] == "("
                  temp << "(+#{w.gsub("(","")}"
                else
                  if w.strip[0,1] == "+" or w.strip[0,1] == "-"
                    temp << w
                  else
                    temp << "+#{w}"
                  end
                end
              elsif w != "AND"
                temp << w
              end
            end
            t.content = " " << temp.join(" ") << " " 
            unless t.nextSibling.nil?
              t.nextSibling.firstChild.content = "+" << t.nextSibling.firstChild.content unless (t.content.strip[-3,3] == "NOT" or t.nextSibling.firstChild.content.strip[0,1] == "+" or t.nextSibling.firstChild.content.strip[0,1] == "-")
            end
            unless t.previousSibling.nil?
              t.previousSibling.firstChild.content = "+" << t.previousSibling.firstChild.content unless (t.previousSibling.firstChild.content.strip[0,1] == "+" or t.previousSibling.firstChild.content.strip[0,1] == "-")
            end
          # has NOT does not have AND
          elsif t.content.include?("NOT")
          # does not have AND and does not have OR
          elsif !t.content.include?("OR") and t.content.strip != "" and t.content.strip != "(" and t.content.strip != ")"
            t.content = " " << t.content.split.collect{|w| (w.strip[0,1] == "+" or w.strip[0,1] == "-") ? w : "+#{w}" }.join(" ") << " "
            unless t.nextSibling.nil?
              t.nextSibling.firstChild.content = "+" << t.nextSibling.firstChild.content unless (t.nextSibling.firstChild.content.strip[0,1] == "+" or t.nextSibling.firstChild.content.strip[0,1] == "-")
            end
            unless t.previousSibling.nil?
              t.previousSibling.firstChild.content = "+" << t.previousSibling.firstChild.content unless (t.previousSibling.firstChild.content.strip[0,1] == "+" or t.previousSibling.firstChild.content.strip[0,1] == "-")
            end
          end
        end
      end
    end
    elsif tree.hasChildren?
      mod_tree(tree.children)
    end
    each_tree(tree)
  end
end