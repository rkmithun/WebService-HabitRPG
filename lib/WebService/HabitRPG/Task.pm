package WebService::HabitRPG::Task;
use v5.010;
use strict;
use warnings;
use autodie;
use Moo;
use Scalar::Util qw(looks_like_number);
use POSIX qw(strftime);
use Carp qw(croak);
use Data::Dumper;

use constant HRPG_REPEAT_MAP => qw(
    su m t w th f s
);

# TODO: croak provides poor error messages in here, possibly due to
# it not knowing about Moo properly. Still, they're good enough for
# getting stack backtraces when needed.

# ABSTRACT: A HabitRPG task

# VERSION: Generated by DZP::OurPkg:Version

# Validation functions

my $Bool = sub {
    croak "$_[0] must be 0|1" unless $_[0] =~ /^[01]$/;
};

my $Num = sub {
    croak "$_[0] isn't a number" unless looks_like_number $_[0];
};

my $Type = sub {
    croak "$_[0] is not habit|todo|daily|reward"
        unless $_[0] =~ /^(?:habit|todo|daily|reward)$/;
};

my $NonEmpty = sub {
    croak "Empty or undef parameter" unless length($_[0] // "");
};

has 'text'      => ( is => 'ro', required => 1, isa => $NonEmpty);
has 'id'        => ( is => 'ro', required => 1, isa => $NonEmpty);
has 'up'        => ( is => 'ro', default  => sub { 0 }, isa => $Bool);
has 'down'      => ( is => 'ro', default  => sub { 0 }, isa => $Bool);
has 'value'     => ( is => 'ro', required => 1, isa => $Num);
has 'type'      => ( is => 'ro', required => 1, isa => $Type);
has 'history'   => ( is => 'ro' );  # TODO: Objectify
has 'repeat'    => ( is => 'ro' );  # TODO: Objectify
has 'completed' => ( is => 'ro' );
has '_raw'      => ( is => 'rw' );

sub BUILD {
    my ($self, $args) = @_;

    if ($WebService::HabitRPG::DEBUG) {
        warn "Building task with:\n";
        warn Dumper($args), "\n";
    }

    # Since we're usually being called directly with the results of
    # a JSON parse, we want to record that original structure here.

    $self->_raw($args);
}

sub active_today {
    my ($self) = @_;

    # Non-daily tasks are always active
    
    if ($self->type ne 'daily') {
        return 1;
    }

    my $today_short = (HRPG_REPEAT_MAP)[ int(strftime "%w", localtime) ];
    return $self->repeat->{$today_short};
}

sub format_task {
    my ($task) = @_;

    my $formatted = "";

    if ($task->type =~ /^(?:daily|todo)$/) {
        if ($task->completed) {
            $formatted .= '[X] ';
        }
        elsif (not $task->active_today) {
            $formatted .= '[-] ';
        }
        else {
            $formatted .= '[ ] ';
        }
    }
    elsif ($task->type eq 'habit') {
        $formatted .= ' ';
        $formatted .= $task->{up}   ? "+"  : " "  ;
        $formatted .= $task->{down} ? "- " : "  " ;
    }
    else {
        $formatted .= "  * ";
    }

    $formatted .= $task->text;

    return $formatted;
}

1;
