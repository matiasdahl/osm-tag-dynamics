## Step 1: Extract the exported OSM data

Unzip the latest data from the `osm-data/exports` directory into a temporary
location. See the separate [documentation](extract-osm-data.md) for
instructions how to generate this data.

## Step 2: Compile image and data for website

In the repository root:

```
./scripts/generate_website_data
```

This assumes that R is installed with the required packages. It also assumes
that the txt files unzipped in Step 1 are located in the
directory `~/temp-data/`.

The above command should take around 30-60 minutes on a first run. However,
it will cache a number of computations (as rds files in the
`~/temp-data/`-directory), and subsequent runs should take less than 5
minutes on a c. 2013 laptop.

After the command has run, the svg files in `web-site/images` and the
file `web-site/am_data.txt` should have been compiled into `~/temp-data/web-data`.
To test the website locally, run:

## Step 3: Update site footer

In `web-site/index.html` update the "The data is from the dd.mm.yyyy OpenStreetMap export"-text.

## Step 4: Run website locally (optional)

From the repo root:

```
cd web-site
cp -r ~/temp-data/web-data/. .
python -m SimpleHTTPServer 8000
```

and open `http://127.0.0.1:8000`.

## Step 4: Deploy to gh-pages

Run:

```
./scripts/deploy
```
