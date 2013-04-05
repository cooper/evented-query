use warnings;
use strict;
use feature 'say';
use lib '../evented-object';
use Evented::Query;


test('Select all columns of all rows', sub {
    shift->select->from('someTable');
});

test('Select two specific columns of all rows', sub {
    shift->select('col1', 'col2')->from('someTable');
});

test('Select all columns with row limit', sub {
    shift->select->from('someTable')->limit(5);
});

test('Select all columns ordered descending', sub {
    shift->select->from('someTable')->order_by('identifier', 'desc');
});

test('Select all columns ordered ascending with limit', sub {
    shift->select->from('someTable')->limit(1)->order_by('identifier');
});

test('Select with a function and a column', sub {
    shift->select('COUNT(*)', 'col')->from('someTable');
});

test('Select two columns with alternate names', sub {
    shift->select(['col1', 'other1'])->from('someTable')
        ->select_as('col2', 'other2')->from('someTable');
});

test('Select with simple equality clause', sub {
    shift->select->from('someTable')->where(
        ['col', 'is equal to', 'hithere']
    );
});

test('Select with equal clause and inequality clause', sub {
    shift->select->from('someTable')->where(
        ['col', 'is equal to',  'some value'],
        ['col', 'is less than', 56]
    );
});

test('Select with clauses, function, alt. names, limit, order, group', sub {
    shift->select('col1', 'col2', ['col3', 'id'], ['SUM(`col`)', 'sum'])
    ->from('someTable')->where(
        ['col', 'is equal to',  'some value'],
        ['col', 'is less than', 56]
    )->order_by('col1')->group_by('col2')->limit(100);
});

sub test {
    my ($desc, $code) = @_;
    my $query = Evented::Query->new();
    say "Testing: $desc...";
    say '';
    $code->($query);
    say "    ".$query->sql_data;
    say "    arguments (".join(', ', $query->sql_arguments).")" if $query->sql_arguments;
    say '';
}

say "All tests passed.";
