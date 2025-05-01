make clean
rm -r *.ucdb
make cli
make convert_testplan
make merge_coverage
make view_coverage
