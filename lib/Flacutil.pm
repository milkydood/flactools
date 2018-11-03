package AW::Flacutil;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);


$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT_OK = qw(sane_size sane_time plural min max gent get_tag);
%EXPORT_TAGS = ( all => [qw(sane_size sane_time plural min max gent get_tag)] );
my @t = qw(year 31557600 month 2627994 week 604800 day 86400 hour 3600 minute 60);

sub get_tag  {
        my $tref = shift;
        my $tag = shift;
        my @at = grep { /^$tag$/i }  keys %$tref;
        if (@at > 1) {
                warn "> 1 $tag tag; got " .
                        (join", ", map {"$_: $$tref{$_}"} @at) .
                        "\n";
        }

        return $$tref{$at[0]};
}

sub sane_time {
        my $t = shift;
        my ($u, $v, @o, $c);
	my @x=@t; # nasty

        while ($u = shift @x) {
                $v = shift @x;
                $c = int($t/$v);

                if ($c) {
                        $t-=$c*$v;
                        push @o, plural($c, $u);
                }
        }

	push @o, plural(int($t),'second');

	return $o[0] unless scalar @o > 1;
        return join(' and ',join(', ',@o[0 .. $#o -1]), $o[-1]);
}

sub plural {
	return "@_[0] @_[1]" . (@_[0] != 1 ? 's' : '');
}

sub sane_size {
	my @units = qw(KB MB GB TB PB EB ZB YB);
	my $rem;
	my $out = 'bytes';
	my $in = shift;

	while ($in/1024 > 1) {
		$rem = $in % 1024;
		$in/=1024;
		$out = shift @units;
	}
	return (sprintf("%d.%03d %s", int($in), ($rem%1024/1024) * 1000, $out));
}

sub min { return $_[1] unless defined $_[0]; return $_[0] unless defined $_[1]; return $_[0] < $_[1] ? $_[0] : $_[1]; }
sub max { return $_[0] > $_[1] ? $_[0] : $_[1]; }

sub gent {
	my $gen = $_[1];
	my $gent = $_[3];
	my $nm = $_[0] == -1 ? min($$gen, $_[2]) : max($$gen, $_[2]);
	if ($$gen != $nm) {
		$$gen  = $nm;
		$$gent = join ' / ',map {get_tag($_[4],$_)}qw(artist album title);
	}
}

=pod 

=head1 AUTHORS

	Andrew White (andy@milky.org.uk)
=cut

1;
