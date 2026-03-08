build_newdata_flatlist <- function(tsk_feateng_flatlist) {
    .fcst_orig_rows <- map(tsk_feateng_flatlist, \(tsk) {
        tsk$data() %>% tail(1)
    })

    .newdata_rows <- map(.fcst_orig_rows, \(fcst_orig_row) {
        fcst_orig_row %>% select(-n) %>% mutate(date_num = date_num + 7)
    })

    .newdata_rows
}
