#! /usr/bin/perl

#makes things work when run without install
use lib qw( ../bindings/perl-shared/blib/lib ../bindings/perl-shared/blib/arch );
# this is for after install
use lib qw( /usr/local/rrdtool-1.1.0/lib/perl ../lib/perl );

use RRDs;
my $start=time;
my $rrd="randome.rrd";
my $name = $0;
$name =~ s/\.pl.*//g;

RRDs::create ($rrd, "--start",$start-1, "--step",300,
	      "DS:a:GAUGE:600:U:U",
	      "RRA:AVERAGE:0.5:1:300",
	      "RRA:MIN:0.5:12:300",
	      "RRA:MAX:0.5:12:300",
);
my $ERROR = RRDs::error;
die "$0: unable to create `$rrd': $ERROR\n" if $ERROR;

# dropt some data into the rrd
my $t;
for ($t=$start; $t<$start+300*300; $t+=300){
  RRDs::update $rrd, "$t:".(sin($t/3000)*50+50);
  if ($ERROR = RRDs::error) {
    die "$0: unable to update `$rrd': $ERROR\n";
  }
}

RRDs::graph "$name.png",
  "--title", uc($name)." Demo", 
  "--start", "now",
  "--end", "start+1d",
  "--lower-limit=0",
  "--interlace", 
  "--zoom=2.5",
  "--imgformat","PNG",
  "--width=450",
  "DEF:a=$rrd:a:AVERAGE",
  "DEF:b=$rrd:a:MIN",
  "DEF:c=$rrd:a:MAX",
  "AREA:a#00b6e4:real",
  "LINE1:b#0022e9:min",
  "LINE1:c#00ee22:max",
;

if ($ERROR = RRDs::error) {
  print "ERROR: $ERROR\n";
};


print "This script has created $name.png in the current directory\n";
print "This demonstrates the use of the TIME and % RPN operators\n";
