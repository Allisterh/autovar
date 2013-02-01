Autovar
=======

Autovar is an R package for automating and simplifying the process from raw SPSS or STATA data to VAR models.


Selecting data
--------------

Currently, one data set can be operated on at at time. The data set, along with any metadata associated with it, is stored in the global variable `av_state`. This variable supports the print command (`print(av_state)`).


### load_file

    load_file(filename,file_type = c('SPSS','STATA'))
    
**In the web application, this function does not need to be called explicitly. It is always prepended to the code.**

This function prints the columns of the loaded data set. The abbreviation `(scl)` is used to denote scale (numeric) columns, and `(nom)` is used to denote nominal (factor) columns.

#### Arguments

The `file_type` argument is optional. When not specified, it is determined from the `filename`, i.e., `.dta` extensions are treated as STATA files and `.sav` extensions are treated as SPSS files.

#### Results

This function creates the following variables in the `av_state` list:

* `file_name` - The full file name including path. The working directory is prepended if a partial path is supplied.
* `file_type` - The type of the file. Can be `SPSS` or `STATA`. Used for determining how to read the file.
* `raw_data` - The raw file data as it is read, before any added columns, imputations, sorting, or splitting.
* `data` - The current data set. Initially, `data` is a list containing a single item, such that `raw_data` is identical to `data[['multiple']]`.

#### Syntax

Example: `load_file("../data/input/RuwedataAngela.sav")`


### group_by

    group_by(id_field)

The `group_by` function splits up the initial data set into multiple sets based on their value for `id_field`.

For example, if we have a data set with a field named `id`  that has values ranging from 11 to 15, calling `group_by('id')` will set `av_state$data` to a list of five items. This list is ordered by the value of the id field. Then, we can use `av_state$data[[1]]` (or equivalently, `av_state$data[['11']]`) to retrieve the rows in the data set that have `id` 11. Likewise, use `av_state$data[[2]]` or `av_state$data[['12']]` for rows with `id` 12.

#### Results

Other than adjusting `av_state$data`, the `group_by` function creates the following variables in the `av_state` list:

* `group_by` - the `id_field` used for grouping the data.


### order_by

    order_by(id_field,impute_method=c('BEST_FIT','ONE_MISSING','ADD_MISSING','NONE'))

The `order_by` function determines the order of the data rows as they appear in ther output of the `store_file` function. The supplied `id_field` parameter is often a measurement index (e.g., `'tijdstip'`). The `id_field` column has to be numeric.

#### Arguments

The `impute_method` argument has three possible values:

* `BEST_FIT` - This is not an impute method itself, but tells the system to determine the optimal impute method and use that. This is the default choice for `impute_method` when it is not specified.
* `ONE_MISSING` - Only works when the `id_field` in each data_subset is an integer range with exactly one value missing and exactly one `NA` value. The `NA` value is then substituted by the missing index.
* `ADD_MISSING` - Does not work when one or more rows have an NA value for `id_field`. Only works for integer ranges of `id_field` with single increments. Works by adding rows for all missing values in the range between the minimum and maximum value of `id_field`. All values in the added rows are `NA` except for the `id_field` and the field used for grouping the data (if there was one).
* `NONE` - No imputation is performed.

#### Results

After the substitutions, the data sets in `av_state$data` are sorted by their `id_field` value. This sorting step moves any rows with value `NA` for the `id_field` to the end.

Other than adjusting `av_state$data`, the `order_by` function creates the following variables in the `av_state` list:

* `impute_method` - the `impute_method` used.
* `order_by` - the `id_field` used.

#### Syntax

Example: `order_by('tijdstip',impute_method='ONE_MISSING')`


### select_range

    select_range(subset_id='multiple',column,begin,end)

The `select_range` function selects which rows of a data set should be included. If the data set is grouped into multiple data sets, the `subset_id` argument needs to be supplied, allowing the function to work individually per data set.

#### Arguments

The `column` argument specifies which column the begin and end values should be taken over. This argument is optional, and if it is missing, the value of `av_state$order_by` will be substituted.

