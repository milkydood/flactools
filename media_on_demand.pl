#!/usr/bin/perl -w
use strict;
use threads;
use threads::shared;

# andyw 20090203 - virtually merge your flac and mp3 collections into
# one big virtual fs. Ideal for drag and drop to an mp3 player without
# requiring thought.

# TODO: Check thread-safeness / add threads for bg de/encoding
# if i can be arsed.
# Handle errors from open and the like
# check perms, possibly.
# clear out converted space
# cache mp3s in mp3 area
#
# shared %conv may not be optimal
#
# BUGS - some binaries (eg mpg123) seek to the last 128 bytes to read the tag
# there first. Unfortunately, this is failed before we can do anything about
# it. Even using a v2 tag (which appears at the start of the file) doesn't
# prevent this.

use Fuse;

use POSIX qw(ENOENT EINVAL);
use Fcntl qw(SEEK_SET);

use Audio::FLAC::Header; # in order to copy the tags.

my $flac_cmd = 'flac -s -d -c';
my $lame_cmd = 'lame --vbr-new -V 4 --silent --add-id3v2 -';

my $debug = 1;
my $extra_debug = 9;

my %path = (
	flac => '/home/system/flac',
	mp3 => '/home/andy/mp3',
);

my ($t, $f);
my %conv :shared;

for (keys %path) {
	die unless -d $path{$_};
}


sub x_statfs {return 255,1,0,1,0,1}

sub x_getdir {
	my $dir = shift;

	my %cache = ();

	#for $t (qw(flac mp3)) {
	for $t (qw(flac)) {

		next unless -d "$path{$t}/$dir";
		opendir(A,"$path{$t}/$dir");

		for $f (grep !/^\.\.?$/, readdir(A)) {
			debug("x_getdir $f ($t)\n");
			$f = s_file($f) if $t eq 'flac';
			$cache{$f} = 1;
		}

		closedir(A);
	}

	return ('.','..',keys %cache, 0);
}

sub filename_fixup {
	my ($file) = shift;
	$file =~ s,^/,,;
	$file = '.' unless length($file);
	return $file;
}

sub x_getattr {
	my ($f) = filename_fixup(shift);
	my @s;

	#if (-e "$path{mp3}/$f") {
		#debug("x_getattr $f (mp3)\n");
		#return stat("$path{mp3}/$f");
	#} elsif (-e s_file("$path{mp3}/$f")) {
	if (-e s_file("$path{mp3}/$f")) {
		debug("x_getattr $f (flac)\n");
		@s = stat(s_file("$path{mp3}/$f"));
		
		# -d allowed because we never store em
		return @s if -d s_file("$path{mp3}/$f");

		if (exists $conv{$f}) {
			lock(%conv);
			$s[7] = length($conv{$f});
			$s[8] = $s[9] = $s[10] = time;
		} else {
			$s[8] = $s[9] = $s[10] = 0;
		}

		return @s;
	} else {
		debug("x_getattr $f - not there\n");
		return -ENOENT();
	}
}


# given mp3, return corresponding flac.
# given flac, return corresponding mp3.
sub s_file {
	my $f = shift;
	debug("s_file on $f\n");

	if (substr($f,-3,3) eq 'mp3') {
		$f =~s/^$path{mp3}/$path{flac}/;
		$f =~s/\.mp3$/\.flac/;
	} else {
		$f =~s/^$path{mp3}/$path{flac}/;
		$f =~s/\.flac$/\.mp3/;
	}

	debug( "s_file path now $f\n");
	return $f;
}

# extract lame tags, return contructed lame tag args
sub s_tags {
	my ($flacmeta, $flactag, $lametags, $t, $k);

	my %flacmap=(qw(TITLE tt ARTIST ta ALBUM tl DATE ty COMMENT tc 
		TRACKNUMBER tn));

	$flacmeta = Audio::FLAC::Header->new(shift);
	$flactag = $flacmeta->tags(); 

	for $k (keys %flacmap) {
		$t = (grep/^$k$/i, keys %$flactag)[0];
		next unless $t && $$flactag{$t};
		$lametags.=" --$flacmap{$k} \Q$$flactag{$t}\E";
	}

	return $lametags;
}

sub x_open {
	my ($f) = filename_fixup(shift);
	#if (-e "$path{mp3}/$f") {
#	return -EISDIR() if -d "$path{mp3}/$f";
#	debug("x_open $f (mp3)\n");
#	return 0;
#} elsif (-e s_file("$path{mp3}/$f")) {
	if (-e s_file("$path{mp3}/$f")) {
		debug("x_open $f (flac) $f\n");
		return -EISDIR() if -d s_file("$path{mp3}/$f");
		return 0;
	} else {
		debug( "x_open $f - not there\n");
		return -ENOENT();
	}
}

sub x_read {
	my ($f) = filename_fixup(shift);
	my ($sz, $off) = @_;
	my ($flac, $buf, $lametags);

	#if (-e "$path{mp3}/$f") {
	#	debug( "x_read mp3 $f $sz bytes @ $off\n");
	#	open(A,"$path{mp3}/$f");
	#	binmode(A);
	#	return -EINVAL() if $off > (stat("$path{mp3}/$f"))[7];
	#	return 0 if $off == (stat("$path{mp3}/$f"))[7];
	#	seek A, $off, SEEK_SET();
	#	read A, $buf, $sz;
	#	close(A);
	#	return $buf;
	#} elsif (-e ($flac = s_file("$path{mp3}/$f"))) {
	if (-e ($flac = s_file("$path{mp3}/$f"))) {
		debug( "x_read flac $f $sz bytes @ $off\n");

		if (! exists $conv{$f}) {
			# might not be a flac file. Just pass it 
			# through if not.
			if ($flac =~/flac$/) {
				$lametags= s_tags($flac);

				debug("Calling $flac_cmd $flac | $lame_cmd $lametags |\n");
				lock(%conv);
				open(A,"$flac_cmd $flac | $lame_cmd $lametags |");
			} else {
				open(A,$flac);
			}

			binmode(A);
			while(read(A,$buf,2**18)) {
				#actually, let's bodge playlists too
				if ($flac =~/playlist\.?\w*$/) {
					$buf=~s/\.flac$/\.mp3/gom;
				}

				$conv{$f}.=$buf;
				debug("REENCODE: Buffer now " . length($conv{$f}) . "\n");
			}

			close(A);
		}
		
		lock(%conv);
		return -EINVAL() if $off > length $conv{$f};
		return 0 if $off == length $conv{$f};
		return substr($conv{$f}, $off, $sz);
	} else {
		return -ENOENT();
	}
		
}

sub debug {
	return unless $extra_debug;
	print @_;
}

my ($mountpoint) = "";
$mountpoint = shift(@ARGV) if @ARGV;
Fuse::main(
	mountpoint=>$mountpoint,
	debug=>$debug,
	threaded=>1,
	map {$_,"main::x_$_" } qw/statfs getdir getattr open read/,
);
