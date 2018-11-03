[flacenc](flacenc) - uses flac(1) to encode all files ending in .wav in the current directory to flacs. Uses all available cores. Perl.

[flacenc.js](flacenc.js) - js version of the above, using callbacks to spawns more flac(1) processes as encode jobs complete, until everything is encoded.

[flac_find_blank_track_numbers](flac_find_blank_track_numbers) - find flac files with a missing 'Tracknumber' tag. Perl.

[flacfixdate](flacfixdate) - players seem to prefer 'Date' instead of 'Year', so this just changes the tag. Perl.

[flacinfo](flacinfo) - perl script to get tags and info from flac headers, print on stdout.

[flacplist](flacplist) - Generate a text playlist, using 'Tracknumber' and falling back to timestamps for ordering. Perl.

[flactag](flactag) - Perl script to tag flac files. Takes command line arguments, and prompts for any missing taginfo. Renames to fit my naming scheme, unless it's passed --no-rename. Works on filenames specified in a glob. Should probably be re-worked to use libreadline.

[flac_tag_from_mp3](flac_tag_from_mp3) - Usage is $0 src dst - given an mp3 file, copy the tags to the flac file. Used when I decided to re-rip everything to flac, after I'd previously ripped to mp3.

[flac_tag_from_mp3list](flac_tag_from_mp3list) - Similar to above, but works on a whole directory instead.

[flactest](flactest) - Test for broken flac files - report any that are broken, or all ok.

[flactime](flactime) - given a series of filespecs (dirs/individual flac files), report a whole bunch of stats.

[flac_track_number_from_playlist_order](flac_track_number_from_playlist_order) - write out an ever-increasing tracknumber from the filenames in the given playlist.

[fuze+reenc.sh](fuze+reenc.sh) - transcode flac files to mp3 files, also copying over tag information and cover art.

[listinadequatepictures.sh](listinadequatepictures.sh) - given multiple filespecs, report and flac files that don't have an image of at least 300x300 (it's assumed there is just one image).

[media_on_demand.pl](media_on_demand.pl) - a fuse filesystem. Target is an output directory, and the source is a flac directory. On access of a file in the mp3 directory, that flac is transcoded and presented.
