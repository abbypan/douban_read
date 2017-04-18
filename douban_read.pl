#!/usr/bin/perl
use utf8;
use strict;
use warnings;

use WWW::Mechanize::Firefox;
use Web::Scraper;
use Novel::Robot::Packer;
use Encode::Locale;
use Encode;

#use POSIX qw/strftime/;
#use Data::Dump qw/dump/;

$| = 1;
binmode( STDIN,  ":encoding(console_out)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );

our $BASE_URL = 'https://read.douban.com';
our $RETRY    = 5;

my ( $url ) = @ARGV;

my $mech = WWW::Mechanize::Firefox->new();
$mech->autoclose_tab( 1 );
$mech->get( $url );

my $r = get_book_info( $mech );
print "$r->{writer}, $r->{book}\n";
for my $f ( @{ $r->{floor_list} } ) {
  print "get chapter $f->{id}: $f->{url}\n";
  my ( $ct, $cc ) = get_chapter( $mech, $f->{url} );
  next unless ( $ct =~ /\S/ and $cc =~ /\S/ );
  ( $f->{title}, $f->{content} ) = ( $ct, $cc );
}

my $packer = Novel::Robot::Packer->new( type => 'html' );
$packer->main( $r, with_toc => 1, output => encode( locale => "$r->{writer}-$r->{book}.html" ) );
system( encode( locale => qq[conv_novel.pl -f "$r->{writer}-$r->{book}.html" -t mobi] ) );
system( encode( locale => qq[conv_novel.pl -f "$r->{writer}-$r->{book}.html" -t txt] ) );

sub get_book_info {
  my ( $mech ) = @_;

  my ( $toc ) = $mech->selector( '#chapters-contents-list', all => 0 );
  my $h = $toc->{innerHTML};

  my $pr = scraper {
    process '//a', 'floor_list[]' => {
      'id' => '@tabindex', 'url' => '@href',
      }
  };
  my $r = $pr->scrape( \$h );
  $_->{url} = "$BASE_URL$_->{url}" for @{ $r->{floor_list} };

  my ( $bk ) = $mech->selector( 'a.lite-title', all => 0 );
  $r->{book} = $bk->{innerHTML};
  $r->{book} =~ s#^\s*<b>.*?</b>.*?·\s*|\s*$##sg;

  my ( $wr ) = $mech->selector( 'span.name', all => 0 );
  $r->{writer} = $wr->{innerHTML};

  return $r;
} ## end sub get_book_info

sub get_chapter {
  my ( $mech, $url ) = @_;

  for ( 1 .. $RETRY ) {

    $mech->get( $url );
    sleep 1;

    #press End, keycode = 35
    $mech->eval_in_page(
      q[
            var ev = document.createEvent('KeyboardEvent');
            ev.initKeyEvent(
            'keydown', true, true, window, false, false, false, false, 35, 0);
            document.body.dispatchEvent(ev);
            ]
    );

    sleep 3;

    my ( $t ) = $mech->selector( 'h1', all => 0 );
    my $title = $t->{innerHTML};

    my @c = $mech->selector( 'div.content', all => 1 );
    my @cc = map { $_->{innerHTML} } @c;
    my $content = '';
    for ( @cc ) {
      s/<\/?span[^>]*>//sg;
      s/<\/?p[^>]*>/\n/sg;
      s/<[^>]+>//sg;
      s#(.+?)\n+#<p>$1</p>\n#sg;
      $content .= "$_\n";
    }

    return ( $title, $content ) if ( $title =~ /\S/ );
  } ## end for ( 1 .. $RETRY )

  return;
} ## end sub get_chapter
