recomb_into_flatlist <- function(
  branched_list_obj,
  obj_listname,
  id_listname = "id"
) {
  .actual_objs <- map(branched_list_obj, \(list_obj) list_obj[[obj_listname]])
  .actual_ids <- map(branched_list_obj, \(list_obj) list_obj[[id_listname]])

  .named_objs <- set_names(.actual_objs, .actual_ids)
  .named_objs
}
