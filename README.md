# ydalir
A collection of bash scripts that perform various tasks on Linux based systems

## veiði
this script removes a set of fields from a .csv file. Currently, the amount of
fields within the source file is not bounded. In order to use it, invoke it as:

> veidi.bash \<source-file\> \<number-of-fields\> \<field-set\> \<separator\> \<target-dir\>

- \<source-file\>      =\> it can a base name, a relative path or an absolute path;
- \<number-of-fields\> =\> indicates the amount of fields contained within a row;
- \<field-set\>        =\> indicates the set of fields that are to be removed. The field index
                           starts from one. Indexes are separated by a single semi-colon. For
                           example, a valid field set is 2;5;8
- \<separator\>        =\> separator between any two fields of the input file. It will be used in the
                           output file, too. Valid separators belong to the set {',', ';'}
- \<target-dir\>       =\> the directory that will contain the output file

**remember to enclose both the field set and the separator within either single or double quotes**

the name of the output file is derived from the input file name. In particular, _new.csv is
appended to the base name (devoid of its extension) of the latter. If the base name contains
multiple dots, only the token preceding the first one will appear in the output file name.

the script needs the execute privilege:

> chmod +x veidi.bash

valid only for the current user
> chmod u+x veidi.bash