Either the `begin` or the `end` argument need to be specified. The column does not need to be sorted for this function to work. Values are included if they are `>= begin` and `<= end`, if specified. This does not remove `NA` values.

#### Syntax

Example: `select_range('1',begin=20,end=40)`


Modifying and adding columns
----------------------------


### set_first_timestamp


### impute_missing_values


### add_derived_column

    add_derived_column(name,columns,operation=c('SUM','LN','MINUTES_TO_HOURS'))

The `add_derived_column` function adds a new column, based on existing columns, to all identified groups in the current data set. The `name` argument holds the name of the new column.

#### Arguments

The `operation` argument has three possible values:

* `SUM` - The new column is the sum of the columns specified in the `columns` argument. So for this option, the `columns` argument is an array of column names. Values in the summation of columns that are `NA` are treated as if they're zero. Columns that are not numeric are transformed to numeric. For example, `Factor` columns are transformed to numbers starting at 0 for the first factor level.
* `LN` - The new column is the natural logarithm of the specified column in `columns`. Thus, for this option, the `columns` argument is simply the name of a single column. This operation does not work on columns that are not numeric. Values in the original column that are `NA` are left as `NA` in the new column. Note that values are increased if necessary so that the resulting column has no negative values.
* `MINUTES_TO_HOURS` - The new column is the values of the specified column divided by 60. Thus, for this option, the `columns` argument is simply the name of a single column. This operation does nto work on columns that are not numeric. Values in the original column that are `NA` are left as `NA` in the new column.

#### Syntax

Example: `add_derived_column('SomPHQ',c('PHQ1','PHQ2','PHQ3','PHQ4','PHQ5','PHQ6','PHQ7','PHQ8','PHQ9'),operation='SUM')`, `add_derived_column('lnSomBewegUur','SomBewegUur',operation='LN')`, or  `add_derived_column('SomBewegUur','SomBewegen',operation='MINUTES_TO_HOURS')`.


Vector Autoregression
---------------------


### var_main

    var_main(vars,lag_max=14,significance=0.05,exogenous_max_iterations=3,subset=1,log_level=av_state$log_level)

The `var_main` function generates and tests possible VAR models for the specified variables. The only required argument is `vars`, which should be a vector of variables.

#### Arguments

The `lag_max` argument limits the highest possible number of lags that will be used in a model. This number sets the maximum limit in the search for optimal lags.

The `significance` argument is the maximum P-value for which results are seen as significant. This argument is used in Granger causality tests, Portmanteau tests, and Jarque-Bera tests.

The `exogenous_max_iterations` argument determines how many times we should try to exclude additional outliers for a variable. The `exogenous_max_iterations` argument should be a number between 1 and 3:

* `1` - When Jarque-Bera tests fail, having `exogenous_max_iterations = 1` will only try with removing 3x std. outliers for variables using exogenous variables.
* `2` - When `exogenous_max_iterations = 2`, the program will also try removing 2.5x std. outliers if JB tests still fail.
* `3` - When `exogenous_max_iterations = 3`, the program will also try removing 2x std. outliers if JB tests still fail.

The `subset` argument specifies which data subset the VAR analysis should run on. The VAR analysis only runs on one data subset at a time. If not specified, the first subset is used (corresponding to `av_state$data[[1]]`).

The `log_level` argument sets the minimum level of output that should be shown. It should be a number between 0 and 3. `0` = debug, `1` = test detail, `2` = test outcomes, `3` = normal. The default is set to the value of `av_state$log_level` or if that doesn't exist, to `0`. If the `log_level` parameter was specified, the original value of `av_state$log_level` will be restored at the end of `var_main`.

#### Results

The `var_main` function sets the following variables in the `av_state` list:

* `significance` - the `significance` used.
* `lag_max` - the `lag_max` used.
* `exogenous_max_iterations` - the `exogenous_max_iterations` used.
* `vars` - the `vars` used.
* `subset` - the `subset` used.
* `log_level` - the `log_level` used. This setting is restored at the end of `var_main` to its original value.
* `model_queue` - the list of models specified by only parameters, used as the main queue in `var_main`. This is a a list of objects with class `var_model`.
* `accepted_models` - the sorted list of accepted models and their var results. This is a a list of objects with class `var_modelres`. Each accepted model has properties `parameters` to retrieve the model parameters, and `varest` to retrieve the var result.
* `rejected_models` - the list of rejected models and their var results (excluding those from `model_queue` that did not have a specified lag). This is a a list of objects with class `var_modelres`. Each accepted model has properties `parameters` to retrieve the model parameters, and `varest` to retrieve the var result.

