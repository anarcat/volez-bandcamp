#!/usr/bin/perl

use File::Temp;
use Data::Dumper;
use JSON;

# SUPPORT THE FUCKING BANDS YOU TOOLS !
# Its a fucking sham that they used bandcamp that
# doesn't have support for html5 player (how hard
# can that be ?), and its a sham I spend a day to
# get music from my friends, but fuck, its just 
# that bandcamp is shit, not that the musicians
# are bad.

# FIXME: I just don't wanna pollute my /tmp with a whole bunch of random junk
$tempdir = 'farts'; # File::Temp->newdir();

# FIXME: this should be an argument 
#system("wget http://pearstheband.bandcamp.com/album/go-to-prison -O " . $tempdir . "/index.html");

# we just get use some really easy to spot (for grep :D) lines
# and we are taking just that part of the file where the array
# that contains all the data gets declared
$working_with = `A=\$((\$(grep -n "if ( window.FacebookData ) {" $tempdir/index.html | cut -d ":" -f 1)-5)) ; B=\$((\$(grep -n "var TralbumData" $tempdir/index.html | cut -d ":" -f 1)+3)) ; head -n \$A $tempdir/index.html | tail -n \$((\$A-\$B))`;

# with my eagle eye, I saw that it was almost JSON, and we 
# just need to regex it a couple of time to get valid JSON,
# with vim I've just did:
# the fucking asdf: "fu" => "asdf": "fu"
$working_with =~ s/^(\s*)([-_a-zA-Z0-9]+)(\s*):/$1"$2"$3:/mg; 
# odd escaping
$working_with =~ s/\\"/\\\\\\"/mg;
$working_with =~ s/\\r/\\\\r/mg;
$working_with =~ s/\\n/\\\\n/mg;
# odd javascript construct in there 
$working_with =~ s/" \+ "//mg;  
# oh, and it needs to be in brackets
$working_with = '{' . $working_with . '}';

my @perl = from_json($working_with);

print Dumper(@perl); 

my $album_title = $perl[0]{'current'}{'title'};
$album_title =~ s/\'/\\\'/g;
my $band_name = $perl[0]{'artist'};
$band_name =~ s/\'/\\\'/g;
$dir = "$tempdir/$band_name - $album_title";
#FIXME fail gracefully if not able to create directory
mkdir $dir;
#print Dumper($perl[0]{'trackinfo'}[0]);
foreach $track (@{$perl[0]{'trackinfo'}}) {
   $title = @{$track}{'title'};
#   $title =~ s/\'/\\\'/g;
   $track_num = @{$track}{'track_num'};
   print("wget '" . @{@{$track}{'file'}}{'mp3-128'} . "' -O \"" . $dir . "/" . "$track_num - $title.mp3" . "\"\n");
   # just in case they run fail to ban, we retry every 30 seconds
   @args = ("wget", @{@{$track}{'file'}}{'mp3-128'}, "-w", "30", "-O", $dir . "/" . "$track_num - $title");  
   system(@args);
   sleep 10;
}

# we get the album art
#FIXME the file isn't necessarily .jpg
print("wget " . $perl[0]{'artFullsizeUrl'} . " -O \"" . $dir . "/" . "Folder.jpg" . "\"\n");
#system("wget " . $perl[0]{'artFullsizeUrl'} . " -w 30 -O '" . $dir . "/" . "Folder.jpg'");

print $dir;

#FIXME delete that temp_dir, just move to where it goes
