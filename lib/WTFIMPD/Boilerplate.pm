#
# Copyright (C) 2015-2025 Joelle Maslak
# All Rights Reserved - See License
#

package WTFIMPD::Boilerplate;
# ABSTRACT: Default Boilerplate for Joelle Maslak's Code

use strict;
use warnings;

=head1 SYNOPSIS

  use WTFIMPD::Boilerplate 'script';

=head1 DESCRIPTION

This module is adapted from C<JTM::Boilerplate>.

This module serves two purposes.  First, it sets some default imports,
and turns on the strictures I've come to rely upon.  Secondly, it depends
on a number of other modules to aid in setting up new environments (I can
just do a "cpan JTM-Boilerplate" to install everything I need).

This module optionally takes one of two parameters, 'script', 'class',
or 'role'. If 'script' is specified, the module assumes that you do not
need Moose or MooseX modules.

=head1 WARNINGS

This module makes significant changes in the calling package!

=cut

use v5.22;
use strict;

use feature 'signatures';
no warnings 'experimental::signatures';

no warnings 'experimental::re_strict';
use re 'strict';

use English;
use Import::Into;
use Smart::Comments;
use re;

sub import ( $self, $type = 'script' ) {
    ### assert: ($type =~ m/^(?:class|role|script)$/ms)

    my $target = caller;

    strict->import::into($target);
    warnings->import::into($target);
    autodie->import::into($target);

    my ($ver) = "$PERL_VERSION" =~ m/^v(\d+\.\d+)\..*$/;
    feature->import::into( $target, ":$ver" );

    utf8->import::into($target);    # Allow UTF-8 Source

    if ( $type eq 'class' ) {
        Moose->import::into($target);
        Moose::Util::TypeConstraints->import::into($target);
        MooseX::StrictConstructor->import::into($target);
        namespace::autoclean->import::into($target);
    } elsif ( $type eq 'role' ) {
        Moose::Role->import::into($target);
        Moose::Util::TypeConstraints->import::into($target);
        MooseX::StrictConstructor->import::into($target);
        namespace::autoclean->import::into($target);
    } else {
        Feature::Compat::Class->import::into($target);
    }

    Carp->import::into($target);
    English->import::into($target);
    Smart::Comments->import::into( $target, '-ENV', '###' );

    feature->import::into( $target, 'postderef' );    # Not needed if feature bundle >= 5.23.1

    Feature::Compat::Defer->import::into($target);
    Feature::Compat::Try->import::into($target);

    # We haven't been using this
    # feature->import::into($target, 'refaliasing');
    feature->import::into( $target, 'signatures' );

    feature->import::into( $target, 'unicode_strings' );
    # warnings->unimport::out_of($target, 'experimental::refaliasing');
    warnings->unimport::out_of( $target, 'experimental::signatures' );

    if ( $PERL_VERSION lt v5.24.0 ) {
        warnings->unimport::out_of( $target, 'experimental::postderef' );
    }

    # For "re 'strict'" feature
    warnings->unimport::out_of( $target, 'experimental::re_strict' );
    re->import('strict');

    if ( $PERL_VERSION ge v5.32.0 ) {
        # Turn off indirect syntax
        feature->unimport::out_of( $target, 'indirect' );

        # Turn on isa
        feature->import::into( $target, 'isa' );
        warnings->unimport::out_of( $target, 'experimental::isa' );
    }

    if ( $PERL_VERSION ge v5.34.0 ) {
        # Turn off multidimensional "array" emulation
        feature->unimport::out_of( $target, 'multidimensional' );

        # Turn off bareword filehandles
        feature->unimport::out_of( $target, 'bareword_filehandles' );
    }

    return;
}

1;
