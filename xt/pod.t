use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

# we need to specify lib/ and script/ manually so it won't find the
# bundled documentation in blib/
all_pod_files_ok(all_pod_files(qw(lib script)));
