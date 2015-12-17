## Step 1: Extract the exported OSM data

Unzip the latest data from the `osm-data/exports` directory into a temporary
location. See the separate [documentation](extract-osm-data.md) for
instructions how to generate this data.

## Step 2: Compile image and data for website

In the repository root,

```
cd src
Rscript create_images.R
cd ..
```

This assumes that R is installed with the required packages. It also assumes
that the txt files unzipped in Step 1 are located in the
directory `~/temp-data/osm-extract-2015-12-07/`.

The above command should take around an hour on a first run. However, it will cache
a number of computations (as rds files in the `src`-directory), and subsequent
runs should take less than 5 minutes on a c. 2013 laptop.

After the command has run, the svg files in `web-site/images` and the
file `web-site/am_data.txt` should have been updated. To test the website
locally, run:

```
cd web-site
python -m SimpleHTTPServer 8000
```

and open `http://127.0.0.1:8000`.
