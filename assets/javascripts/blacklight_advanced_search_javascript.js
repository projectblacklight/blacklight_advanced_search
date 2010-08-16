$(document).ready(function() {
  $('.limit_column ul').each(function(){
    var ul = $(this);
    // find all ul's that don't have any span descendants with a class of "selected"
    if($('span.selected', ul).length == 0){
      // hide it
      ul.hide();
      // attach the toggle behavior to the h3 tag
      $('h3', ul.parent()).click(function(){
         // toggle the next ul sibling
         $(this).next('ul').slideToggle();
      });
     }
  });
  
  
  /* Stuff for handling the checkboxes */
  /* When you click a checkbox, update readout */
  $("#advanced_search_facets input").each(function(){
    if ($(this).attr('type') == 'checkbox' & $(this).is(':checked')) {
    var selected_facets_element = $(this).parent().parent().parent().children('h3').children('span');
    if (selected_facets_element.children('span').text() == "") {
      selected_facets_element.children('span').text($(this).next('label').text());
    }else{
      selected_facets_element.children('span').text(selected_facets_element.children('span').text() + " OR " + $(this).next('label').text());
    }
    if (selected_facets_element.attr("style") == "display: none;"){
      selected_facets_element.attr("style","")
    }
    }
  });
  
  
  /* On page load, make readout match initial load. */
    $("#advanced_search_facets input").each(function(){
      if($(this).attr('type') == 'checkbox'){
      $(this).click(function(){
      var selected_facets_element = $(this).parent().parent().parent().children('h3').children('span');
        var current_text = selected_facets_element.children('span').text();
      var new_text = $(this).next('label').text();
        if($(this).is(':checked')){
        if(current_text == ''){
          swap_text = new_text;
        }else{
          swap_text = current_text + " OR " + new_text;
        }
      }else{
        if(current_text.replace("(","_").replace(")","_").search(new_text.replace("(","_").replace(")","_") + " OR ") > -1  ){
          swap_text = current_text.replace(new_text + " OR ", '');
        }else if(current_text.replace("(","_").replace(")","_").search(" OR " + new_text.replace("(","_").replace(")","_")) > -1  ){
          swap_text = current_text.replace(" OR " + new_text, '');
        }else{
          swap_text = current_text.replace(new_text, '');
        }
      }
      selected_facets_element.children('span').text(swap_text);
      if(selected_facets_element.children('span').text() == " OR "){
        selected_facets_element.children('span').text() == "";
      }else if(selected_facets_element.children('span').text().substr(-4) == " OR "){
        selected_facets_element.children('span').text(selected_facets_element.children('span').text().substr(0,selected_facets_element.children('span').text().length-4))
      }
      if(selected_facets_element.children('span').text() == ""){
        selected_facets_element.attr("style", "display:none;");
      }else{
        selected_facets_element.attr("style", "display:inline;");
      }
      });
    }
   
  });

  
});
