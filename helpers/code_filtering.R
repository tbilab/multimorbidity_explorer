# Helper functions for filtering the codes in response to interaction with various parts of app

# deleting of codes
deleteCodes <- function(codes_to_delete, current_codes){
  # Generate a new list of codes that we want to look at.
  new_included <- current_codes %>%
    filter(!(code %in% codes_to_delete))
  
  if(nrow(new_included) < 2){
    meToolkit::warnAboutSelection()
    return(current_codes)
  }
  
  new_included
}

isolateCodes <- function(codes_to_isolate, current_codes){
  if(length(codes_to_isolate) < 2){
    meToolkit::warnAboutSelection()
    return(current_codes)
  }
  
  current_codes %>%
    filter(code %in% codes_to_isolate)
}


invertCodes <- function(codes_to_invert, currently_inverted_codes){
  # codes that have been inverted and are now being reverted to normal
  already_inverted_codes <- intersect(currently_inverted_codes, codes_to_invert)
  
  # codes that are being freshly inverted
  newly_inverted_codes <- codes_to_invert[!(codes_to_invert %in% already_inverted_codes)]
  
  # codes that are unchanged/ stay inverted
  unchanged_codes <- currently_inverted_codes[!(currently_inverted_codes %in% already_inverted_codes)]
  
  # return the list of codes that should be inverted
  c(newly_inverted_codes, unchanged_codes)
}



codeFilter <- function(type, code_list, current_codes){

  included_codes <- current_codes

  if(type == 'delete'){
    included_codes <- deleteCodes(code_list, current_codes)
  }
  
  if(type == 'isolate'){
    included_codes <- isolateCodes(code_list, current_codes)
  }
  
  included_codes
}


