# Copyright (c) 2013, Mitchell Cooper
package Evented::Query;

use warnings;
use strict;
use feature 'switch';

use EventedObject;
use parent 'EventedObject';

# creates a new query object.
sub new {
    my ($class, %opts) = @_;
    my $query = $class->SUPER::new(%opts);
    $query->{arguments} = [];
    return $query;
}

###########
### SQL ###
###########

# returns a list of SQL query arguments.
sub sql_arguments {
    my $query = shift;
    return @{$query->{arguments}};
}

# compiles to SQL and stores it.
sub sql_compile {
    my ($query, $sql) = shift;
    
    # call generator.
    if ($query->{generator}) {
        $sql = $query->{generator}->($query);
    }
    
    # return the SQL query.
    $query->{compiled} = 1;
    $query->{sql_data} = $sql;
    
    return $query;
}

# returns compiled SQL string.
sub sql_data {
    my $query = shift;
    
    $query->sql_compile if !$query->{compiled};
    
    return $query->{sql_data};
}

##############################
### SELECT QUERY INTERFACE ###
##############################


# set query select columns.
# you can call this several times to add more columns.
sub select {
    my ($query, @select) = @_;
    
    # if there are no values, assume all.
    @select = '*' if scalar @select == 0;
    
    # set the select columns.
    $query->{select_columns} ||= [];
    push @{$query->{select_columns}}, @select;
    
    # it's a select query.
    $query->{generator} = \&_select_sql;
    
    return $query;
}

# set a query select column and select it using a different column name.
sub select_as {
    my ($query, $select, $as) = @_;
    
    # SELECT..AS is stored as an array reference.
    $query->select([$select, $as]);
    
}

# set select target table.
sub from {
    my ($query, $table) = @_;
    $query->{target_table} = $table;
    return $query;
}


# set select order by column and ordering format.
sub order_by {
    my ($query, $column, $format) = @_;
    
    # default to ascending.
    $format ||= 'ASC';
    
    $query->{order_by_column} = $column;
    $query->{order_by_format} = $format;
    
    return $query;
}

# set select grouping column.
sub group_by {
}

# set select row return limit.
sub limit {
    my $query = shift;
    $query->{select_row_limit} = shift;
    return $query;
}

# convert select columns to the proper format.
sub _select_fmt {
    my ($query, @final) = shift;
    
    # backtick each column name.
    foreach my $column (@{$query->{select_columns}}) {
        my ($col, $as);
        
        # array reference indicates SELECT..AS.
        if (ref $column && ref $column eq 'ARRAY') {

            $col = $column->[0];
            $as  = $column->[1];
        }
    
        # backtick things that need them.
        if ($column !~ m/\(/ && $column ne '*') {
            $col = _bt($column);
        }
        
        # add backticks.
        push @final, $col             unless defined $as;
        push @final, $col.' AS '._bt($as) if defined $as;
        
    }

    # return as a comma-separated string.
    return join ', ', @final;
    
}

# creates a select query.
sub _select_sql {
    my $query = shift;
    
    # generate select columns.
    my $items = $query->_select_fmt();
    
    # fetch the table and backtick it.
    my $table = _bt($query->{target_table});

    # conditionals, ordering, and return limit.
    my $where = _space($query->_where_sql);
    my $order = _space($query->_order_by_sql);
    my $limit = _space($query->_limit_sql);

    # create query.
    my $sql = "SELECT $items FROM $table$where$order$limit";
    
    # return complete query.
    return $sql;
    
}

sub _order_by_sql {
    my $query = shift;
    return if !defined $query->{order_by_column};
    
    # replace anything with the actual SQL keywords.
    # this allows you to pass things such as 'ascending'
    if (lc $query->{order_by_format} =~ m/^a/) {
        $query->{order_by_format} = 'ASC';
    }
    if (lc $query->{order_by_format} =~ m/^d/) {
        $query->{order_by_format} = 'DESC';
    }
    
    return 'ORDER BY '._bt($query->{order_by_column}).' '.$query->{order_by_format};
}

sub _group_by_sql {

}

sub _limit_sql {
    my $query = shift;
    return if !defined $query->{select_row_limit};
    return 'LIMIT '.$query->{select_row_limit};
}

###################################
### GENERAL SQL QUERY INTERFACE ###
###################################

sub where {
    my $query = shift;
    
    # add these conditionals.
    $query->{conditionals} ||= [];
    push @{$query->{conditionals}}, @_;
    
    return $query;
}

# compiles and executes SQL query.
sub execute {
    my $query = shift;
    
    # we haven't compiled yet.
    if (!$query->{compiled}) {
        $query->sql_compile();
    }
    
    # execute the code.
    #if ($query->{db}) return $query->{db}->blah
    
}

# returns the number of rows fetched by select.
sub select_num_rows {

}

sub _where_sql {
    my $query = shift;
    return if !$query->{conditionals};
    
    # create SQL for each conditional.
    my ($i, $sql) = (0, '');
    foreach my $item (@{$query->{conditionals}}) {

        my $string;

        # array ref in the format of [column, compare operator, value]
        if (ref $item && ref $item eq 'ARRAY') {
        
            # create SQL for this item.
            my ($column, $op, $value) = @$item;
            $op     = _where_op($op);
            $string = _bt($column)." $op ?";
            
            # add the argument.
            push @{$query->{arguments}}, $value;
        
        }

        # normal strings are injected as-is.
        else {
            $string = $item;
        }

        $sql .= $i == 0 ? 'WHERE ' : ' AND ';
        $sql .= $string;
        
        $i++;
    }
    
    return $sql;
}

sub _where_op {
    my $op = shift;
    given (lc $op) {
        when (/less|lt/)    { return '<' }
        when (/greater|gt/) { return '>' }
        when (/equal|eq/)   { return '=' }
    }
    return $op;
}

##############
### EVENTS ###
##############

sub on_select_hash {
}

sub on_select_array {
}

#############
### OTHER ###
#############

# add/escape backticks.
sub _bt {
    my $string = shift;
    $string =~ s/\`/\\\`/g;
    return "`$string`";
}

# add prefixing space if needed.
sub _space {
    my $string = shift;
    return '' if !defined $string || !length $string;
    return " $string";
}

1