#### Syntax

Example: `var_main(c('Activity_hours','Depression'),log_level=2)`


### var_info

    var_info(varest)

The `var_info` function prints the output of the tests for a var model. Note that its output can be altered by the value of `av_state$log_level`. The tests it shows are the Eingevalue stability condition, the Portmanteau tests, the Jarque-Bera tests, the Granger causality Wald tests, and estat ic.

#### Syntax

Example: `var_info(av_state$accepted_models[[1]]$varest)` or `var_info(av_state$rejected_models[[1]]$varest)`


Outputting data
---------------


### visualize

    visualize(columns,...)

The `visualize` function works with single or multiple columns. When given an array of multiple columns as `columns` argument, all columns have to be of the numeric class. This function creates a combined plot with individual plots for each identified group in the current data set. Any supplied arguments other than the ones described are passed on to the plotting functions.

#### Arguments

When given the name of a single column as `columns` argument, this function behaves differently depending on the class of the column:

* If the class of the column is `factor`, the column is seen as a nominal column, and the following arguments are accepted: `visualize(column,type=c('PIE','BAR','DOT','LINE'),title="",...)`. All plots  also accept the `xlab` argument, e.g., `xlab='minuten'`. Furthermore,  when the type is `BAR`, an additional argument `horiz` can be supplied (`horiz` is `FALSE` by default), which will draw horizontal bar charts rather than vertical ones. To show values over time rather than total values, the `LINE` type can be used. Example: `visualize('PHQ1')`.
* If the class of the column is `numeric`, the column is seen as a scale column, and the following arguments are accepted: `visualize(column,type=c('LINE','BOX'),title="",...)`. Furthermore, when the type is `LINE`, an additional argument `acc` can be supplied (`acc` is `FALSE` by default), which will plot lines of accumulated values rather than the individual values. Example: `visualize('minuten_sport',type='LINE',acc=TRUE)`.

When the `columns` argument is given an array of column names, the sums of the columns are displayed in the plots. For this to work, all columns have to be of the numeric class. When given an array of column names as the `columns` argument, the function accepts the following arguments: `visualize(columns,labels=columns,type=c('PIE','BAR','DOT'),title="",...)`. The arguments of this function work much like the ones described above for individual `factor` columns. The added optional `labels` argument should be an array of strings, with the same length as the `columns` argument, to specify custom names for the columns.

#### Syntax

Examples for using visualize with multiple columns: 

    visualize(c('sum_minuten_licht','sum_minuten_zwaar','minuten_vrijetijd','minuten_sport'), labels=c('licht werk','zwaar werk','vrije tijd','sport'),type='BAR',horiz=TRUE)
    visualize(c('sum_minuten_licht','sum_minuten_zwaar','minuten_vrijetijd','minuten_sport'),type='DOT',xlab='minuten')


### store_file

    store_file(filename,inline_data,file_type = c('SPSS','STATA'))

**In the web application, this function does not need to be called explicitly. It is appended to the code when the Download button is clicked.**

The `store_file` function will export all groups in the active data set to individual output files named after. All output files are subsequently packed in a .tar file that can be downloaded.

#### Arguments

All arguments are optional. When the `filename` argument is missing, the filename of the input file is substituted. The `inline_data` argument determines whether or not the data should be stored inline or in a separate file. If this argument is missing, inline storage is used for data sets with less than 81 columns, and separate storage is used otherwise.

Currently, only the `SPSS` `file_type` is supported. The `.sps` file that comes with the `SPSS` exports may require manual adjusting, as the fully quantified file path to the data set needs to be specified for it to work (relative file paths do not work).

#### Syntax

Example: `store_file()`


### print_state

    print_state()

This command shows the current state of the data set. This is an alias to `print(av_state)`.
