#!/usr/bin/env perl

use strict;
use warnings;
use Text::CSV qw/csv/;
use feature "say";
use Mojo::JSON qw/j/;
use File::Find;
use Try::Tiny;


my $badDate = "2020-04-25";
my $goodDate = "2020-05-23";

my @total;

my @files = glob("./DIVI/*.csv");

foreach my $file (@files) {
    try {
        my $statsData = generateStatsForDate($file);

        push(@total, $statsData);
    }
    catch {
        say "Failed to process $file. Reason: $_";
    };
}

say "var diviData = " . j(\@total) . ";";

sub formatRate {
    return sprintf("%0.2f", shift);
}

sub generateStatsForDate {
    my $file = shift;

    my ($date) = ($file =~ /(\d\d\d\d\-\d\d-\d\d)/);

    my $data = csv( in => $file, headers => "auto" );

    if($data->[1]->{faelle_covid_aktuell_im_bundesland}) {
        return
    }

    my $sumCovidTotal = 0;
    my $sumCovidVentilated = 0;

    my $sumICUTotal = 0;
    my $sumICUUsed = 0;

    foreach my $row (@$data) {
        # bundesland;gemeindeschluessel;anzahl_meldebereiche;faelle_covid_aktuell;faelle_covid_aktuell_beatmet;anzahl_standorte;betten_frei;betten_belegt;daten_stand
        $sumCovidTotal += $row->{faelle_covid_aktuell};
        $sumCovidVentilated += $row->{faelle_covid_aktuell_beatmet} || $row->{faelle_covid_aktuell_invasiv_beatmet} || 0;

        $sumICUTotal += $row->{betten_frei} + $row->{betten_belegt};
        $sumICUUsed += $row->{betten_belegt};
    }

    return {
        date => $date,
        covidPatients => {
            total => $sumCovidTotal,
            ventilated => $sumCovidVentilated,
            ventilationRate => formatRate($sumCovidVentilated / $sumCovidTotal),
        },
        ICUBeds => {
            total => $sumICUTotal,
            used => $sumICUUsed,
            free => $sumICUTotal - $sumICUUsed,
            covidRate => formatRate($sumCovidTotal / $sumICUUsed),
            freeRate => formatRate($sumICUUsed / $sumICUTotal),
        }
    };
}