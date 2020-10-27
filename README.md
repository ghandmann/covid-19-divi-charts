# DIVI Catcher and Report Generator

This little website/tool simple plots the german intensive care unit (ICU) numbers provided by the "DIVI-Intensivregister" regarding the COVID-19 pandemic.

The website and tools are open source, do whatever you want with it.

The data is strictly not open source, but owned by DIVI e.V.

So it should not be included in the repo. But to prevent everybody from re-downloading the same (partially broken) CSVs again, i just added them to the repo until somebody forbids it. :)

A daily updated version of the website can be found [here](https://sveneppler.de/covid-19/).

## `catcher.pl`

Just a short perl script to fetch alle CSV-Files from the [DIVI website](https://www.divi.de/divi-intensivregister-tagesreport-archiv-csv?layout=table)

## `report-generator.pl`

Just a short perl script to iterate through all CSV files and create daily summaries. The script outputs a valid Javascript file, meant to be redirected into `data.json` like this:
```
perl report-generator.pl > data.js
```

## `index.html`

Just the needed HTML/JavaScript code to plot the data with the help of the [highcharts](https://www.highcharts.com) library.
