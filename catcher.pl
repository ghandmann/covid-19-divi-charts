#!/usr/bin/env perl

use strict;
use warnings;
use 5.10.0;
use DateTime;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Log;
use Tie::File;


my $log = Mojo::Log->new(path => "./divi-catcher.log");
my $ua = Mojo::UserAgent->new();

my $diviBaseUrl = Mojo::URL->new("https://www.divi.de");

my $overviewBase = "https://www.divi.de/divi-intensivregister-tagesreport-archiv-csv?layout=table&start=";
my $pageOffset = 0;

# only try getting the first 2 pages
my $maxPageOffset = 20;

while($pageOffset <= $maxPageOffset) {
    my $pageUrl = $overviewBase . $pageOffset;

    $log->info("Fetching overview page=$pageUrl");

    my $overviewPage = $ua->get($pageUrl)->res->dom;

    my $linkElements = $overviewPage->find("td.edocman-document-title-td a");

    my $linksFoundCount = $linkElements->size;

    $linkElements->each(sub {
        my $url = $diviBaseUrl->clone->path(shift->attr("href"));
        my ($date) = ($url =~ /divi-intensivregister-(\d\d\d\d-\d\d-\d\d)/);

        my $targetFile = "./DIVI/${date}.csv";

        if(-f $targetFile) {
            $log->info("$targetFile already exists. Not re-downloading report from $url");
        }
        else {
            fetchCSV($url, $targetFile);
            filterCSV($targetFile);
        }
    });

    $pageOffset += 20;
}

sub fetchCSV {
    my $url = shift;
    my $targetFile = shift;

    if($targetFile =~ /2020-04-24/) {
        # this file has a completely different format, so we skip it.
        return;
    }

    $ua->get($url)->res->save_to($targetFile);
    $log->info("Fetched $url to $targetFile");
}

# Since 2021-10-28 for some reason every CSV-File contains all data points since 2020-04.
# So just filter out the "old" values.
sub filterCSV {
    my $fileName = shift;

    my @fullFile;
    open(my $readFh, "<", $fileName) or die "Failed to open for read: $!";
    while(<$readFh>) {
        push(@fullFile, $_);
    }
    close($readFh);

    my $headerLine = $fullFile[0];
    my $lastLine = $fullFile[-1];
    my ($date) = split(/,/, $lastLine);

    if($headerLine =~ /^bundesland/) {
        return;
    }

    $log->info("Filtering CSV File '$fileName' to only contain values for date=$date");

    my @newFile = ($headerLine, grep { /^$date/ } @fullFile);
    open(my $writeFh, ">", $fileName) or die "Failed to open for write: $!";
    print $writeFh join("", @newFile);
    close($writeFh);
}