use strict;
use warnings;
use utf8;
use Test::More;

plan tests => 23;

use_ok('Thruk::Utils');
use_ok('Thruk::Utils::Status');
use_ok('Monitoring::Livestatus::Class::Lite');

my $query = "name = 'test'";
_test_filter($query, 'Filter: name = test');
is($query, "name = 'test'", "original string unchanged");
_test_filter('name ~~ "test"', 'Filter: name ~~ test');
_test_filter('groups >= "test"', 'Filter: groups >= test');
_test_filter('check_interval != 5', 'Filter: check_interval != 5');
_test_filter('host = "a" AND host = "b"', "Filter: host = a\nFilter: host = b\nAnd: 2");
_test_filter('host = "a" AND host = "b" AND host = "c"', "Filter: host = a\nFilter: host = b\nFilter: host = c\nAnd: 3");
_test_filter('host = "a" OR host = "b"', "Filter: host = a\nFilter: host = b\nOr: 2");
_test_filter('host = "a" OR host = "b" OR host = "c"', "Filter: host = a\nFilter: host = b\nFilter: host = c\nOr: 3");
_test_filter("(name = 'test')", 'Filter: name = test');
_test_filter('(host = "a" OR host = "b") AND host = "c"', "Filter: host = a\nFilter: host = b\nOr: 2\nFilter: host = c\nAnd: 2");
_test_filter("name = 'te\"st'", 'Filter: name = te"st');
_test_filter("name = 'te(st)'", 'Filter: name = te(st)');
_test_filter("host_name = \"test\" or host_name = \"localhost\" and status = 0", "Filter: host_name = test\nFilter: host_name = localhost\nOr: 2\nFilter: status = 0\nAnd: 2");
_test_filter(' name ~~  "test"  ', 'Filter: name ~~ test');
_test_filter('host = "localhost" AND time > 1 AND time < 10', "Filter: host = localhost\nFilter: time > 1\nFilter: time < 10\nAnd: 3");
_test_filter('host = "localhost" AND (time > 1 AND time < 10)', "Filter: host = localhost\nFilter: time > 1\nFilter: time < 10\nAnd: 2");
_test_filter('last_check <= "-7d"', 'Filter: last_check <= '.(time() - 86400*7));
_test_filter('last_check <= "now + 2h"', 'Filter: last_check <= '.(time() + 7200));
_test_filter('last_check <= "lastyear"', 'Filter: last_check <= '.Thruk::Utils::_expand_timestring("lastyear"));

sub _test_filter {
    my($filter, $expect) = @_;
    my $f = Thruk::Utils::Status::parse_lexical_filter($filter);
    my $s = Monitoring::Livestatus::Class::Lite->new('test.sock')->table('hosts')->filter($f)->statement(1);
    $s    = join("\n", @{$s});
    $s      =~ s/(\d{10})/&_round_timestamps($1)/gemxs;
    $expect =~ s/(\d{10})/&_round_timestamps($1)/gemxs;
    is($s, $expect, 'got correct statement');
}

# round timestamp by 5 seconds to avoid test errors on slow machines
sub _round_timestamps {
    my($x) = @_;
    $x = int($x / 5) * 5;
    return($x);
}